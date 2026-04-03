# Changelog

All notable changes to **roblox-procedural-worlds** are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
Versioning: [Semantic Versioning](https://semver.org/)

---

## [4.0.0] - 2026-04-03

### Added
- **AIMemory.lua** — Per-mob persistent memory system. Each mob stores: last attacked target (with timestamp), a list of observed player positions (up to 5 entries, FIFO), and an aggression cooldown timer that prevents non-stop attacking. Memory is wiped on mob death via `AIMemory.clearMemory()`. Emits `AIMemory:Updated` debug events on every write.
- **AIGroupBehavior.lua** — Pack-level coordination layer on top of the existing MobAI FSM. Mobs that share a `packId` tag collaborate: one mob acts as the **Alert Leader** (broadcasts `AIGroup:Alert` to the EventBus when it spots a player), one attempts a **Flank Maneuver** (moves to the player's opposite side before attacking), and one acts as **Retreat Signaler** (emits `AIGroup:Retreat` when pack aggregate HP drops below 25 %). All roles are assigned dynamically at spawn and reassigned on member death.
- **SkillSystem.lua** — Full RPG progression module. Tracks XP per player; every kill and quest completion grants XP via `SkillSystem.grantXP(player, amount)`. XP thresholds follow a quadratic curve (base 100 × level²). On level-up: emits `SkillSystem:LevelUp`, awards 3 skill points. Players distribute skill points across 4 attributes — **Strength** (melee damage multiplier), **Agility** (movement speed, dodge chance), **Intelligence** (spell damage, XP gain bonus), **Endurance** (max HP, damage reduction). Attributes apply immediately via `CombatSystem` multipliers.
- **BossEncounter.lua** — Boss lifecycle manager. Each boss definition specifies HP thresholds that trigger **phase transitions** (e.g. Phase 1: 100 %→60 %, Phase 2: 60 %→30 %, Phase 3: 30 %→0 %). An **enrage timer** activates after a configurable duration (default 180 s) if the boss is still alive — doubling damage and movement speed and emitting `Boss:Enraged`. Each phase unlocks **unique special attacks** (ground slam AoE, projectile barrage, summon minions) executed through the BehaviorTree `Action` nodes. Emits `Boss:PhaseChanged`, `Boss:Enraged`, `Boss:Defeated`.
- **NPCDialogue.lua** *(v2 upgrade)* — Replaces the flat dialogue string system from v2.0 with a full **dialogue tree**: each NPC has a root node with branching `choices` arrays. Player choice selections are tracked per-session in a `choiceHistory` table. Quest integration: choice nodes can carry a `questAction` field (`"accept"` or `"complete"`) that fires `NPCDialogue:QuestAccepted` / `NPCDialogue:QuestCompleted` on the EventBus, which `init.server.lua` routes to `QuestSystem` and `SkillSystem.grantXP`.

### Changed
- `init.server.lua` — Upgraded to v4.0. Loads all five new modules. Adds EventBus hooks for `AIGroup:Alert`, `AIGroup:Retreat`, `Boss:PhaseChanged`, `Boss:Enraged`, `Boss:Defeated`, `SkillSystem:LevelUp`, `NPCDialogue:QuestAccepted`, `NPCDialogue:QuestCompleted`. `Players.PlayerAdded` now calls `SkillSystem.initPlayer`; `Players.PlayerRemoving` calls `SkillSystem.savePlayer`. Boss death awards 500 XP to the killer. Quest completion via dialogue awards 100 XP. New `BossLair` waypoint added at `(-1200, 30, 800)`. `AIMemory.clearMemory` called on `MobAI:Died`.
- `WorldConfig.lua` — Add v4 config keys: `SKILL_XP_BASE`, `SKILL_POINTS_PER_LEVEL`, `BOSS_ENRAGE_TIMER`, `BOSS_PHASE_THRESHOLDS`, `AI_MEMORY_POSITION_LIMIT`, `AI_MEMORY_AGGRESSION_COOLDOWN`, `AI_GROUP_RETREAT_HP_PERCENT`.

### Architecture Notes
- **AIMemory is mob-local**: the memory table is keyed by `mobModel` (userdata reference) and garbage-collected automatically when the mob model is destroyed.
- **AIGroupBehavior operates via EventBus**, not direct references — packs are identified by a string `packId` tag on the mob model, keeping the system decoupled from MobAI internals.
- **SkillSystem attribute effects** are applied as multipliers passed into `CombatSystem.calculateDamage` and `CombatSystem.applyDamage` — no monkey-patching of Humanoid properties.
- **BossEncounter** integrates with `BehaviorTree` for special attack sequencing. Phase transitions swap the active BT root node, keeping phase logic cleanly separated.
- **NPCDialogue v2** maintains backward compatibility: NPCs that still use the old flat string format are auto-wrapped into a single-node tree with no choices.

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
