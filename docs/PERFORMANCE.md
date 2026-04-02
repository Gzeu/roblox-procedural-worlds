# Performance Tuning Guide

## Generation Time Estimates

| Map Size  | Approx Chunks | Est. Gen Time | Recommended Settings |
|-----------|--------------|---------------|---------------------|
| 500×500   | ~289         | 15–30 s       | Defaults fine |
| 1000×1000 | ~1,111       | 60–120 s      | `VoxelSize = 8` |
| 2000×2000 | ~4,445       | 5–10 min      | `VoxelSize = 8`, `ChunkSize = 60`, `MaxConcurrentChunks = 12` |

## Key Levers

### VoxelSize
The single highest-impact setting. Doubling from `4` → `8` cuts `FillBlock` calls by **8×**.
Terrain looks slightly blockier but generation is ~8× faster.

### MaxConcurrentChunks
Keep ≤ 16. Too many concurrent `task.spawn()` micro-threads saturates the Lua scheduler
and causes frame drops without improving throughput. Ideal range: 6–12.

### ChunkSize
Larger chunks = fewer `task.spawn()` overheads. `60` studs is a good balance for large maps.

### Streaming Enabled
Enable `Workspace → StreamingEnabled` in Studio for maps above 1000 studs.
Roblox automatically unloads distant terrain on clients, dramatically improving client FPS.

### Migrate to WriteVoxels for Very Large Maps
For 2000+ stud maps, consider replacing `Terrain:FillBlock()` (one call per voxel) with
`Terrain:WriteVoxels()` (one call per chunk). This batches an entire chunk into a single
API call, removing per-voxel overhead. Requires restructuring `ChunkHandler` to build a 3D array.

### Asset Spawn Rates
`Model:Clone()` is expensive. For large maps, lower `TreeSpawnChance` to `0.01` and
consider lazy asset placement — only spawn props when a player enters a chunk's radius.
