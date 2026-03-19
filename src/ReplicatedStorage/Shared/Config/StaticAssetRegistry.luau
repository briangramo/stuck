local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local StaticAssetManifest = require(script.Parent.StaticAssetManifest)

local SERVICES = {
    ReplicatedStorage = ReplicatedStorage,
    SoundService = SoundService,
    StarterGui = StarterGui,
    Workspace = Workspace,
}

if RunService:IsServer() then
    SERVICES.ServerScriptService = game:GetService("ServerScriptService")
    SERVICES.ServerStorage = game:GetService("ServerStorage")
end

local StaticAssetRegistry = {}

local COLLECTION_NAMES = { "network", "bindables", "sounds" }

local function resolveParent(parentSpec)
    local current = SERVICES[parentSpec.service]
    if not current then
        return nil, string.format("Unsupported service '%s'", tostring(parentSpec.service))
    end

    for _, segment in ipairs(parentSpec.segments) do
        current = current:FindFirstChild(segment)
        if not current then
            return nil, string.format("Missing container '%s' under %s", segment, parentSpec.service)
        end
    end

    return current
end

local function validateEntry(entry)
    local parent, parentError = resolveParent(entry.parent)
    if not parent then
        return parentError
    end

    local instance = parent:FindFirstChild(entry.name)
    if not instance then
        return string.format(
            "Missing %s '%s' under %s",
            entry.className,
            entry.name,
            parent:GetFullName()
        )
    end

    if not instance:IsA(entry.className) then
        return string.format(
            "Expected %s '%s' to be a %s, got %s",
            entry.className,
            entry.name,
            entry.className,
            instance.ClassName
        )
    end

    return nil
end

function StaticAssetRegistry.GetManifest()
    return StaticAssetManifest
end

function StaticAssetRegistry.GetEntry(collectionName, name)
    local collection = StaticAssetManifest[collectionName]
    assert(collection, string.format("Unknown collection '%s'", tostring(collectionName)))

    local entry = collection.byName[name]
    assert(entry, string.format("Unknown %s asset '%s'", collectionName, tostring(name)))

    return entry
end

function StaticAssetRegistry.GetInstance(collectionName, name)
    local entry = StaticAssetRegistry.GetEntry(collectionName, name)
    local parent, parentError = resolveParent(entry.parent)
    assert(parent, parentError)

    local instance = parent:FindFirstChild(entry.name)
    assert(instance, string.format("Missing %s '%s'", entry.className, entry.name))
    assert(instance:IsA(entry.className), string.format("Expected '%s' to be a %s", entry.name, entry.className))

    return instance
end

function StaticAssetRegistry.ValidateAll()
    local errors = {}

    for _, collectionName in ipairs(COLLECTION_NAMES) do
        local collection = StaticAssetManifest[collectionName]
        for _, entry in ipairs(collection.entries) do
            local errorMessage = validateEntry(entry)
            if errorMessage then
                table.insert(errors, errorMessage)
            end
        end
    end

    return #errors == 0, errors
end

return StaticAssetRegistry
