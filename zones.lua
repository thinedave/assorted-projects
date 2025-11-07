--@realm client
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local modules = ReplicatedStorage:WaitForChild("modules")
local extramath = require(modules.extramath)
local util = require(modules.util)

-- HOW TO CREATE A ZONE
-- 1. Open ReplicatedStorage/lists/zones/
-- 2. Instantiate zone with local ZONE = zones.New("x") (camelCase, no spaces or underscores)
-- 3. Fill variables however you want (e.g. ZONE.superDense = true)
-- 4. Register zone with zones.Register(ZONE)
-- 5. Create a part in Workspace/zones/ named "ZONE_x" where x is the uniqueID of the zone
-- 6. Add a tag named "zone" to the part
-- 7. Place and size part to cover the entire area of the zone, duplicate part if needed just keep name same

type ZoneConnectors = {Entered: RBXScriptConnection, Left: RBXScriptConnection}

type Zone = {
    uniqueID: string,
    name: string,
    description: string,
    fogColor: Color3,
    fogEnd: number,
    fogStart: number,
    ambientColor: Color3,
    brightness: number,
    contrast: number,
    saturation: number,
    tint: Color3,
    transitionTime: number,
    easingStyle: Enum.EasingStyle,
    isSuperZone: boolean,
    superDense: boolean,
    OnEnter: (() -> ())?,
    OnLeave: (() -> ())?,
    Heartbeat: (() -> ())?,
}

local module = {}
module.stored = {} :: {[string]: Zone}
module.parts = {} :: {[Part]: ZoneConnectors}

local defaultFogColor: Color3 = Color3.fromRGB(0, 0, 0)
local defaultAmbientColor: Color3 = Color3.fromRGB(128, 117, 91)
local defaultTint: Color3 = Color3.fromRGB(255, 253, 224)

module.base = {
    uniqueID = "",
    name = "Undefined",
    description = "Undefined",
    fogColor = defaultFogColor,
    fogEnd = 3000,
    fogStart = 3000,
    ambientColor = defaultAmbientColor,
    brightness = 0,
    contrast = 0,
    saturation = 0,
    tint = defaultTint,
    transitionTime = 5,
    easingStyle = Enum.EasingStyle.Linear,
    isSuperZone = false,
    superDense = false,
    OnEnter = nil,
    OnLeave = nil,
    Heartbeat = nil,
} :: Zone

module.baseSuper = {
    uniqueID = "",
    name = "Undefined",
    description = "Undefined",
    fogColor = defaultFogColor,
    fogEnd = 3000,
    fogStart = 3000,
    ambientColor = defaultAmbientColor,
    brightness = 0,
    contrast = 0,
    saturation = 0,
    tint = defaultTint,
    transitionTime = 5,
    easingStyle = Enum.EasingStyle.Linear,
    isSuperZone = true,
    superDense = false,
    OnEnter = nil,
    OnLeave = nil,
    Heartbeat = nil,
} :: Zone

module.currentZone = module.base :: Zone
module.currentSuperZone = module.baseSuper :: Zone
module.Heartbeat = nil :: RBXScriptConnection?

function module.New(id: string): Zone
    local zone = extramath.DeepClone(module.base) :: Zone
    zone.uniqueID = id

    return zone

end

function module.Register(zone: Zone): ()
    module.stored[zone.uniqueID] = zone

end

function module.LoadAll(): ()
    print("Loading zones...")

    for i: number, v: Instance in pairs(ReplicatedStorage:WaitForChild("lists").zones:GetChildren()) do
        print("Loading zones from "..v.Name.."...")

        util.DynamicRequire(v);

    end

end

function module.GetZoneFromPart(part: Part): Zone
    local split: {string} = string.split(part.Name, "_")

    if(split[1]) ~= "ZONE" then return module.baseSuper end

    return module.stored[split[2]] or module.baseSuper

end

function module.EnterZone(zone: Zone): ()
    local localPlayer: Player = Players.LocalPlayer
    local character: Model? = localPlayer.Character
    if(not character) then return end

    module.currentZone = zone
    if(zone.isSuperZone) then module.currentSuperZone = zone end

    extramath.TweenProperty(Lighting, {
        ["FogColor"] = zone.fogColor,
        ["FogEnd"] = zone.fogEnd,
        ["FogStart"] = zone.fogStart,
        ["Ambient"] = zone.ambientColor,
    }, zone.transitionTime, zone.easingStyle, Enum.EasingDirection.In)

    extramath.TweenProperty(Lighting.ColorCorrection, {
        ["Brightness"] = zone.brightness,
        ["Contrast"] = zone.contrast,
        ["Saturation"] = zone.saturation,
        ["TintColor"] = zone.tint,
    }, zone.transitionTime, zone.easingStyle, Enum.EasingDirection.In)

    local fog: Part = character:WaitForChild("fog") :: Part
    
    extramath.TweenProperty(fog, {
        ["Transparency"] = (zone.superDense and 0 or 1)
    }, (zone.superDense and zone.transitionTime * 1.25 or zone.transitionTime), zone.easingStyle, Enum.EasingDirection.In)

    if(zone.OnEnter) then zone.OnEnter() end

    if(module.Heartbeat) then
        module.Heartbeat:Disconnect()
        module.Heartbeat = nil
    
    end

    if(zone.Heartbeat) then module.Heartbeat = RunService.Heartbeat:Connect(zone.Heartbeat) end

end

function module.LeaveZone(zone: Zone): ()
    if(zone ~= module.currentZone) then return end

    if(zone.OnLeave) then zone.OnLeave() end

    module.EnterZone(zone == module.currentSuperZone and module.baseSuper or module.currentSuperZone)

end

local zoneChangerPart: string = "HumanoidRootPart"

function module.ConnectZone(v: Part, zone: Zone): ()
    print("Connecting zone "..zone.uniqueID.." to Part "..v.Name)

    local localPlayer: Player = Players.LocalPlayer

    module.parts[v] = {
        Entered = v.Touched:Connect(function(other: BasePart): ()
            if(other.Name ~= zoneChangerPart or other.Parent ~= localPlayer.Character) then return end

            module.EnterZone(zone)
            
        end),
        Left = v.TouchEnded:Connect(function(other: BasePart): ()
            if(other.Name ~= zoneChangerPart or other.Parent ~= localPlayer.Character) then return end

            module.LeaveZone(zone)
        
        end),
    }

end

function module.Listen(): ()
    print("Listening for zones...")

    for _, v in CollectionService:GetTagged("zone") do
        module.ConnectZone(v, module.GetZoneFromPart(v))
    
    end
    
    CollectionService:GetInstanceAddedSignal("zone"):Connect(function(v: Part)
        module.ConnectZone(v, module.GetZoneFromPart(v))
    
    end)
    
    CollectionService:GetInstanceRemovedSignal("zone"):Connect(function(v: Part)
        module.parts[v].Entered:Disconnect()
        module.parts[v].Left:Disconnect()
        module.parts[v] = nil
    
    end)

end

return module