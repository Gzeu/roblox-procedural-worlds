# Changelog — roblox-procedural-worlds

## [v2.2.0] — 2026-04-03
### Added
- `LootTable.lua` — weighted procedural loot generation with 4 tiers: Common, Uncommon, Rare, Legendary
- `MobSpawner.lua` — biome-aware NPC spawning with per-player cap, heartbeat loop and auto-despawn at distance
- `WorldConfig.lua` extended with `LootTables`, `MobSpawns` (8 biome pools), `MobSpawnCap`, `DungeonChestTiers` and `DungeonChestWeights`
- `DungeonGenerator.lua` updated: chests now filled via `LootTable.FillChest()` with tier selected by weighted random
- `WorldGenerator.lua` updated: `MobSpawner.Start(seed)` called during `Init()`
- `rojo/default.project.json` updated with `LootTable` and `MobSpawner` module entries

### Changed
- Dungeon rooms now include a neon torch-light placeholder part
- Chest position randomized within room bounds
- `WorldConfig` cleaned up and centralized (rivers, weather, dungeons, biomes all in one place)

---

## [v2.1.0] — Previous release
### Added
- Rivers (RiverCarver)
- Dungeons (DungeonGenerator)
- Weather system (WeatherManager + WeatherClient)
- Seed persistence (SeedPersistence)
- Rojo project config
