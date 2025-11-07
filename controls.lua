--@realm shared
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local net = ReplicatedStorage:WaitForChild("net")
local modules = ReplicatedStorage:WaitForChild("modules")
local session = require(modules.session)

-- UserInputType's mouse enums only go up to 7 and KeyCode starts from 8, so we can get away with this.
type UserInput = (Enum.UserInputType | Enum.KeyCode)
type UserInputs = {UserInput}
type WasSuccessful = boolean

local module = {}

module.bindToKey = {} :: {[string]: UserInputs}
module.keyToBind = {} :: {[UserInput]: string}

function module.Unbind(bind: string, index: number): ()
    if(not module.bindToKey[bind] or not module.bindToKey[bind][index]) then return end

    module.keyToBind[module.bindToKey[bind][index]] = nil

end

function module.BindRaw(input: UserInput, bind: string, index: number): ()
    if(not module.bindToKey[bind]) then module.bindToKey[bind] = {} end

    module.Unbind(bind, index)

    module.keyToBind[input] = bind
    module.bindToKey[bind][index] = input

end

function module.Bind(input: UserInput, bind: string, index: number): WasSuccessful
    if(input == Enum.KeyCode.Escape) then return false end

    module.BindRaw(input, bind, index)

    return true

end

function module.SendBinds(): ()
    net.SendBinds:FireServer(module.bindToKey)

end

function module.DefaultBinds(): ()
    module.Bind(Enum.UserInputType.MouseButton1, "attack1", 1)
    module.Bind(Enum.KeyCode.R, "attack2", 1)
    module.Bind(Enum.UserInputType.MouseButton2, "block", 1)
    module.Bind(Enum.KeyCode.F, "parry", 1)
    module.Bind(Enum.KeyCode.Q, "dodge", 1)
    module.Bind(Enum.KeyCode.LeftAlt, "dodge", 2)
    module.Bind(Enum.KeyCode.Tab, "tab", 1)
    module.Bind(Enum.KeyCode.X, "sheathe", 1)
    module.Bind(Enum.KeyCode.H, "rest", 1)
    module.Bind(Enum.KeyCode.One, "hotbar1", 1)
    module.Bind(Enum.KeyCode.Two, "hotbar2", 1)
    module.Bind(Enum.KeyCode.Three, "hotbar3", 1)
    module.Bind(Enum.KeyCode.Four, "hotbar4", 1)
    module.Bind(Enum.KeyCode.Five, "hotbar5", 1)
    module.Bind(Enum.KeyCode.Six, "hotbar6", 1)
    module.Bind(Enum.KeyCode.Seven, "hotbar7", 1)
    module.Bind(Enum.KeyCode.Eight, "hotbar8", 1)
    module.Bind(Enum.KeyCode.Nine, "hotbar9", 1)
    module.Bind(Enum.KeyCode.Zero, "hotbar0", 1)

end

function module.LoadBinds(): ()
    local localPlayer: Player = Players.LocalPlayer

    if(not session.players[localPlayer.UserId].binds or #session.players[localPlayer.UserId].binds == 0) then
        module.DefaultBinds()
        return

    end

    for i: string, v: UserInputs in pairs(session.players[localPlayer.UserId].binds) do
        module.bindToKey[i] = v

        for _, vv: UserInput in pairs(v) do
            module.keyToBind[vv] = i

        end

    end

end

function module.GetBind(input: InputObject): string
    return module.keyToBind[input.KeyCode] or module.keyToBind[input.UserInputType]

end

function module.GetKeys(bind: string): UserInputs
    return module.bindToKey[bind]

end

return module