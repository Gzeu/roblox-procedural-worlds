# Changelog

All notable changes to **roblox-procedural-worlds** are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
Versioning: [Semantic Versioning](https://semver.org/)

---

## [5.0.0] - 2026-04-03

### Added
- **FightingStyles.lua** — Anime RPG combat layer with unlockable styles (`Warrior`, `Rogue`, `Mystic`, `Berserker`), combo chains (up to 5 hits, per-style combo scaling), a 0–100 stance meter, crit and dodge adjustments, and `buildAttackProfile()` that returns per-hit modifiers for the combat pipeline.
- **AwakenSystem.lua** — Three-stage transformation system (`Burst` lv10, `Ascended` lv25, `Mythic` lv50). Players accumulate `AwakenEnergy` (0–100) from kills then activate a timed buff state (damage, speed, maxHP, crit). Auto-expires with cooldown.
- **ClanSystem.lua** — Weighted clan roll at first join: `Ironfang` (Common 50%), `Moonveil` (Rare 28%), `Stormcall` (Epic 15%), `Sunbreaker` (Legendary 7%). Each clan provides passive stat bonuses via `getPassiveBonuses()`. Clan name written as a Player Attribute.
- **RunModifiers.lua** — Roguelite boon/curse system scoped per dungeon/arena run. Weighted auto-roll of 5 boons and 5 curses. `getPlayerEffects()` merges all active modifiers into one effect table. Clean teardown via `endRun()`.
- **BaseBuilding.lua** — 4-stud snap-grid placement, per-player limit (100), minimum spacing collision (6 studs), owner attribute tags, `serializePlayerBuilds()` / `loadPlayerBuilds()` for DataStore persistence, fallback Part model when template is missing.
- **EconomyManager.lua** — Player gold wallet (default 250g, synced as Player Attribute) with `addGold`/`removeGold` and a server-side listing market (`createListing`, `cancelListing`, `purchaseListing`). Inventory-module agnostic with graceful fallback.

### Changed
- `init.server.lua` — v5.0: loads all six new modules, adds `Sanctum` waypoint. `PlayerAdded` initialises clan, fighting style, awaken and economy. Boss kills grant XP + awaken energy. Mob kills grant awaken energy. Level-up milestones auto-unlock styles (Rogue @5, Mystic @10, Berserker @20).
- `CHANGELOG.md` — Added v5.0.0 section.

---

## [4.0.0] - 2026-04-03

### Added
- **AIMemory.lua** — Per-mob persistent memory: last target, observed positions (FIFO 5), aggression cooldown.
- **AIGroupBehavior.lua** — Pack coordination: alert leader, flanker, retreat signaler with dynamic role assignment.
- **SkillSystem.lua** — XP → level → skill points → 4 attributes (Strength, Agility, Intelligence, Endurance).
- **BossEncounter.lua** — HP-threshold phase transitions, enrage timer, phase-specific special attacks.
- **NPCDialogue.lua** v2 — Branching dialogue tree, per-session choice history, quest integration hooks.

### Changed
- `init.server.lua` — v4.0: loads all five modules, adds `BossLair` waypoint, connects boss/dialogue/skill hooks.

---

## [3.0.0] - 2026-04-03

### Added
- **MobAI.lua** — FSM: Idle → Patrol → Alert → Chase → Attack → Flee → Dead.
- **AINavigator.lua** — PathfindingService wrapper with straight-line fallback.
- **BehaviorTree.lua** — Composable BT engine: Sequence, Selector, Parallel, Condition, Action, Inverter, Repeater, Cooldown, Tree.
- **AIDirector.lua** — Per-player Dynamic Difficulty Adjustment with 6 tiers (Trivial → Nightmare).
- **AIConfig.lua** — Per-mob config table + Aggressive/Passive BT presets.

---

## [2.5.0] - 2026-04-03

### Added
- EventBus, CraftingSystem, TeleportManager, ParticleEffects. Two new biomes, ore, mob.

### Fixed
- Chunk unload thrashing bug. SeedPersistence fallback.

---

## [2.0.0] - 2025-12-10

### Added
- RiverCarver, VillageGenerator, DungeonGenerator, CombatSystem, QuestSystem, NPCDialogue, AdminPanel, LODManager, StreamingManager.

---

## [1.0.0] - 2025-09-01

### Added
- Procedural terrain, biome system, chunk loading, asset placement, ore generation, day/night cycle, weather, inventory, persistence, mob spawner, loot tables.
