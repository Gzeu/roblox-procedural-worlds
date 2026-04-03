-- ParticleEffects.lua
-- Centralized particle effect management: spawn, attach, pool and clean effects
-- v2.5 | roblox-procedural-worlds

local Debris = game:GetService("Debris")
local EventBus = require(script.Parent.EventBus)

local ParticleEffects = {}
ParticleEffects.__index = ParticleEffects

-- Effect presets: name -> property table for ParticleEmitter
local presets = {
	Spark = {
		Color = ColorSequence.new(Color3.fromRGB(255, 200, 50), Color3.fromRGB(255, 80, 0)),
		LightEmission = 0.8,
		LightInfluence = 0.2,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) }),
		Speed = NumberRange.new(8, 20),
		SpreadAngle = Vector2.new(30, 30),
		Lifetime = NumberRange.new(0.3, 0.8),
		Rate = 60,
		Rotation = NumberRange.new(0, 360),
	},
	Heal = {
		Color = ColorSequence.new(Color3.fromRGB(80, 255, 120)),
		LightEmission = 0.5,
		LightInfluence = 0.3,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) }),
		Speed = NumberRange.new(4, 10),
		SpreadAngle = Vector2.new(60, 60),
		Lifetime = NumberRange.new(0.5, 1.2),
		Rate = 40,
	},
	Dust = {
		Color = ColorSequence.new(Color3.fromRGB(180, 160, 130)),
		LightEmission = 0,
		LightInfluence = 1,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0) }),
		Speed = NumberRange.new(2, 6),
		SpreadAngle = Vector2.new(80, 80),
		Lifetime = NumberRange.new(0.8, 2.0),
		Rate = 20,
	},
	Magic = {
		Color = ColorSequence.new(Color3.fromRGB(140, 80, 255), Color3.fromRGB(200, 140, 255)),
		LightEmission = 1,
		LightInfluence = 0,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) }),
		Speed = NumberRange.new(5, 15),
		SpreadAngle = Vector2.new(45, 45),
		Lifetime = NumberRange.new(0.4, 1.0),
		Rate = 80,
	},
	Blood = {
		Color = ColorSequence.new(Color3.fromRGB(160, 20, 20)),
		LightEmission = 0,
		LightInfluence = 1,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0.05) }),
		Speed = NumberRange.new(5, 12),
		SpreadAngle = Vector2.new(50, 50),
		Lifetime = NumberRange.new(0.5, 1.5),
		Rate = 50,
	},
}

-- Register or override a preset
function ParticleEffects.registerPreset(name, properties)
	assert(type(name) == "string", "Preset name must be a string")
	assert(type(properties) == "table", "Properties must be a table")
	presets[name] = properties
end

-- Get preset list
function ParticleEffects.getPresets()
	return presets
end

-- Apply preset properties to a ParticleEmitter instance
local function applyPreset(emitter, preset)
	for prop, val in pairs(preset) do
		pcall(function() emitter[prop] = val end)
	end
end

-- Emit a burst of particles at a BasePart or Vector3 position
-- @param target BasePart | Vector3
-- @param presetName string
-- @param duration number (seconds, default 0.2)
-- @param parent Instance? (optional attachment parent)
function ParticleEffects.emit(target, presetName, duration, parent)
	local preset = presets[presetName]
	if not preset then
		warn("[ParticleEffects] Unknown preset: " .. tostring(presetName))
		return
	end

	local attachPart
	if typeof(target) == "Vector3" then
		attachPart = Instance.new("Part")
		attachPart.Anchored = true
		attachPart.CanCollide = false
		attachPart.Transparency = 1
		attachPart.Size = Vector3.new(1, 1, 1)
		attachPart.Position = target
		attachPart.Parent = parent or workspace
		Debris:AddItem(attachPart, (duration or 0.2) + 2)
	else
		attachPart = target
	end

	local emitter = Instance.new("ParticleEmitter")
	applyPreset(emitter, preset)
	emitter.Enabled = true
	emitter.Parent = attachPart

	task.delay(duration or 0.2, function()
		emitter.Enabled = false
		Debris:AddItem(emitter, 2)
	end)

	EventBus.emit("ParticleEffects:Emitted", presetName, target)
	return emitter
end

-- Attach a continuous emitter (manually stop with :Destroy or disable)
function ParticleEffects.attach(part, presetName)
	local preset = presets[presetName]
	if not preset then
		warn("[ParticleEffects] Unknown preset: " .. tostring(presetName))
		return
	end

	local emitter = Instance.new("ParticleEmitter")
	applyPreset(emitter, preset)
	emitter.Enabled = true
	emitter.Parent = part
	return emitter
end

-- Stop all ParticleEmitters on a part
function ParticleEffects.stopAll(part)
	for _, child in ipairs(part:GetChildren()) do
		if child:IsA("ParticleEmitter") then
			child.Enabled = false
			Debris:AddItem(child, 2)
		end
	end
end

return ParticleEffects
