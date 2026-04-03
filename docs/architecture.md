# Architecture — roblox-procedural-worlds

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     ServerScriptService                         │
│                                                                 │
│  init.server.lua                                                │
│       └── WorldGenerator.Init(seed?)                            │
│             │                                                   │
│             ├── SeedPersistence     (DataStore: save/load seed) │
│             ├── WeatherManager      (state machine, 120s cycle) │
│             ├── StreamingManager    (chunk radius tracking)     │
│             ├── MobSpawner          (biome-aware, per-player)   │
│             ├── QuestSystem         (procedural, 3/player)      │
│             ├── LODManager          (detail reduction by dist)  │
│             ├── AdminPanel          (in-game debug GUI)         │
│             │                                                   │
│             └── GenerateChunk(cx, cz)                           │
│                   ├── ChunkHandler.BuildChunk()                 │
│                   │     └── BiomeResolver.GetBiomeAt()          │
│                   │     └── AssetPlacer.DecorateChunk()         │
│                   ├── OreGenerator.PlaceOres()                  │
│                   ├── RiverCarver.CarveAt()                     │
│                   └── DungeonGenerator.TrySpawnAt()             │
│                         └── LootTable.FillChest()               │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                     StarterPlayerScripts                        │
│  WeatherClient  (fog, rain particles, sky tint)                 │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow

### World Initialization
1. `init.server.lua` requires `WorldGenerator`
2. `WorldGenerator.Init()` loads/generates seed via `SeedPersistence`
3. All subsystems boot with `Start(seed)` or `Init()`
4. Initial 9×9 chunk grid generates around spawn (0,0)
5. Player tracking begins — new chunks load as players move

### Chunk Lifecycle
```
GenerateChunk(cx, cz)
  → ChunkHandler.BuildChunk()    → terrain parts, biome colors
  → LODManager.RegisterChunk()   → LOD tracking
  → OreGenerator.PlaceOres()     → vein placement underground
  → RiverCarver.CarveAt()        → erosion pass
  → DungeonGenerator.TrySpawnAt()→ probabilistic dungeon spawn
       → LootTable.FillChest()   → weighted loot on chest parts
```

### Mob Lifecycle
```
MobSpawner (Heartbeat, every 5s)
  → BiomeResolver.GetBiomeAt(player pos)
  → WorldConfig.MobSpawns[biome]  → pick random mob def
  → Spawn part model near player
  → despawn if > 200 studs from owner
```

### Quest Lifecycle
```
QuestSystem.Start(seed)
  → PlayerAdded → AssignQuests(player, seed + userId)
       → 3 quests generated per player (kill/explore/loot/survive/boss)
       → reward = LootTable.Generate(tier, questSeed)
  → QuestSystem.UpdateProgress(player, type, amount)
       → on complete: OnQuestComplete() → sets player attributes
```

### LOD System
```
LODManager (Heartbeat, every 2s)
  → per chunk: calculate min distance to any player
  → tier 1 (0-2 chunks): full detail
  → tier 2 (2-4 chunks): hide decorations
  → tier 3 (4-7 chunks): terrain base only
  → tier 4 (7+ chunks):  fully hidden
```

## Module API Summary

| Module | Key Public Functions |
|---|---|
| WorldGenerator | `Init(seed?)`, `GetSeed()`, `SetSeed(seed)`, `GenerateChunk(cx,cz)` |
| BiomeResolver | `GetBiomeAt(x, z, seed)` |
| ChunkHandler | `BuildChunk(cx, cz, seed) → Model` |
| OreGenerator | `PlaceOres(worldX, worldZ, seed)` |
| RiverCarver | `CarveAt(worldX, worldZ, seed)` |
| DungeonGenerator | `Generate(origin, seed)`, `TrySpawnAt(x, z, seed)` |
| LootTable | `Generate(tier, seed)`, `FillChest(model, tier, seed)` |
| MobSpawner | `Start(seed)`, `GetActive()` |
| QuestSystem | `Start(seed)`, `AssignQuests(player, seed)`, `UpdateProgress(player, type, amt)`, `GetQuests(player)` |
| AdminPanel | `Init(worldGenRef, mobSpawnerRef)` |
| LODManager | `Start()`, `RegisterChunk(cx,cz,model)`, `UnregisterChunk(cx,cz)`, `UpdateAll()` |
| WeatherManager | `Start(seed)` |
| SeedPersistence | `Save(seed)`, `Load()` |
| StreamingManager | `Start(seed)` |
