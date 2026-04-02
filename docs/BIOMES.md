# Biome Reference

## Temperature × Moisture Map

All 9 biomes are placed in a 2D (temperature, moisture) space. Values range from 0.0 to 1.0.

| Biome | Temp | Moisture | Surface | Fill | Trees | Rocks | Bushes |
|---|---|---|---|---|---|---|---|
| Forest    | 0.45 | 0.75 | Grass       | Mud        | ✅ | ✅ | ✅ |
| Desert    | 0.90 | 0.08 | Sand        | Sandstone  | ❌ | ✅ | ❌ |
| Snow      | 0.08 | 0.45 | Snow        | Glacier    | ✅ | ✅ | ❌ |
| Grassland | 0.60 | 0.40 | Grass       | Ground     | ❌ | ❌ | ✅ |
| Jungle    | 0.85 | 0.90 | Grass       | Mud        | ✅ | ✅ | ✅ |
| Tundra    | 0.10 | 0.20 | Snow        | Ground     | ❌ | ✅ | ❌ |
| Volcano   | 0.95 | 0.05 | Basalt      | Basalt     | ❌ | ✅ | ❌ |
| Swamp     | 0.35 | 0.92 | Mud         | Mud        | ✅ | ❌ | ✅ |
| Ocean     | 0.50 | 1.00 | Sand        | Sand       | ❌ | ❌ | ❌ |

## Structures per Biome

| Biome     | Structures |
|-----------|------------|
| Forest    | Campfire, WoodRuin |
| Desert    | SandRuin, Obelisk |
| Snow      | Igloo, IceSpike |
| Grassland | Campfire |
| Jungle    | JungleTemple, Campfire |
| Tundra    | IceSpike |
| Volcano   | LavaPillar, AshRuin |
| Swamp     | WoodRuin, Campfire |
| Ocean     | — |

## How Blending Works

The `BiomeResolver` uses **inverse-square-distance weighting** in (temp, moisture) space. For each world column:

1. Sample temperature and moisture noise → two floats in [0, 1]
2. Compute 1/d² distance to every biome pole
3. Normalise weights to sum 1.0
4. Dominant biome = highest weight
5. At surface layer: if any secondary biome has >18% weight, randomly borrow its surface material

This creates gradual, organic-looking transitions without hard borders.
