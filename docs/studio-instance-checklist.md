# Studio Instance Checklist

Generated from JSON manifests. Create or update these instances manually in Roblox Studio.

Containers are conventions, not runtime-generated objects:

- `ReplicatedStorage/Net/RemoteEvents` for `RemoteEvent`
- `ReplicatedStorage/Net/RemoteFunctions` for `RemoteFunction`
- `ServerScriptService/Signals/BindableEvents` for `BindableEvent`
- `ServerScriptService/Signals/BindableFunctions` for `BindableFunction`
- `SoundService/Ambience` for `Sound`

## Network

### 1. `SpectateCycleRequest`

- Class: `RemoteEvent`
- Parent: `ReplicatedStorage/Net/RemoteEvents`
- direction: `ClientToServer`
- Notes: Requests previous or next spectate target.

### 2. `SpectateStateChanged`

- Class: `RemoteEvent`
- Parent: `ReplicatedStorage/Net/RemoteEvents`
- direction: `ServerToClient`
- Notes: Pushes stuck UI state and current spectate target.

## Bindables

None declared.

## Sounds

### 1. `SlimeHum`

- Class: `Sound`
- Parent: `SoundService/Ambience`
- soundId: `rbxassetid://0`
- volume: `0.18`
- looped: `true`
- Notes: Placeholder ambience slot. In Studio, assign a valid audio asset to SoundService/Ambience/SlimeHum before enabling ambience.
