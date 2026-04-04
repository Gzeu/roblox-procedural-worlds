--[[
  BiomeBlending.lua  v3.0
  Smooth transitions between biomes using gradient noise sampling.
  Usage:
    local BiomeBlending = require(game.ServerScriptService.BiomeBlending)
    local blended = BiomeBlending.getBlendedColor(x, z, heightmap)
--]]

local BiomeBlending = {}

-- Biome color table (R, G, B 0-1)
local BIOME_COLORS = {
  Ocean    = {0.09, 0.44, 0.72},
  Beach    = {0.84, 0.77, 0.60},
  Forest   = {0.42, 0.50, 0.25},
  Swamp    = {0.29, 0.39, 0.21},
  Desert   = {0.85, 0.80, 0.62},
  Volcanic = {0.41, 0.25, 0.16},
  Tundra   = {0.76, 0.80, 0.84},
}

local BLEND_RADIUS = 8  -- cells

local function lerp(a, b, t)
  return a + (b - a) * math.clamp(t, 0, 1)
end

local function getBiome(h, maxH, waterLevel)
  local frac = h / maxH
  if h <= waterLevel       then return "Ocean"    end
  if frac < 0.15           then return "Beach"    end
  if frac > 0.85           then return "Volcanic" end
  if frac > 0.75           then return "Tundra"   end
  if frac < 0.25           then return "Swamp"    end
  if frac < 0.35           then return "Desert"   end
  return "Forest"
end

--- Returns a blended Color3 for a given world position by sampling
--- the 8 cardinal/diagonal neighbours within BLEND_RADIUS.
function BiomeBlending.getBlendedColor(x, z, getHeight, maxH, waterLevel)
  waterLevel = waterLevel or 20
  maxH       = maxH or 120

  local r, g, b = 0, 0, 0
  local totalWeight = 0

  for dz = -BLEND_RADIUS, BLEND_RADIUS, BLEND_RADIUS do
    for dx = -BLEND_RADIUS, BLEND_RADIUS, BLEND_RADIUS do
      local h   = getHeight(x + dx, z + dz)
      local bm  = getBiome(h, maxH, waterLevel)
      local col = BIOME_COLORS[bm] or BIOME_COLORS.Forest
      local dist = math.sqrt(dx*dx + dz*dz) + 1
      local w   = 1 / dist
      r = r + col[1] * w
      g = g + col[2] * w
      b = b + col[3] * w
      totalWeight = totalWeight + w
    end
  end

  return Color3.new(r/totalWeight, g/totalWeight, b/totalWeight)
end

--- Linearly interpolates two biome colors given a blend factor (0-1).
function BiomeBlending.blendTwo(biomeA, biomeB, t)
  local ca = BIOME_COLORS[biomeA] or BIOME_COLORS.Forest
  local cb = BIOME_COLORS[biomeB] or BIOME_COLORS.Forest
  return Color3.new(
    lerp(ca[1], cb[1], t),
    lerp(ca[2], cb[2], t),
    lerp(ca[3], cb[3], t)
  )
end

return BiomeBlending
