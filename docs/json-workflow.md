# JSON Workflow

## Source of truth

Edit only these files when you add or change static Roblox instances:

- [`/Users/briangramo/Code/StuckRojo/config/instances/network.json`](./../config/instances/network.json)
- [`/Users/briangramo/Code/StuckRojo/config/instances/bindables.json`](./../config/instances/bindables.json)
- [`/Users/briangramo/Code/StuckRojo/config/instances/sounds.json`](./../config/instances/sounds.json)

## Rules

- Never create `RemoteEvent`, `RemoteFunction`, `BindableEvent`, `BindableFunction`, or `Sound` instances dynamically in code.
- Keep `GameServer` orchestration-only. Reusable systems belong in ModuleScripts with a single `Init(ctx)` entrypoint.
- Increment manifest `build` values only when you add new functionality.

## Schemas

### `network.json`

```json
{
  "build": 1,
  "entries": [
    {
      "name": "RoundStateChanged",
      "className": "RemoteEvent",
      "parent": {
        "service": "ReplicatedStorage",
        "segments": ["Net", "RemoteEvents"]
      },
      "direction": "ServerToClient",
      "notes": "Broadcasts round state updates."
    },
    {
      "name": "RequestRespawn",
      "className": "RemoteFunction",
      "parent": {
        "service": "ReplicatedStorage",
        "segments": ["Net", "RemoteFunctions"]
      },
      "direction": "ClientToServer",
      "notes": "Handles respawn requests."
    }
  ]
}
```

### `bindables.json`

```json
{
  "build": 1,
  "entries": [
    {
      "name": "RoundStarted",
      "className": "BindableEvent",
      "parent": {
        "service": "ServerScriptService",
        "segments": ["Signals", "BindableEvents"]
      },
      "notes": "Raised when a new round begins."
    },
    {
      "name": "AllocateSpawn",
      "className": "BindableFunction",
      "parent": {
        "service": "ServerScriptService",
        "segments": ["Signals", "BindableFunctions"]
      },
      "notes": "Returns the spawn selected for a player."
    }
  ]
}
```

### `sounds.json`

```json
{
  "build": 1,
  "entries": [
    {
      "name": "LobbyMusic",
      "className": "Sound",
      "parent": {
        "service": "SoundService",
        "segments": ["Music"]
      },
      "soundId": "rbxassetid://0000000000",
      "volume": 0.35,
      "looped": true,
      "notes": "Main lobby music."
    }
  ]
}
```

## After every manifest change

1. Run `python3 tools/build_static_manifest.py`.
2. Review [`/Users/briangramo/Code/StuckRojo/docs/studio-instance-checklist.md`](./studio-instance-checklist.md).
3. Apply the matching static changes in Rojo or manually in Roblox Studio.
4. Test that bootstrap validation still passes.
