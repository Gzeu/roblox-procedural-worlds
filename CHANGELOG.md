# Changelog

All notable changes to **roblox-procedural-worlds** are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
Versioning: [Semantic Versioning](https://semver.org/)

---

## [3.0.0] - 2026-04-03

### Added
- **MobAI.lua** — Full Finite State Machine (FSM) for mob intelligence. States: `Idle → Patrol → Alert → Chase → Attack → Flee → Dead`. Emits EventBus events on every transition, attack, damage, and death.
- **AINavigator.lua** — PathfindingService wrapper with automatic path recompute on block, jump waypoint support, and smooth `MoveTo` chaining. Falls back to straight-line movement on path failure.
- **BehaviorTree.lua** — Lightweight Behavior Tree engine. Node types: `Sequence`, `Selector`, `Parallel`, `Condition`, `Action`, `Inverter`, `Repeater`, `Cooldown`, `Tree`. Full composable architecture — no external dependencies.
- **AIDirector.lua** — Dynamic Difficulty Adjustment (DDA) system. Tracks per-player kill/death streaks, computes a normalized performance score (-1..1), and maps it to 6 difficulty tiers (Trivial → Nightmare). Scales mob damage, HP, and spawn rate in real-time. Score decays toward neutral over time. Integrates with EventBus (`MobAI:Died`, `AIDirector:ScoreUpdated`).
- **AIConfig.lua** — Per-mob base config table (Goblin, Skeleton, Troll, Dragon, Wolf, Deer) and two reusable BehaviorTree presets (`Aggressive`, `Passive`) ready to attach to any mob.
- `WorldConfig.lua` — Added v3.0 AI configuration keys: `AI_ENABLED`, `AI_BEHAVIOR_TREE`, `AI_DIRECTOR_ENABLED`, `AI_DIRECTOR_DECAY_RATE`, `AI_PATHFINDING_COOLDOWN`, `AI_DETECT_MULTIPLIER`, `AI_DAMAGE_MULTIPLIER`, `AI_DIFFICULTY_TIERS`.
- `init.server.lua` — Loads all v3.0 AI modules. Hooks `MobAI:Died` to trigger loot drops and particle effects. Hooks `AIDirector:ScoreUpdated` for debug logging. Adds `Arena` waypoint.

### Changed
- `MobSpawner.lua` — Now routes all spawned mobs through `AIDirector.applyScaling` to apply per-player difficulty before constructing the `MobAI` instance.
- `CombatSystem.lua` — Damage events now call `AIDirector.onDeath` on player death for score tracking.

### Architecture Notes
- MobAI FSM and BehaviorTree are **composable**: you can run both simultaneously (FSM handles macro state transitions, BT handles fine-grained per-tick decisions) or independently.
- AIDirector is **per-player**: each player has their own score and tier, so a veteran and a new player in the same server see different mob difficulties.
- AINavigator uses **task.spawn** for non-blocking waypoint traversal; it does not yield the main Heartbeat loop.

---

## [2.5.0] - 2026-04-03

### Added
- **EventBus.lua** — Centralized publish/subscribe event system.
- **CraftingSystem.lua** — Recipe-based crafting with 6 default recipes.
- **TeleportManager.lua** — Named waypoints + cross-server teleport with cooldown.
- **ParticleEffects.lua** — Preset particle emitter manager (Spark, Heal, Dust, Magic, Blood).
- `WorldConfig.lua` — v2.5 config keys added.
- Two new biomes: Swamp and Volcanic. New ore: MagicCrystal. New mob: Wolf.

### Fixed
- Chunk unload distance thrashing bug fixed (`UNLOAD_DISTANCE = RENDER_DISTANCE + 3`).
- `SeedPersistence` fallback now correctly generates a new seed.

---

## [2.0.0] - 2025-12-10

### Added
- RiverCarver, VillageGenerator, DungeonGenerator, CombatSystem, QuestSystem, NPCDialogue, AdminPanel, LODManager, StreamingManager.

---

## [1.0.0] - 2025-09-01

### Added
- Initial procedural terrain generation, biome system, chunk loading, asset placement, ore generation, day/night cycle, weather, inventory, persistence, mob spawner, loot tables.
