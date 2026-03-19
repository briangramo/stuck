from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parent.parent
CONFIG_DIR = ROOT / "config" / "instances"
MANIFEST_OUTPUT = ROOT / "src" / "ReplicatedStorage" / "Shared" / "Config" / "StaticAssetManifest.luau"
CHECKLIST_OUTPUT = ROOT / "docs" / "studio-instance-checklist.md"

CONFIG_FILES = {
    "network": CONFIG_DIR / "network.json",
    "bindables": CONFIG_DIR / "bindables.json",
    "sounds": CONFIG_DIR / "sounds.json",
}

ALLOWED_CLASSES = {
    "network": {"RemoteEvent", "RemoteFunction"},
    "bindables": {"BindableEvent", "BindableFunction"},
    "sounds": {"Sound"},
}

ALLOWED_SERVICES = {
    "ReplicatedStorage",
    "ServerScriptService",
    "ServerStorage",
    "SoundService",
    "Workspace",
    "StarterGui",
}


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def expect(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def validate_parent(parent: Any, label: str) -> None:
    expect(isinstance(parent, dict), f"{label}: parent must be an object")
    service = parent.get("service")
    segments = parent.get("segments")
    expect(service in ALLOWED_SERVICES, f"{label}: unsupported service '{service}'")
    expect(isinstance(segments, list), f"{label}: parent.segments must be a list")
    for index, segment in enumerate(segments, start=1):
        expect(isinstance(segment, str) and segment, f"{label}: parent.segments[{index}] must be a non-empty string")


def validate_entry(kind: str, entry: Any, seen_names: set[str], index: int) -> None:
    label = f"{kind}.entries[{index}]"
    expect(isinstance(entry, dict), f"{label}: entry must be an object")

    name = entry.get("name")
    class_name = entry.get("className")

    expect(isinstance(name, str) and name, f"{label}: name must be a non-empty string")
    expect(name not in seen_names, f"{label}: duplicate name '{name}'")
    seen_names.add(name)

    expect(class_name in ALLOWED_CLASSES[kind], f"{label}: invalid className '{class_name}'")
    validate_parent(entry.get("parent"), label)

    notes = entry.get("notes")
    if notes is not None:
        expect(isinstance(notes, str), f"{label}: notes must be a string when provided")

    if kind == "network":
        direction = entry.get("direction")
        expect(isinstance(direction, str) and direction, f"{label}: direction must be a non-empty string")

    if kind == "sounds":
        sound_id = entry.get("soundId")
        expect(isinstance(sound_id, str) and sound_id, f"{label}: soundId must be a non-empty string")
        volume = entry.get("volume")
        if volume is not None:
            expect(isinstance(volume, (int, float)), f"{label}: volume must be a number when provided")
        looped = entry.get("looped")
        if looped is not None:
            expect(isinstance(looped, bool), f"{label}: looped must be a boolean when provided")


def normalize_manifest() -> dict[str, Any]:
    result: dict[str, Any] = {}

    for kind, path in CONFIG_FILES.items():
        payload = load_json(path)
        expect(isinstance(payload, dict), f"{path.name}: root must be an object")

        build = payload.get("build")
        entries = payload.get("entries")

        expect(isinstance(build, int) and build >= 1, f"{path.name}: build must be an integer >= 1")
        expect(isinstance(entries, list), f"{path.name}: entries must be a list")

        seen_names: set[str] = set()
        for index, entry in enumerate(entries, start=1):
            validate_entry(kind, entry, seen_names, index)

        result[kind] = {
            "build": build,
            "entries": entries,
        }

    return result


def luau_key(key: str) -> str:
    return f"[{json.dumps(key)}]"


def luau_value(value: Any, indent: int = 0) -> str:
    space = "    " * indent
    next_space = "    " * (indent + 1)

    if isinstance(value, dict):
        lines = ["{"]
        for key, item in value.items():
            lines.append(f"{next_space}{luau_key(key)} = {luau_value(item, indent + 1)},")
        lines.append(f"{space}}}")
        return "\n".join(lines)

    if isinstance(value, list):
        lines = ["{"]
        for item in value:
            lines.append(f"{next_space}{luau_value(item, indent + 1)},")
        lines.append(f"{space}}}")
        return "\n".join(lines)

    if isinstance(value, str):
        return json.dumps(value)

    if isinstance(value, bool):
        return "true" if value else "false"

    if value is None:
        return "nil"

    return str(value)


def build_lookup_table(entries: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    return {entry["name"]: entry for entry in entries}


def write_runtime_manifest(manifest: dict[str, Any]) -> None:
    runtime_manifest = {
        "gameName": "Stuck Forever",
        "network": {
            "build": manifest["network"]["build"],
            "entries": manifest["network"]["entries"],
            "byName": build_lookup_table(manifest["network"]["entries"]),
        },
        "bindables": {
            "build": manifest["bindables"]["build"],
            "entries": manifest["bindables"]["entries"],
            "byName": build_lookup_table(manifest["bindables"]["entries"]),
        },
        "sounds": {
            "build": manifest["sounds"]["build"],
            "entries": manifest["sounds"]["entries"],
            "byName": build_lookup_table(manifest["sounds"]["entries"]),
        },
    }

    content = "-- This file is generated by tools/build_static_manifest.py.\n"
    content += "-- Do not edit it by hand.\n\n"
    content += "return "
    content += luau_value(runtime_manifest)
    content += "\n"

    MANIFEST_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    MANIFEST_OUTPUT.write_text(content, encoding="utf-8")


def format_parent(parent: dict[str, Any]) -> str:
    return "/".join([parent["service"], *parent["segments"]])


def render_section(title: str, entries: list[dict[str, Any]], extra_fields: list[str]) -> list[str]:
    lines = [f"## {title}", ""]

    if not entries:
        lines.append("None declared.")
        lines.append("")
        return lines

    for index, entry in enumerate(entries, start=1):
        lines.append(f"### {index}. `{entry['name']}`")
        lines.append("")
        lines.append(f"- Class: `{entry['className']}`")
        lines.append(f"- Parent: `{format_parent(entry['parent'])}`")
        for field in extra_fields:
            if field in entry:
                lines.append(f"- {field}: `{json.dumps(entry[field]) if isinstance(entry[field], bool) else entry[field]}`")
        if entry.get("notes"):
            lines.append(f"- Notes: {entry['notes']}")
        lines.append("")

    return lines


def write_checklist(manifest: dict[str, Any]) -> None:
    lines = [
        "# Studio Instance Checklist",
        "",
        "Generated from JSON manifests. Create or update these instances manually in Roblox Studio.",
        "",
        "Containers are conventions, not runtime-generated objects:",
        "",
        "- `ReplicatedStorage/Net/RemoteEvents` for `RemoteEvent`",
        "- `ReplicatedStorage/Net/RemoteFunctions` for `RemoteFunction`",
        "- `ServerScriptService/Signals/BindableEvents` for `BindableEvent`",
        "- `ServerScriptService/Signals/BindableFunctions` for `BindableFunction`",
        "- `ReplicatedStorage/Sounds` for `Sound`",
        "",
    ]

    lines.extend(render_section("Network", manifest["network"]["entries"], ["direction"]))
    lines.extend(render_section("Bindables", manifest["bindables"]["entries"], []))
    lines.extend(render_section("Sounds", manifest["sounds"]["entries"], ["soundId", "volume", "looped"]))

    CHECKLIST_OUTPUT.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")


def main() -> None:
    manifest = normalize_manifest()
    write_runtime_manifest(manifest)
    write_checklist(manifest)
    print("Generated runtime manifest and Studio checklist.")


if __name__ == "__main__":
    main()
