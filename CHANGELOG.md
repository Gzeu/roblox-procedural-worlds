# Changelog — roblox-procedural-worlds

## [v2.5.0] — 2026-04-03
### Added
- `VillageGenerator.lua` — procedural villages: houses (random color/roof), well, roads, torch posts, ring layout around center
- `PlayerPersistence.lua` — DataStore save/load: XP, level, inventory, last position; auto-save every 60s + on PlayerRemoving
- `NPCDialogue.lua` — server: proximity trigger (15 studs), biome-aware dialogue lines, 10s cooldown per player/NPC pair, fires RemoteEvent
- `NPCDialogueClient.lua` — client: receives dialogue event, renders BillboardGui above NPC with 6s auto-remove
- `DayNightCycle.lua` — smooth 600s day/night cycle: ClockTime + Ambient + OutdoorAmbient interpolated across 7 phase keyframes; IsNight() helper
- `docs/api-reference.md` — full public API for every module
- `WorldConfig.lua` v2.5: added `DayLengthSeconds`, `VillageConfig`
- `WorldGenerator.lua` v2.5: boots PlayerPersistence, NPCDialogue, DayNightCycle, VillageGenerator.TrySpawnAt in GenerateChunk
- `rojo/default.project.json` updated: VillageGenerator, PlayerPersistence, NPCDialogue, DayNightCycle, NPCDialogueClient

---

## [v2.3.0] — 2026-04-03
### Added
- `.master-prompt.md`, `init.server.lua`, `QuestSystem`, `AdminPanel`, `LODManager`, `docs/architecture.md`

---

## [v2.2.0] — 2026-04-03
### Added
- `LootTable`, `MobSpawner`, `WorldConfig` extended with loot + mob pools

---

## [v2.1.0]
### Added
- Rivers, Dungeons, Weather, Seed persistence, Rojo config
