-- Client-side day/night look and sound, driven by the clock attributes the server publishes.
-- Bright and cheerful by day; a soft purple, spooky-but-friendly glow at night (Mild rating).

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage.Shared.Config)

local Atmosphere = {}

local DAY_AMBIENT = Color3.fromRGB(140, 130, 140)
local NIGHT_AMBIENT = Color3.fromRGB(90, 70, 140)
local NIGHT_TINT = Color3.fromRGB(200, 185, 255)
-- Events recolour the night (still friendly, never dark-red horror).
local EVENT_LOOKS = {
	BloodMoon = { ambient = Color3.fromRGB(130, 70, 100), tint = Color3.fromRGB(255, 190, 205) },
	SpookySeason = { ambient = Color3.fromRGB(120, 80, 70), tint = Color3.fromRGB(255, 215, 170) },
}
local FADE = 0.15 -- share of a phase spent fading between day and night looks

local function smooth(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

-- How "night" the world should look, 0..1, given the phase and its progress.
local function nightness(phase: string, progress: number): number
	if phase == "Day" then
		return smooth((progress - (1 - FADE)) / FADE) -- dusk at the end of the day
	end
	return 1 - smooth((progress - (1 - FADE)) / FADE) -- dawn at the end of the night
end

local function music(id: string, name: string): Sound?
	if id == "" then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = id
	sound.Looped = true
	sound.Volume = 0
	sound.Parent = SoundService
	sound:Play()
	return sound
end

-- Seconds left in the current phase, and progress through it (0..1).
function Atmosphere.phaseTime(): (number, number)
	local length = ReplicatedStorage:GetAttribute("PhaseLength") or 1
	local endsAt = ReplicatedStorage:GetAttribute("PhaseEndsAt") or 0
	local left = math.max(0, endsAt - workspace:GetServerTimeNow())
	return left, 1 - left / length
end

function Atmosphere.start()
	local correction = Instance.new("ColorCorrectionEffect")
	correction.Parent = Lighting
	local haze = Instance.new("Atmosphere")
	haze.Color = Color3.fromRGB(200, 190, 230)
	haze.Decay = Color3.fromRGB(120, 100, 180)
	haze.Parent = Lighting

	local dayMusic = music(Config.Audio.dayMusic, "DayMusic")
	local nightMusic = music(Config.Audio.nightMusic, "NightMusic")

	RunService.RenderStepped:Connect(function()
		local phase = ReplicatedStorage:GetAttribute("Phase") or "Day"
		local _, progress = Atmosphere.phaseTime()
		local n = nightness(phase, progress)
		local look = EVENT_LOOKS[ReplicatedStorage:GetAttribute("Event") or ""]
		local nightAmbient = if look then look.ambient else NIGHT_AMBIENT
		local nightTint = if look then look.tint else NIGHT_TINT

		-- Sun sweeps from morning to sunset by day, then the moon has the sky by night.
		Lighting.ClockTime = if phase == "Day" then 8 + progress * 10 else (18 + progress * 12) % 24
		Lighting.Ambient = DAY_AMBIENT:Lerp(nightAmbient, n)
		Lighting.OutdoorAmbient = DAY_AMBIENT:Lerp(nightAmbient, n)
		Lighting.Brightness = 2.5 - n * 1.2
		correction.TintColor = Color3.new(1, 1, 1):Lerp(nightTint, n)
		correction.Saturation = -0.15 * n
		haze.Density = 0.25 + 0.2 * n

		if dayMusic then
			dayMusic.Volume = Config.Audio.musicVolume * (1 - n)
		end
		if nightMusic then
			nightMusic.Volume = Config.Audio.musicVolume * n
		end
	end)
end

return Atmosphere
