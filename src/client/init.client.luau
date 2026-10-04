-- Client entry point. Only displays state the server owns and sends requests; never changes cash itself.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Atmosphere = require(script.Atmosphere)
local CashHud = require(script.CashHud)
local ClockHud = require(script.ClockHud)
local DefensePlacement = require(script.DefensePlacement)
local NightHud = require(script.NightHud)
local RebirthPanel = require(script.RebirthPanel)
local WelcomeBack = require(script.WelcomeBack)
local DailyPanel = require(script.DailyPanel)
local Toasts = require(script.Toasts)
local Format = require(ReplicatedStorage.Shared.Format)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

Toasts.mount(playerGui)
WelcomeBack.mount(playerGui)
Atmosphere.start()
ClockHud.mount(playerGui)
NightHud.mount(playerGui)
DefensePlacement.mount(playerGui)
RebirthPanel.mount(playerGui)
DailyPanel.mount(playerGui)

local cash = player:WaitForChild("leaderstats"):WaitForChild("Cash") :: IntValue
CashHud.mount(playerGui, cash, Format.cash)
