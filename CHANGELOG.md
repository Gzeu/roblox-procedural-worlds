# Changelog

All notable changes to **roblox-procedural-worlds** are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
Versioning: [Semantic Versioning](https://semver.org/)

---

## [2.5.0] - 2026-04-03

### Added
- **EventBus.lua** — Centralized publish/subscribe event system for decoupled inter-module communication. Supports `on`, `once`, `emit`, `clear`, and `debug` methods.
- **CraftingSystem.lua** — Recipe-based crafting engine with ingredient validation, level requirements, runtime recipe registration, and full EventBus integration (CraftFailed / CraftSuccess events).
- **TeleportManager.lua** — In-world teleportation with named waypoints, cooldown enforcement, and cross-server TeleportService support. Three default waypoints registered at boot (Spawn, Market, Dungeon).
- **ParticleEffects.lua** — Preset-based particle emitter manager (Spark, Heal, Dust, Magic, Blood). Supports burst emit at Vector3 or BasePart, continuous attach, and per-part stopAll cleanup.
- `WorldConfig.lua` — Added v2.5 configuration keys: `TELEPORT_COOLDOWN`, `MAX_WAYPOINTS`, `CRAFTING_ENABLED`, `PARTICLE_POOL_SIZE`, `EVENT_BUS_DEBUG`.
- Two new biomes: **Swamp** and **Volcanic** added to biome table.
- New ore: **MagicCrystal** added to ore generation table (rare, deep).
- New mob: **Wolf** added to mob spawner config (Taiga/Tundra, hostile, level 5).
- Six crafting recipes: WoodenSword, HealthPotion, IronPickaxe, Torch, StoneWall, EnchantedArmor.

### Changed
- `init.server.lua` — Fully rewritten bootstrap to load v2.5 modules in dependency order with named waypoint registration and EventBus debug hooks.
- `WorldConfig.lua` — Extended with 10 biomes (up from 8), expanded mob table, and richer ore list.

### Fixed
- Chunk unload distance was equal to render distance (could cause thrashing). `UNLOAD_DISTANCE` now set to `RENDER_DISTANCE + 3`.
- `SeedPersistence` fallback now correctly calls `generateSeed()` when no saved seed exists.

---

## [2.0.0] - 2025-12-10

### Added
- RiverCarver: procedural river paths using midpoint displacement
- VillageGenerator: NPC villages with procedural building layouts
- DungeonGenerator: BSP room-based dungeon system
- CombatSystem: hitbox detection, damage calculation, knockback
- QuestSystem: dynamic quest assignment and tracking
- NPCDialogue: branching dialogue trees with player state awareness
- AdminPanel: in-game admin UI for world manipulation
- LODManager: Level of Detail switching based on camera distance
- StreamingManager: player-aware chunk streaming prioritization

### Changed
- WorldGenerator fully refactored to modular pipeline architecture
- ChunkHandler now supports async load/unload with priority queue

---

## [1.0.0] - 2025-09-01

### Added
- Initial procedural terrain generation with Perlin noise
- Biome system (6 biomes)
- Chunk-based world loading
- Tree and asset placement
- Ore generation
- Day/Night cycle
- Weather system
- Player inventory and persistence
- MobSpawner with basic AI
- LootTable system
