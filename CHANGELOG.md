# Changelog

All notable changes to this project will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [2.7.0] — 2026-04-03

### Added
- **BossEncounter** — multi-phase world boss system with loot drops, respawn cooldown, and proximity engagement detection

---

## [2.6.0] — 2026-04-03

### Added
- **EconomyManager** — per-player Gold balance, shop buy/sell, player-to-player transfer, DataStore persistence
- **SkillSystem** — XP/leveling engine, skill tree (active + passive), cooldown tracking, skill point allocation

---

## [2.5.0] — 2026-04-03

### Added
- **FactionSystem** — 4 factions, reputation tiers, inter-faction relation matrix, join/leave API
- **CraftingSystem** — recipe-based crafting with Inventory integration, level requirements
- **ClanSystem** — player-created clans, invite/leave, clan XP & level, leader management
- **DailyRewards** — 7-day streak table, DataStore-backed claim tracking, bonus items on key days

### Updated
- `rojo/default.project.json` — registered all 9 new modules
- `WorldConfig.lua` — added config keys for v2.5–v2.7 systems (economy, skills, bosses, crafting, clans, daily rewards)

---

## [2.4.0] — Previous

### Added
- CombatSystem — melee/ranged/magic damage, status effects DoT loop
- Inventory — slot-based inventory with stacking and equip slots
- NPCDialogue — branching dialogue trees
- DayNightCycle — Lighting-driven day/night with configurable hour speed

---

## [2.3.0] — Previous

### Added
- QuestSystem — dynamic quest tracking
- AdminPanel — runtime world controls
- LODManager — multi-level terrain detail

---

## [2.2.0] — Previous

### Added
- MobSpawner — biome-aware mob spawning
- LootTable — weighted loot rolls

---

## [2.0.0] — Initial

### Added
- Core procedural world: chunks, biomes, ores, rivers, dungeons, weather, seed persistence, streaming
