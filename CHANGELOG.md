# Changelog

## v2.0.0 — 2026-04-02

### Added
- **5 new biomes**: Jungle, Tundra, Volcano, Swamp, Ocean (9 total)
- **OreGenerator** module — coal, iron, gold, diamond ore veins underground
- **StructurePlacer** module — biome-specific structures (campfires, ruins, igloos, volcanite pillars)
- **StreamingManager** module — runtime chunk streaming around players; unloads far chunks to save memory
- `WorldConfig.OreVeins` table for tunable ore settings
- `WorldConfig.Structures` table for per-biome structure lists
- Biome-specific ambient color hints via `FogColor` in WorldConfig

### Improved
- `ChunkHandler` now calls OreGenerator + StructurePlacer per chunk
- `BiomeResolver` expanded to 9 poles with correct temp/moisture positioning
- `WorldGenerator` now spawns StreamingManager after world completes
- `WorldConfig.Settings.MaxConcurrentChunks` increased default to 10
- All modules use explicit Luau type annotations throughout
- README updated with v2 features and biome chart

## v1.0.0 — 2026-04-02
- Initial release: 4 biomes, chunk generation, caves, water, asset placement
