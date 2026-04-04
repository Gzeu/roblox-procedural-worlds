-- AnimationManager.lua  (ModuleScript)
-- Procedural animations via TweenService on HumanoidRootPart.
-- No AnimationId uploads required. Works with any rig.
-- v7.0 | roblox-procedural-worlds

local TweenService = game:GetService("TweenService")

local AnimationManager = {}

-- Per-model active tween handles  {model -> {tween, connection}}
local activeTweens = {}

local function stopAnim(model)
	local handle = activeTweens[model]
	if handle then
		if handle.tween   then handle.tween:Cancel() end
		if handle.conn    then handle.conn:Disconnect() end
		if handle.tween2  then handle.tween2:Cancel() end
		activeTweens[model] = nil
	end
end

local function getHRP(model)
	return model:FindFirstChild("HumanoidRootPart")
		or model:FindFirstChildWhichIsA("BasePart")
end

-- Idle: gentle Y sway ±2 degrees as CFrame rotation at 1 Hz
function AnimationManager.playIdle(model)
	stopAnim(model)
	local hrp = getHRP(model)
	if not hrp then return end

	local origin = hrp.CFrame
	local goingUp = true
	local handle = {}

	local function swayStep()
		if not model.Parent then
			stopAnim(model)
			return
		end
		local angle = goingUp and math.rad(2) or math.rad(-2)
		local target = hrp.CFrame * CFrame.Angles(0, 0, angle)
		local tw = TweenService:Create(hrp,
			TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{CFrame = target}
		)
		handle.tween = tw
		tw:Play()
		goingUp = not goingUp
		handle.conn = tw.Completed:Connect(function()
			handle.conn:Disconnect()
			swayStep()
		end)
	end

	activeTweens[model] = handle
	swayStep()
end

-- Walk: bob HumanoidRootPart Y up/down 0.2 studs at 4 Hz
function AnimationManager.playWalk(model)
	stopAnim(model)
	local hrp = getHRP(model)
	if not hrp then return end

	local handle  = {}
	local bobUp   = true

	local function bobStep()
		if not model.Parent then
			stopAnim(model)
			return
		end
		local offset = bobUp and 0.2 or -0.2
		local target = hrp.CFrame + Vector3.new(0, offset, 0)
		local tw = TweenService:Create(hrp,
			TweenInfo.new(0.125, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{CFrame = target}
		)
		handle.tween = tw
		tw:Play()
		bobUp = not bobUp
		handle.conn = tw.Completed:Connect(function()
			handle.conn:Disconnect()
			bobStep()
		end)
	end

	activeTweens[model] = handle
	bobStep()
end

-- Attack: forward lunge +1.5 studs over 0.15s then return
function AnimationManager.playAttack(model)
	local hrp = getHRP(model)
	if not hrp then return end

	local origin   = hrp.CFrame
	local forward  = hrp.CFrame.LookVector
	local lunge    = origin + forward * 1.5

	local tw1 = TweenService:Create(hrp,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{CFrame = CFrame.new(lunge.Position) * (origin - origin.Position)}
	)
	tw1:Play()
	tw1.Completed:Connect(function()
		local tw2 = TweenService:Create(hrp,
			TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{CFrame = origin}
		)
		tw2:Play()
	end)
end

-- Death: tween Y -3 studs over 1s, then destroy model after 3s
function AnimationManager.playDeath(model)
	stopAnim(model)
	local hrp = getHRP(model)
	if not hrp then
		task.delay(3, function() if model.Parent then model:Destroy() end end)
		return
	end

	-- Disable collision on all parts
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then p.CanCollide = false end
	end

	local target = hrp.CFrame + Vector3.new(0, -3, 0)
	local tw = TweenService:Create(hrp,
		TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{CFrame = target}
	)
	tw:Play()

	-- Fade out (transparency)
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			TweenService:Create(p,
				TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Transparency = 1}
			):Play()
		end
	end

	task.delay(3, function()
		if model and model.Parent then model:Destroy() end
	end)
end

-- Stop all animations for a model (call on state change before new anim)
function AnimationManager.stop(model)
	stopAnim(model)
end

return AnimationManager
