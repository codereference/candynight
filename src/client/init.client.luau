-- Client entry point. Only displays state the server owns; never changes cash itself.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CashHud = require(script.CashHud)
local Format = require(ReplicatedStorage.Shared.Format)

local player = Players.LocalPlayer
local cash = player:WaitForChild("leaderstats"):WaitForChild("Cash") :: IntValue

CashHud.mount(player:WaitForChild("PlayerGui"), cash, Format.cash)
