# Changelog

## [2.1.0] — 2026-04-03

### Added
- **RiverCarver** — gradient-descent river tracing from mountain saddle points toward WaterLevel; configurable via `WorldConfig.RiverSettings`
- **DungeonGenerator** — BSP-based underground dungeon generation with rooms, L-shaped corridors, and prop placement (`DungeonProps` folder); configurable via `WorldConfig.DungeonSettings`
- **WeatherManager** (server) — biome-zone weather polling; fires `WeatherChanged` RemoteEvent per player when entering a new zone
- **WeatherClient** (LocalScript) — rain, snow, and ash particle effects driven by `WeatherChanged` events
- **SeedPersistence** — DataStore-backed seed storage; world topology preserved across server restarts; `ResetSeed()` for admin resets
- **Rojo project file** (`rojo/default.project.json`) — maps all `src/*.lua` to correct Roblox service locations
- `WorldConfig.RiverSettings` — spring grid step, min height, step size, carve radius, max rivers
- `WorldConfig.DungeonSettings` — dungeon Y depth, BSP rect size, grid step, max count, spawn threshold
- `WorldConfig.Settings.WeatherCheckInterval` — polling frequency for WeatherManager

### Changed
- `WorldGenerator` updated to orchestrate RiverCarver, DungeonGenerator, WeatherManager, and SeedPersistence
- `WorldConfig.Seed = 0` now defers to DataStore persistence instead of an ephemeral random seed

## [2.0.0] — 2026-03-01

### Added
- 9-biome system with inverse-square-distance blending
- 3-octave FBM layered terrain (base + detail + fine + mountains)
- 3D cave system with configurable Y depth band
- Ore vein injection (Coal, Iron, Gold, Diamond)
- Per-biome structure placement (campfires, igloos, ruins, temples, pillars)
- Tree, rock, bush surface asset placement
- Chunk streaming runtime (load/unload around players)
- Full `--!strict` Luau type annotations throughout

## [1.0.0] — 2025-12-01

### Initial release
- Basic flat terrain with Perlin height
- Single biome, no streaming
