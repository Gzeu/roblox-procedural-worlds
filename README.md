# 🌍 Roblox Procedural Worlds

> Generate fully procedural Roblox worlds from a single JSON config — rivers, dungeons, underground layers, large structures, and more.

[![CI](https://github.com/Gzeu/roblox-procedural-worlds/actions/workflows/ci.yml/badge.svg)](https://github.com/Gzeu/roblox-procedural-worlds/actions/workflows/ci.yml)

---

## ✨ What's New — v3.0

| Feature | Details |
|---|---|
| **River carving** | Hydraulic erosion algorithm traces rivers from peaks to water level |
| **Dungeon rooms** | Procedural rooms + corridors generated directly in `.rbxlx` as `Model "Dungeons"` |
| **Underground layers** | Bedrock (y<10) · Stone (y<60) · Dirt (y<surface−3) · Surface cap |
| **Large structures** | Towers & ruins placed semi-randomly per seed |
| **`--watch` flag** | Auto-rebuilds on every JSON save (`Ctrl+C` to stop) |
| **`--format rojo`** | Exports `src/` folder compatible with Rojo / VS Code plugin |
| **3D Isometric preview** | Three.js inline preview with drag-to-rotate & scroll-to-zoom |
| **URL Share** | Config encoded as Base64 in URL hash — shareable one-click link |
| **Undo / Redo** | Ctrl+Z / Ctrl+Y — up to 20 states |
| **Custom presets** | Save & load your own presets in `localStorage` |
| **BiomeBlending.lua** | Gradient-noise soft transitions between biomes |
| **ChunkHandler.lua v4** | Async chunk loading via `task.defer` |
| **MobAI.lua v5** | Vision cone 90°, hearing radius, memory decay |
| **CI workflow** | JSON schema validation + smoke build on every PR |
| **Configs gallery** | 5 example worlds: medieval, scifi, horror, jungle, arctic |

---

## 🚀 Quick Start

```bash
# 1. Clone
git clone https://github.com/Gzeu/roblox-procedural-worlds
cd roblox-procedural-worlds

# 2. Edit config
cp configs/medieval.json world_config.json

# 3. Build
python tools/build_world.py world_config.json

# 4. Open output/world.rbxlx in Roblox Studio
```

### Watch mode (auto-rebuild)
```bash
python tools/build_world.py world_config.json --watch
```
Every time you save `world_config.json`, the world is rebuilt automatically.

### Rojo export
```bash
python tools/build_world.py world_config.json --format rojo
# → src/heightmap.json  ready for Rojo plugin sync
```

---

## 🗺 Configs Gallery

| File | Theme | Biomes | Rivers | Dungeons | Structures |
|---|---|---|---|---|---|
| `configs/medieval.json` | 🏰 Medieval Kingdom | Forest · Swamp · Desert | 5 | 8 | 10 |
| `configs/scifi.json` | 🚀 Sci-Fi Wasteland | Volcanic · Desert | 0 | 12 | 8 |
| `configs/horror.json` | 💀 Horror Moors | Swamp · Forest | 4 | 10 | 7 |
| `configs/jungle.json` | 🌿 Jungle Paradise | Forest · Swamp · Ocean | 7 | 6 | 5 |
| `configs/arctic.json` | ❄ Arctic Tundra | Tundra · Ocean | 2 | 5 | 4 |

---

## 🌋 Biome Props

| Biome | Props |
|---|---|
| Desert | Cactuși |
| Swamp | Swamp Trees, Moss |
| Volcanic | Boulders, Lava Pits (Neon) |
| Tundra | Ice Boulders, Snow Mounds |
| Ocean | Ocean Rocks |
| Forest | Trees |

---

## 🏗 Underground Layers

| Layer | Y Range | Material |
|---|---|---|
| Bedrock | 0 – 10 | Slate |
| Stone | 10 – 60 | SmoothPlastic |
| Dirt | 60 – surface−3 | Grass |
| Surface cap | surface | Biome color |
| Snow cap | > 70% maxHeight | White |

---

## 🗡 Dungeon Generation

Dungeons are embedded as a `Model` named **Dungeons** in the `.rbxlx`.
- Rooms: 10–24 cells wide, 6–10 cells tall, placed at y=15–45
- Corridors: L-shaped hallways connecting consecutive rooms
- Count: controlled by `dungeonRooms` in config

---

## 🏰 Large Structures

- **Towers**: 3-tier Part stack (base → mid → top + flag)
- **Ruins**: 3–7 randomly-sized pillars per ruin
- Count: `structures` in config
- Placement: deterministic from `seed`

---

## 🌊 Rivers

Hydraulic erosion algorithm:
1. Starts near terrain peaks
2. Walks downhill each step (steepest-descent)
3. Carves width `riverWidth` and depth `riverDepth` into heightmap
4. Stops when reaching `waterLevel`

Config keys: `rivers`, `riverDepth`, `riverWidth`

---

## 🤖 Lua Modules

| Module | Version | Purpose |
|---|---|---|
| `src/BiomeBlending.lua` | v3.0 | Gradient-noise soft biome transitions |
| `src/ChunkHandler.lua` | v4.0 | Async chunk load/unload with `task.defer` |
| `src/MobAI.lua` | v5.0 | Vision cone · Hearing radius · Memory decay |

---

## 🔧 world_config.json Reference

```json
{
  "seed": 42,
  "worldSize": 256,
  "maxHeight": 120,
  "waterLevel": 20,
  "noiseScale": 0.008,
  "rivers": 4,
  "riverDepth": 6,
  "riverWidth": 3,
  "dungeonRooms": 6,
  "structures": 5,
  "propDensity": 0.04,
  "biomes": ["Forest", "Desert", "Swamp", "Volcanic", "Tundra", "Ocean"]
}
```

---

## 📦 Project Structure

```
roblox-procedural-worlds/
├── tools/
│   ├── build_world.py          # v3.0 — main builder
│   └── world-configurator.html # v3.0 — GUI with 3D preview
├── src/
│   ├── BiomeBlending.lua       # v3.0
│   ├── ChunkHandler.lua        # v4.0
│   └── MobAI.lua               # v5.0
├── configs/
│   ├── medieval.json
│   ├── scifi.json
│   ├── horror.json
│   ├── jungle.json
│   └── arctic.json
├── .github/workflows/
│   └── ci.yml                  # JSON validate + smoke build
└── README.md
```

---

## 📄 License

MIT — see [LICENSE](LICENSE)
