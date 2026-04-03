-- init.server.lua
-- Entry point for roblox-procedural-worlds
-- Boots WorldGenerator and all subsystems
-- v2.3.0

local WorldGenerator = require(script.WorldGenerator)

-- Optional: pass a forced seed for testing (nil = use saved or random)
local FORCE_SEED = nil

WorldGenerator.Init(FORCE_SEED)

print("[ProceduralWorlds] v2.3.0 — World initialized with seed:", WorldGenerator.GetSeed())
