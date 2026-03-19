# Stuck Forever

`Stuck Forever` is a Rojo-based Roblox prototype built around one brutal loop:

`spawn -> walk the bridge -> fall once -> become a permanent monument -> spectate forever`

## Prototype features

- A fixed 200x200 grassy lobby
- A deterministic streamed obby bridge that extends forever
- Slime around the lobby and under streamed bridge chunks
- A top-10 in-world server leaderboard
- Permanent stuck persistence across rejoins
- Cross-server monument chunk replication through DataStore
- Spectator mode with bottom-center controls

## Static instance policy

This repo uses JSON manifests in [`/Users/briangramo/Code/StuckRojo/config/instances`](./config/instances) as the source of truth for:

- `RemoteEvent`
- `RemoteFunction`
- `BindableEvent`
- `BindableFunction`
- `Sound`

These instances are never created at runtime. They are declared statically in [`/Users/briangramo/Code/StuckRojo/default.project.json`](./default.project.json) and validated during server boot. If you are not syncing with Rojo, use [`/Users/briangramo/Code/StuckRojo/docs/studio-instance-checklist.md`](./docs/studio-instance-checklist.md) to build the same static tree manually in Studio.

## Important files

- [`/Users/briangramo/Code/StuckRojo/src/ServerScriptService/GameServer.server.luau`](./src/ServerScriptService/GameServer.server.luau): server entrypoint
- [`/Users/briangramo/Code/StuckRojo/src/ServerScriptService/Server/Bootstrap.luau`](./src/ServerScriptService/Server/Bootstrap.luau): service wiring
- [`/Users/briangramo/Code/StuckRojo/src/ReplicatedStorage/Shared/Config/GameConfig.luau`](./src/ReplicatedStorage/Shared/Config/GameConfig.luau): world, streaming, and persistence constants
- [`/Users/briangramo/Code/StuckRojo/src/ReplicatedStorage/Shared/Bridge/BridgePatterns.luau`](./src/ReplicatedStorage/Shared/Bridge/BridgePatterns.luau): deterministic segment definitions
- [`/Users/briangramo/Code/StuckRojo/src/StarterPlayer/StarterPlayerScripts/Client/SpectateController.luau`](./src/StarterPlayer/StarterPlayerScripts/Client/SpectateController.luau): stuck UI and camera logic

## Workflow

After changing remotes, bindables, functions, or sounds:

```bash
python3 tools/build_static_manifest.py
```

That regenerates [`/Users/briangramo/Code/StuckRojo/src/ReplicatedStorage/Shared/Config/StaticAssetManifest.luau`](./src/ReplicatedStorage/Shared/Config/StaticAssetManifest.luau) and [`/Users/briangramo/Code/StuckRojo/docs/studio-instance-checklist.md`](./docs/studio-instance-checklist.md).

## Studio note

The persistence layer uses DataStore when available. In Studio, it falls back to in-memory data if API services are unavailable so the prototype remains locally testable.
