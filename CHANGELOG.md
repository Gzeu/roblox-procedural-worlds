# Changelog — roblox-procedural-worlds

## [v2.4.0] — 2026-04-03
### Added
- `src/CombatSystem.lua` — server-authoritative hit detection, damage, hit-flash, knockback (BodyVelocity), death event, mob respawn timer; weapon damage read from player attributes set by Inventory
- `src/Inventory.lua` — per-player slot inventory (20 slots), stacking, AddItem/RemoveItem/EquipItem/Has/GiveLoot; weapon stats applied as player attributes for CombatSystem; synced via SetAttribute
- `src/NPCDialogue.lua` — procedural dialogue engine: greeting + biome + weather + quest-type lines, template variable substitution ({mob}, {biome}); in-game GUI with Next/Close button; auto-close after 30s
- `src/DayNightCycle.lua` — smooth Heartbeat-driven day/night: ClockTime, Ambient, Brightness, FogColor per time band (dawn/dusk/night/day); event callbacks OnDawn/OnDusk/OnNoon/OnMidnight; configurable CycleMinutes
- `WorldConfig.lua` v2.4: added `Combat` table (BaseDamage, AttackRange, AttackCooldown, KnockbackForce, MobRespawnTime), `Inventory` table (MaxSlots, Weapons map with damage/range), `DayNight` table (CycleMinutes, StartHour, Latitude)
- `WorldGenerator.lua` v2.4: boots CombatSystem, Inventory, DayNightCycle; hooks OnDusk/OnDawn to double/restore MobSpawnCap (night = more mobs)
- `rojo/default.project.json`: registered CombatSystem, Inventory, NPCDialogue, DayNightCycle

### Changed
- `WorldGenerator.SetSeed()` now also calls `SeedPersistence.Save()` immediately
- MobSpawnCap dynamically scales: 10 (day) → 18 (night) via DayNightCycle callbacks

---

## [v2.3.0] — 2026-04-03
### Added
- `.master-prompt.md`, `src/init.server.lua`, `src/QuestSystem.lua`, `src/AdminPanel.lua`, `src/LODManager.lua`, `docs/architecture.md`
- `WorldConfig.lua` v2.3: Debug, AdminUserIds, QuestsPerPlayer

---

## [v2.2.0] — 2026-04-03
### Added
- `LootTable.lua`, `MobSpawner.lua`, extended WorldConfig

---

## [v2.1.0]
### Added
- Rivers, Dungeons, Weather, Seed persistence, Rojo config
