# Roblox Studio Explorer Structure

```text
Workspace
├── Terrain                          ← Roblox built-in
└── ProceduralAssets (Folder)        ← Auto-created at runtime

ServerScriptService
└── WorldGenerator        (Script)         ← src/WorldGenerator.lua

ReplicatedStorage
├── WorldConfig           (ModuleScript)   ← src/WorldConfig.lua
├── BiomeResolver         (ModuleScript)   ← src/BiomeResolver.lua
├── ChunkHandler          (ModuleScript)   ← src/ChunkHandler.lua
├── OreGenerator          (ModuleScript)   ← src/OreGenerator.lua
├── StructurePlacer       (ModuleScript)   ← src/StructurePlacer.lua
├── AssetPlacer           (ModuleScript)   ← src/AssetPlacer.lua
├── StreamingManager      (ModuleScript)   ← src/StreamingManager.lua
├── Assets                (Folder)
│   ├── Trees
│   │   ├── Tree_Pine   (Model, PrimaryPart required)
│   │   ├── Tree_Oak    (Model)
│   │   └── Tree_Birch  (Model)
│   ├── Rocks
│   │   ├── Rock_Small  (Model)
│   │   ├── Rock_Medium (Model)
│   │   └── Rock_Large  (Model)
│   └── Bushes
│       ├── Bush_Round  (Model)
│       └── Bush_Shrub  (Model)
└── Structures            (Folder)
    ├── Campfire          (Model, PrimaryPart required)
    ├── WoodRuin          (Model)
    ├── SandRuin          (Model)
    ├── Obelisk           (Model)
    ├── Igloo             (Model)
    ├── IceSpike          (Model)
    ├── JungleTemple      (Model)
    ├── LavaPillar        (Model)
    └── AshRuin           (Model)
```

## Notes

- All **Models** must have a `PrimaryPart` set (any `BasePart` inside the model).
- `ProceduralAssets` folder is created automatically at runtime by `AssetPlacer` and `StructurePlacer` if it does not exist.
- Module scripts in `ReplicatedStorage` are accessible from both server and client; `WorldGenerator` runs server-side only.
- The `Structures/` folder is optional — if absent, `StructurePlacer` will silently skip placement.
- The `Assets/` sub-folders (`Trees`, `Rocks`, `Bushes`) are also optional per-type; missing folders disable that asset type gracefully.
