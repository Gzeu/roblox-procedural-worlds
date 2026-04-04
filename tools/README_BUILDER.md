# 🛠️ World Builder Tools

Acest director conține toolurile Python + HTML pentru a genera și configura lumi procedurale Roblox.

## Fișiere

| Fișier | Descriere |
|--------|----------|
| `tools/build_world.py` | Script Python care generează `.rbxlx` din JSON config |
| `tools/world-configurator.html` | Configurator vizual cu preview live în browser |
| `configs/default_world.json` | Config exemplu (seed 12345, Forest+Desert+Tundra) |

---

## Utilizare rapidă

### 1. Configurator vizual
Deschide `tools/world-configurator.html` direct în browser:
- Ajustează seed, chunk size, biome-uri, mobs, structuri
- Preview live al terenului procedural
- Click **⬇ Download Config** → salvează `world_config.json`

### 2. Build `.rbxlx`
```bash
python tools/build_world.py configs/default_world.json
# → My_Procedural_World.rbxlx
```

Cu output custom:
```bash
python tools/build_world.py configs/default_world.json MyWorld.rbxlx
```

### 3. Deschide în Roblox Studio
```
Roblox Studio → File → Open from File → MyWorld.rbxlx
```

---

## Format config JSON

```json
{
  "worldName": "My World",
  "seed": 12345,
  "chunkSize": 64,
  "renderDistance": 3,
  "maxHeight": 120,
  "waterLevel": 20,
  "noiseScale": 0.05,
  "biomes": ["Forest", "Desert", "Tundra"],
  "mobs": { "density": 5, "difficulty": "normal", "bosses": true, "groupAI": true },
  "structures": { "villages": true, "dungeons": true, "rivers": true, "ores": true },
  "systems": { "dayNightCycle": true, "weather": true, "baseBuilding": false, "clans": false, "dayLengthMinutes": 20 }
}
```

## Biome-uri disponibile

| Biome | Height scale | Props |
|-------|-------------|-------|
| Forest | 1.0 | Copaci, frunziș |
| Desert | 0.7 | Dune, nisip |
| Tundra | 0.8 | Roci cu zăpadă |
| Swamp | 0.4 | Copaci de mlaștină |
| Volcanic | 1.4 | Roci de lavă |
| Ocean | 0.2 | Apă adâncă |

---

## Ce generează `build_world.py`

- **Terrain chunks** — cuburi cu heightmap procedural (fbm noise, 5 octave)
- **Water tiles** — apă semi-transparentă unde height < water_level
- **Props** — copaci (Forest/Swamp), roci (Volcanic/Tundra)
- **Spawn points** — distribuite random pe hartă
- **WorldConfig.lua** — embed-at în `.rbxlx`, citit de `init.server.lua`
- **Baseplate** — 2048×2048 studs
- **Lighting** — ShadowMap, ClockTime 13:30
- **RemoteEvents/Functions** — `WorldEvents`, `InventoryRemote`
