# Changelog — roblox-procedural-worlds

## [v2.3.0] — 2026-04-03
### Added
- `.master-prompt.md` — AI development rules, architecture conventions, module standards, dependency graph, performance budget
- `src/init.server.lua` — proper entry point that boots WorldGenerator
- `src/QuestSystem.lua` — procedural quest generation (kill/explore/loot/survive/boss) with biome-aware targets, per-player cap, reward via LootTable
- `src/AdminPanel.lua` — in-game debug GUI: seed display, position, biome, mob count, chunk info, regen seed button, clear mobs button; Studio = always admin
- `src/LODManager.lua` — 4-tier LOD system based on chunk distance, hides decorations and terrain at range, full hide at 7+ chunks
- `docs/architecture.md` — full system diagram, data flow for chunk/mob/quest/LOD lifecycles, module API summary
- `WorldConfig.lua` v2.3: added `Debug` flag, `AdminUserIds`, `QuestsPerPlayer`
- `WorldGenerator.lua` v2.3: boots QuestSystem, LODManager, AdminPanel; passes chunk model to LODManager
- `rojo/default.project.json` updated with QuestSystem, AdminPanel, LODManager

---

## [v2.2.0] — 2026-04-03
### Added
- `LootTable.lua` — weighted procedural loot generation with 4 tiers
- `MobSpawner.lua` — biome-aware NPC spawning with per-player cap and auto-despawn
- `WorldConfig.lua` extended: LootTables, MobSpawns, DungeonChestTiers/Weights
- `DungeonGenerator.lua` updated: chests filled via LootTable.FillChest()
- `WorldGenerator.lua` updated: MobSpawner.Start(seed) in Init()

---

## [v2.1.0]
### Added
- Rivers (RiverCarver)
- Dungeons (DungeonGenerator)
- Weather system (WeatherManager + WeatherClient)
- Seed persistence (SeedPersistence)
- Rojo project config
