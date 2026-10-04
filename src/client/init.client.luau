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
local CodesPanel = require(script.CodesPanel)
local StorePanel = require(script.StorePanel)
local StylePanel = require(script.StylePanel)
local AdminPanel = require(script.AdminPanel)
local Onboarding = require(script.Onboarding)
local Toasts = require(script.Toasts)
local Format = require(ReplicatedStorage.Shared.Format)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Show every string in the player's language when the LocalizationTable has it.
local LocalizationService = game:GetService("LocalizationService")
local Strings = require(ReplicatedStorage.Shared.Strings)
local gotTranslator, translator = pcall(LocalizationService.GetTranslatorForPlayerAsync, LocalizationService, player)
if gotTranslator and translator.LocaleId:sub(1, 2) ~= "en" then
	Strings.setTranslator(function(key, vars)
		local ok, text = pcall(translator.FormatByKey, translator, key, vars)
		return if ok then text else nil
	end)
end

Toasts.mount(playerGui)
WelcomeBack.mount(playerGui)
Atmosphere.start()
ClockHud.mount(playerGui)
NightHud.mount(playerGui)
DefensePlacement.mount(playerGui)
RebirthPanel.mount(playerGui)
DailyPanel.mount(playerGui)
CodesPanel.mount(playerGui)
StorePanel.mount(playerGui)
StylePanel.mount(playerGui)
AdminPanel.mount(playerGui)
Onboarding.mount(playerGui)

local cash = player:WaitForChild("leaderstats"):WaitForChild("Cash") :: IntValue
CashHud.mount(playerGui, cash, Format.cash)
