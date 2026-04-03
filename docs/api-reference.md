# API Reference — roblox-procedural-worlds

> Auto-generated from `.master-prompt.md` conventions. Updated at v2.5.0.

---

## WorldGenerator
```lua
WorldGenerator.Init(forceSeed?: number)
WorldGenerator.GetSeed() → number
WorldGenerator.SetSeed(seed: number)
WorldGenerator.GenerateChunk(cx: number, cz: number)
WorldGenerator._TrackPlayer(player: Player)
```

## WorldConfig
All values are read-only at runtime. Modify only in this file.

| Key | Type | Default | Description |
|---|---|---|---|
| `Debug` | bool | false | Enable warn() logs across all modules |
| `AdminUserIds` | table | {} | UserId list for AdminPanel access |
| `ChunkSize` | number | 64 | Studs per chunk side |
| `RenderDistance` | number | 4 | Chunks loaded around each player |
| `BaseHeight` | number | 20 | Terrain base Y |
| `DayLengthSeconds` | number | 600 | Seconds per full day/night cycle |
| `VillageConfig` | table | see file | frequency, minHouses, maxHouses, radius |
| `QuestsPerPlayer` | number | 3 | Active quests per player |
| `MobSpawnCap` | number | 10 | Max mobs per player |

## BiomeResolver
```lua
BiomeResolver.GetBiomeAt(x: number, z: number, seed: number) → string
```

## ChunkHandler
```lua
ChunkHandler.BuildChunk(cx: number, cz: number, seed: number) → Model?
```

## OreGenerator
```lua
OreGenerator.PlaceOres(worldX: number, worldZ: number, seed: number)
```

## RiverCarver
```lua
RiverCarver.CarveAt(worldX: number, worldZ: number, seed: number)
```

## DungeonGenerator
```lua
DungeonGenerator.Generate(originPos: Vector3, seed: number) → Model
DungeonGenerator.TrySpawnAt(x: number, z: number, seed: number) → bool
```

## LootTable
```lua
LootTable.Generate(tier: string, seed: number) → { {name, qty, model?} }
LootTable.FillChest(chestModel: Instance, tier: string, seed: number)
```

## MobSpawner
```lua
MobSpawner.Start(worldSeed: number)
MobSpawner.GetActive() → table
```

## QuestSystem
```lua
QuestSystem.Start(worldSeed: number)
QuestSystem.AssignQuests(player: Player, seed: number) → table
QuestSystem.UpdateProgress(player: Player, questType: string, amount?: number)
QuestSystem.GetQuests(player: Player) → table
QuestSystem.OnQuestComplete(player: Player, quest: table)
```

## VillageGenerator
```lua
VillageGenerator.Generate(originPos: Vector3, seed: number) → Model
VillageGenerator.TrySpawnAt(x: number, z: number, seed: number) → bool
```

## PlayerPersistence
```lua
PlayerPersistence.Start()
PlayerPersistence.Get(player: Player) → { xp, level, inventory, quests, lastPos }
PlayerPersistence.AddXP(player: Player, amount: number)
PlayerPersistence.AddItem(player: Player, itemName: string, qty?: number)
PlayerPersistence.SaveNow(player: Player)
```

## NPCDialogue
```lua
NPCDialogue.Start(worldSeed: number)
NPCDialogue.Register(npcModel: Model, customLines?: table)
```

## DayNightCycle
```lua
DayNightCycle.Start(startTimeNorm?: number)  -- 0=midnight, 0.5=noon
DayNightCycle.GetNormalized() → number       -- 0..1
DayNightCycle.IsNight() → bool
```

## AdminPanel
```lua
AdminPanel.Init(worldGeneratorRef: table, mobSpawnerRef: table)
```

## LODManager
```lua
LODManager.Start()
LODManager.RegisterChunk(cx: number, cz: number, model: Model)
LODManager.UnregisterChunk(cx: number, cz: number)
LODManager.UpdateAll()
```

## SeedPersistence
```lua
SeedPersistence.Save(seed: number)
SeedPersistence.Load() → number?
```

## WeatherManager
```lua
WeatherManager.Start(seed: number)
```

## StreamingManager
```lua
StreamingManager.Start(seed: number)
```
