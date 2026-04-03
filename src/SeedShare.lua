--!strict
-- ============================================================
-- MODULE: SeedShare
-- Viral seed sharing system:
--   - Encodes world seed + settings into a short shareable code
--   - Decodes codes back to exact world parameters
--   - In-game UI prompt for copy/paste
--   - Code format: PREFIX-BIOME-HASH (e.g. WORLD-VOLCANIC-7742)
-- v1.0.0 | roblox-procedural-worlds
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldConfig       = require(ReplicatedStorage:WaitForChild("WorldConfig"))

local SeedShare = {}

-- ── Encode / Decode ──────────────────────────────────────────────

-- Alphabet for base-36 encoding (no ambiguous chars like 0/O, 1/I)
local ALPHABET = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
local BASE = #ALPHABET

local function toBase(n: number, digits: number): string
	local result = {}
	local num = math.abs(math.floor(n))
	for _ = 1, digits do
		local idx = (num % BASE) + 1
		table.insert(result, 1, ALPHABET:sub(idx, idx))
		num = math.floor(num / BASE)
	end
	return table.concat(result)
end

local function fromBase(s: string): number
	local result = 0
	for i = 1, #s do
		local char = s:sub(i, i)
		local idx  = ALPHABET:find(char, 1, true)
		if not idx then return -1 end
		result = result * BASE + (idx - 1)
	end
	return result
end

-- Dominant biome tag from seed
local BIOME_TAGS = {
	"TUNDRA","TAIGA","FOREST","JUNGLE","DESERT",
	"SWAMP","VOLCANIC","OCEAN","SAVANNA","GRASSLAND",
}

local function seedToBiomeTag(seed: number): string
	return BIOME_TAGS[(seed % #BIOME_TAGS) + 1]
end

-- ── Public: Encode ───────────────────────────────────────────────

export type WorldParams = {
	seed:         number,
	noiseScale:   number?,
	seaLevel:     number?,
	biomeCount:   number?,
	heightMult:   number?,
}

--- Encode world parameters into a shareable code string.
--- Format: WORLD-{BIOMETAG}-{SEED5}{PARAMS3}
function SeedShare.Encode(params: WorldParams): string
	local seed       = math.clamp(math.floor(params.seed), 0, 2^28)
	local noiseQ     = math.clamp(math.floor((params.noiseScale  or 0.008) * 10000), 0, BASE^2 - 1)
	local seaQ       = math.clamp(math.floor((params.seaLevel    or 40)    / 10),    0, BASE   - 1)
	local heightQ    = math.clamp(math.floor((params.heightMult  or 120)   / 20),    0, BASE   - 1)

	local seedPart   = toBase(seed,   5)
	local noisePart  = toBase(noiseQ, 2)
	local seaPart    = toBase(seaQ,   1)
	local heightPart = toBase(heightQ,1)

	local biomeTag = seedToBiomeTag(seed)

	return "WORLD-" .. biomeTag .. "-" .. seedPart .. noisePart .. seaPart .. heightPart
end

--- Decode a share code back into world parameters.
--- Returns nil if the code is invalid.
function SeedShare.Decode(code: string): WorldParams?
	code = code:upper():gsub("%s+", "")

	-- Validate prefix
	if not code:match("^WORLD%-") then
		warn("[SeedShare] Invalid prefix:", code)
		return nil
	end

	-- Strip prefix and biome tag
	local withoutPrefix = code:sub(7)  -- remove "WORLD-"
	local dashPos = withoutPrefix:find("-")
	if not dashPos then
		warn("[SeedShare] Missing biome tag separator:", code)
		return nil
	end

	local payload = withoutPrefix:sub(dashPos + 1)  -- e.g. "AB2CD3EF"
	if #payload ~= 9 then
		warn("[SeedShare] Payload length mismatch (expected 9, got", #payload, "):", code)
		return nil
	end

	local seedPart   = payload:sub(1, 5)
	local noisePart  = payload:sub(6, 7)
	local seaPart    = payload:sub(8, 8)
	local heightPart = payload:sub(9, 9)

	local seed      = fromBase(seedPart)
	local noiseQ    = fromBase(noisePart)
	local seaQ      = fromBase(seaPart)
	local heightQ   = fromBase(heightPart)

	if seed < 0 or noiseQ < 0 then
		warn("[SeedShare] Decode error — invalid characters in payload")
		return nil
	end

	return {
		seed       = seed,
		noiseScale = noiseQ / 10000,
		seaLevel   = seaQ * 10,
		heightMult = heightQ * 20,
	} :: WorldParams
end

--- Validate a code string without fully decoding it.
function SeedShare.IsValid(code: string): boolean
	return SeedShare.Decode(code) ~= nil
end

-- ── In-game GUI Prompt ───────────────────────────────────────────

--- Show a ScreenGui prompt to the player with the share code.
--- Includes a copy-to-clipboard button via TextBox selection trick.
function SeedShare.ShowShareUI(player: Player, code: string)
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if not playerGui then return end

	-- Remove existing UI
	local existing = playerGui:FindFirstChild("SeedShareUI")
	if existing then existing:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name        = "SeedShareUI"
	gui.ResetOnSpawn = false
	gui.Parent      = playerGui

	local frame = Instance.new("Frame")
	frame.Size            = UDim2.new(0, 420, 0, 160)
	frame.Position        = UDim2.new(0.5, -210, 0.5, -80)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
	frame.BorderSizePixel = 0
	frame.Parent          = gui
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

	local title = Instance.new("TextLabel")
	title.Size              = UDim2.new(1, -20, 0, 30)
	title.Position          = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.TextColor3        = Color3.fromRGB(200, 240, 220)
	title.Font              = Enum.Font.GothamBold
	title.TextSize          = 16
	title.Text              = "🌍 Share Your World"
	title.TextXAlignment    = Enum.TextXAlignment.Left
	title.Parent            = frame

	local codeBox = Instance.new("TextBox")
	codeBox.Size              = UDim2.new(1, -20, 0, 40)
	codeBox.Position          = UDim2.new(0, 10, 0, 50)
	codeBox.BackgroundColor3  = Color3.fromRGB(35, 35, 48)
	codeBox.BorderSizePixel   = 0
	codeBox.TextColor3        = Color3.fromRGB(240, 200, 100)
	codeBox.Font              = Enum.Font.Code
	codeBox.TextSize          = 15
	codeBox.Text              = code
	codeBox.TextEditable      = false
	codeBox.ClearTextOnFocus  = false
	codeBox.Parent            = frame
	Instance.new("UICorner", codeBox).CornerRadius = UDim.new(0, 6)

	-- Select all text on focus (enables Ctrl+C)
	codeBox.Focused:Connect(function()
		codeBox:CaptureFocus()
	end)

	local hint = Instance.new("TextLabel")
	hint.Size              = UDim2.new(1, -20, 0, 20)
	hint.Position          = UDim2.new(0, 10, 0, 98)
	hint.BackgroundTransparency = 1
	hint.TextColor3        = Color3.fromRGB(130, 130, 150)
	hint.Font              = Enum.Font.Gotham
	hint.TextSize          = 12
	hint.Text              = "Click the code → Ctrl+C to copy. Share with friends!"
	hint.Parent            = frame

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size              = UDim2.new(0, 100, 0, 32)
	closeBtn.Position          = UDim2.new(0.5, -50, 1, -44)
	closeBtn.BackgroundColor3  = Color3.fromRGB(60, 160, 100)
	closeBtn.BorderSizePixel   = 0
	closeBtn.TextColor3        = Color3.fromRGB(255, 255, 255)
	closeBtn.Font              = Enum.Font.GothamBold
	closeBtn.TextSize          = 13
	closeBtn.Text              = "Close"
	closeBtn.Parent            = frame
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

	closeBtn.MouseButton1Click:Connect(function()
		gui:Destroy()
	end)
end

--- Get the share code for the current world and show the UI.
function SeedShare.ShareWorld(player: Player, params: WorldParams)
	local code = SeedShare.Encode(params)
	SeedShare.ShowShareUI(player, code)
	return code
end

--- Hook chat command: player types "/sharecode" in chat.
function SeedShare.HookChatCommand(worldParams: WorldParams)
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(msg)
			if msg:lower() == "/sharecode" or msg:lower() == "/seed" then
				SeedShare.ShareWorld(player, worldParams)
			end
		end)
	end)
end

return SeedShare
