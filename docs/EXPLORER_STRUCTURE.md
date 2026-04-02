# Roblox Studio Explorer Structure

```text
Workspace
├── Terrain                          ← Roblox built-in
└── ProceduralAssets (Folder)        ← Auto-created at runtime

ServerScriptService
└── WorldGenerator     (Script)      ← src/WorldGenerator.lua

ReplicatedStorage
├── WorldConfig        (ModuleScript) ← src/WorldConfig.lua
├── BiomeResolver      (ModuleScript) ← src/BiomeResolver.lua
├── ChunkHandler       (ModuleScript) ← src/ChunkHandler.lua
├── AssetPlacer        (ModuleScript) ← src/AssetPlacer.lua
└── Assets             (Folder)
    ├── Trees
    │   ├── Tree_Pine  (Model, PrimaryPart required)
    │   ├── Tree_Oak   (Model)
    │   └── Tree_Birch (Model)
    ├── Rocks
    │   ├── Rock_Small  (Model)
    │   ├── Rock_Medium (Model)
    │   └── Rock_Large  (Model)
    └── Bushes
        ├── Bush_Round (Model)
        └── Bush_Shrub (Model)
```
