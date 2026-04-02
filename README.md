# Roblox Procedural Worlds

A collection of procedural world generation systems for Roblox Studio using Luau, `Terrain:FillBlock()` and `math.noise()`.

## Features

- Chunk-based terrain generation (30×30 stud chunks)
- Multi-biome system: **Forest**, **Desert**, **Snow**, **Grassland**
- Temperature + moisture biome blending (smooth transitions)
- Layered Perlin noise terrain (base + mountain octaves)
- Water level support (ocean/lake fill)
- Cave carving with 3D noise
- Biome-based asset placement (trees, rocks, bushes)
- Modular Luau architecture (`--!strict` compatible)
- `task.spawn()` per chunk — non-blocking generation
- `pcall()` around all Instance placement

## Repository Structure

```text
roblox-procedural-worlds/
├── README.md
├── LICENSE
├── .gitignore
├── src/
│   ├── WorldConfig.lua       → ModuleScript: all settings & biome definitions
│   ├── BiomeResolver.lua     → ModuleScript: noise → biome mapping
│   ├── ChunkHandler.lua      → ModuleScript: voxel fill per chunk
│   ├── AssetPlacer.lua       → ModuleScript: prop placement per biome
│   └── WorldGenerator.lua    → Script: main entry point
└── docs/
    ├── EXPLORER_STRUCTURE.md → Roblox Studio hierarchy diagram
    └── PERFORMANCE.md        → Tuning guide for large maps
```

## Roblox Studio Placement

| File | Studio Location | Type |
|---|---|---|
| `WorldGenerator.lua` | `ServerScriptService/WorldGenerator` | Script |
| `WorldConfig.lua` | `ReplicatedStorage/WorldConfig` | ModuleScript |
| `BiomeResolver.lua` | `ReplicatedStorage/BiomeResolver` | ModuleScript |
| `ChunkHandler.lua` | `ReplicatedStorage/ChunkHandler` | ModuleScript |
| `AssetPlacer.lua` | `ReplicatedStorage/AssetPlacer` | ModuleScript |

## Asset Setup

Create this folder structure in `ReplicatedStorage`:

```text
ReplicatedStorage
└── Assets
    ├── Trees
    │   ├── Tree_Pine  (Model, PrimaryPart required)
    │   ├── Tree_Oak   (Model, PrimaryPart required)
    │   └── Tree_Birch (Model, PrimaryPart required)
    ├── Rocks
    │   ├── Rock_Small  (Model)
    │   ├── Rock_Medium (Model)
    │   └── Rock_Large  (Model)
    └── Bushes
        ├── Bush_Round  (Model)
        └── Bush_Shrub  (Model)
```

## Quick Start

1. Copy each `src/*.lua` file into its corresponding Studio location (table above)
2. Add your prop Models to `ReplicatedStorage/Assets/`
3. Press **Play** — world generates automatically
4. Tune settings in `WorldConfig.lua` (`Seed`, `WorldSizeX/Z`, `VoxelSize`, etc.)

## Adding Custom Biomes

**Step 1** — Add definition to `WorldConfig.Biomes`:
```lua
WorldConfig.Biomes.Swamp = {
    Name = "Swamp",
    SurfaceMaterial = Enum.Material.Mud,
    FillMaterial    = Enum.Material.Mud,
    DebugColor      = Color3.fromRGB(80, 100, 60),
    Trees  = true,
    Rocks  = false,
    Bushes = true,
}
```

**Step 2** — Add its pole in `BiomeResolver` inside `BIOME_POLES`:
```lua
Swamp = { t = 0.3, m = 0.95 },  -- cold + very wet
```

Done — the inverse-distance weighting system blends it automatically.

## Roadmap

- [ ] More biome packs (Jungle, Tundra, Volcano, Ocean)
- [ ] Structures / villages / ruins per biome
- [ ] Ore/mineral generation underground
- [ ] Runtime streaming chunks around players
- [ ] Saveable seeds and world presets
- [ ] Rojo project file for pro workflow

## License

MIT © 2026 Gzeu
