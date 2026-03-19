# Studio Instance Checklist

Generated from JSON manifests. Create or update these instances manually in Roblox Studio.

Containers are conventions, not runtime-generated objects:

- `ReplicatedStorage/Net/RemoteEvents` for `RemoteEvent`
- `ReplicatedStorage/Net/RemoteFunctions` for `RemoteFunction`
- `ServerScriptService/Signals/BindableEvents` for `BindableEvent`
- `ServerScriptService/Signals/BindableFunctions` for `BindableFunction`
- `ReplicatedStorage/Sounds` for `Sound`

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

### 3. `DistanceMilestoneReached`

- Class: `RemoteEvent`
- Parent: `ReplicatedStorage/Net/RemoteEvents`
- direction: `ServerToClient`
- Notes: Fires whenever a runner reaches a new 100-stud milestone.

## Bindables

None declared.

## Sounds

### 1. `SlimeAmbience`

- Class: `Sound`
- Parent: `ReplicatedStorage/Sounds`
- soundId: `rbxassetid://0`
- volume: `0.18`
- looped: `true`
- Notes: Placeholder ambience loop. In Studio, assign a valid audio asset to ReplicatedStorage/Sounds/SlimeAmbience.

### 2. `MilestoneCelebration`

- Class: `Sound`
- Parent: `ReplicatedStorage/Sounds`
- soundId: `rbxassetid://0`
- volume: `0.7`
- looped: `false`
- Notes: Short bright win-stinger for each 100-stud milestone. In Studio, assign a valid audio asset to ReplicatedStorage/Sounds/MilestoneCelebration.
