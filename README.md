# Roblox Procedural Worlds

> Modular, chunk-based procedural world generation for Roblox Studio — biomes, ores, structures, caves, streaming.

[![Version](https://img.shields.io/badge/version-2.0.0-blue)](#)
[![Luau](https://img.shields.io/badge/Luau-strict-green)](#)
[![License](https://img.shields.io/badge/license-MIT-lightgrey)](#)

---

## Features

| Feature | Details |
|---|---|
| **9 Biomes** | Forest, Desert, Snow, Grassland, Jungle, Tundra, Volcano, Swamp, Ocean |
| **Smooth biome transitions** | Inverse-square-distance weighting + probabilistic material blending |
| **Layered terrain** | 3-octave FBM Perlin noise (base + detail + fine + mountains) |
| **Cave system** | 3D noise cave carving between configurable Y depths |
| **Ore veins** | Coal, Iron, Gold, Diamond — depth-gated 3D noise |
| **Structures** | Per-biome: campfires, igloos, ruins, temples, pillars |
| **Water system** | Automatic ocean/lake fill below WaterLevel |
| **Chunk streaming** | Runtime load/unload around players; configurable radius |
| **Performance** | `task.spawn()` per chunk, configurable concurrency cap |
| **Luau strict** | Full `--!strict` type annotations throughout |

---

## Architecture

```text
ServerScriptService
└── WorldGenerator       ← entry point, seed, chunk dispatch, streaming boot

ReplicatedStorage
├── WorldConfig          ← all settings, 9 biomes, ore definitions
├── BiomeResolver        ← noise → biome + blend weights
├── ChunkHandler         ← voxel fill, caves, calls ore/struct/asset placers
├── OreGenerator         ← 3D ore vein injection per voxel
├── StructurePlacer      ← biome structure placement
├── AssetPlacer          ← tree/rock/bush placement
├── StreamingManager     ← runtime chunk load/unload around players
├── Assets/              ← Trees, Rocks, Bushes (Models)
└── Structures/          ← Campfire, Igloo, WoodRuin, etc. (Models)
```

---

## Biome Map

Biomes are distributed in (temperature × moisture) space:

```
          DRY ←——————————————————→ WET
          
 HOT      Desert    Grassland   Jungle
          Volcano
          
 MEDIUM   Tundra    Forest      Swamp
                                Ocean
          
 COLD     Snow      Tundra      Snow
```

---

## Quick Start

1. Copy each `src/*.lua` file into its Studio location (see Architecture above)
2. Create `ReplicatedStorage/Assets/Trees`, `.../Rocks`, `.../Bushes` with your Models
3. Create `ReplicatedStorage/Structures/` with structure Models (optional)
4. Press **Play** — world generates automatically

---

## Adding Custom Biomes

**1. Add definition in `WorldConfig.Biomes`:**
```lua
WorldConfig.Biomes.Mushroom = {
    Name = "Mushroom",
    SurfaceMaterial = Enum.Material.LeafyGrass,
    FillMaterial    = Enum.Material.Mud,
    DebugColor      = Color3.fromRGB(180, 50, 200),
    Trees = false, Rocks = false, Bushes = true,
    Structures = { "GiantMushroom" },
}
```

**2. Add pole in `BiomeResolver.BIOME_POLES`:**
```lua
Mushroom = { t = 0.55, m = 0.70 },
```

Done — blending is automatic.

---

## Adding Custom Ores

In `WorldConfig.OreVeins`, add:
```lua
{
    Name = "Emerald",
    Material  = Enum.Material.Neon,   -- or custom MaterialVariant
    MinY = -90, MaxY = -30,
    Scale     = 14,
    Threshold = 0.85,
    SeedOffset = 50000,
},
```

---

## Performance Tuning

See [`docs/PERFORMANCE.md`](docs/PERFORMANCE.md)

| Map Size  | Est. Time | Key Setting |
|-----------|-----------|-------------|
| 500×500   | ~20–35 s  | Defaults |
| 1000×1000 | ~90–120 s | `VoxelSize = 8` |
| 2000×2000 | ~6–10 min | `VoxelSize = 8`, `ChunkSize = 60` |

---

## Roadmap

- [ ] Dungeon / underground room generation
- [ ] River carving along terrain valleys
- [ ] Biome weather zones (rain, snow, ash)
- [ ] Rojo project file for pro workflow
- [ ] DataStore seed persistence across sessions

---

## License

MIT © 2026 [Gzeu](https://github.com/Gzeu)
