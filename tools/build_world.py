#!/usr/bin/env python3
"""
build_world.py — Generează un fișier .rbxlx din world_config.json
Utilizare: python build_world.py world_config.json [output.rbxlx]
"""

import json
import sys
import math
import random
from pathlib import Path
from datetime import datetime

# ─────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────

def xml_escape(s):
    return str(s).replace('&','&amp;').replace('<','&lt;').replace('>','&gt;').replace('"','&quot;')

def noise(x, y, seed=0):
    n = math.sin(x * 127.1 + y * 311.7 + seed) * 43758.5453
    return n - math.floor(n)

def smooth_noise(x, y, seed=0):
    ix, iy = int(math.floor(x)), int(math.floor(y))
    fx, fy = x - ix, y - iy
    ux = fx * fx * (3 - 2 * fx)
    uy = fy * fy * (3 - 2 * fy)
    a = noise(ix,     iy,     seed)
    b = noise(ix + 1, iy,     seed)
    c = noise(ix,     iy + 1, seed)
    d = noise(ix + 1, iy + 1, seed)
    return a*(1-ux)*(1-uy) + b*ux*(1-uy) + c*(1-ux)*uy + d*ux*uy

def fbm(x, y, seed=0, octaves=5):
    v, amp, freq, mx = 0, 0.5, 1, 0
    for _ in range(octaves):
        v  += smooth_noise(x * freq, y * freq, seed) * amp
        mx += amp
        amp  *= 0.5
        freq *= 2.0
    return v / mx

# ─────────────────────────────────────────────
# BIOME DEFINITIONS
# ─────────────────────────────────────────────

BIOME_COLORS = {
    "Forest":   {"r": 106, "g": 127, "b": 63},
    "Desert":   {"r": 196, "g": 165, "b": 90},
    "Tundra":   {"r": 139, "g": 184, "b": 212},
    "Swamp":    {"r": 61,  "g": 82,  "b": 46},
    "Volcanic": {"r": 120, "g": 42,  "b": 21},
    "Ocean":    {"r": 10,  "g": 50,  "b": 100},
}

BIOME_WATER_COLOR = {"r": 28, "g": 86, "b": 140}

BIOME_HEIGHT_SCALE = {
    "Forest": 1.0, "Desert": 0.7, "Tundra": 0.8,
    "Swamp": 0.4, "Volcanic": 1.4, "Ocean": 0.2,
}

# ─────────────────────────────────────────────
# XML PART BUILDER
# ─────────────────────────────────────────────

def make_cframe(x, y, z):
    return (
        f'<CoordinateFrame name="CFrame">'
        f'<X>{x:.3f}</X><Y>{y:.3f}</Y><Z>{z:.3f}</Z>'
        f'<R00>1</R00><R01>0</R01><R02>0</R02>'
        f'<R10>0</R10><R11>1</R11><R12>0</R12>'
        f'<R20>0</R20><R21>0</R21><R22>1</R22>'
        f'</CoordinateFrame>'
    )

def make_part(name, x, y, z, sx, sy, sz, r, g, b, transp=0, shape="Block"):
    rf, gf, bf = r/255, g/255, b/255
    return (
        f'<Item class="Part"><Properties>'
        f'<string name="Name">{xml_escape(name)}</string>'
        f'<bool name="Anchored">true</bool>'
        f'<bool name="CanCollide">true</bool>'
        f'<float name="Transparency">{transp}</float>'
        f'{make_cframe(x, y, z)}'
        f'<Vector3 name="Size"><X>{sx:.2f}</X><Y>{sy:.2f}</Y><Z>{sz:.2f}</Z></Vector3>'
        f'<Color3 name="Color"><R>{rf:.4f}</R><G>{gf:.4f}</G><B>{bf:.4f}</B></Color3>'
        f'<string name="Shape">{shape}</string>'
        f'<string name="Material">SmoothPlastic</string>'
        f'</Properties></Item>'
    )

# ─────────────────────────────────────────────
# TERRAIN GENERATOR
# ─────────────────────────────────────────────

def generate_terrain(cfg, rng):
    cs    = cfg["chunkSize"]
    rd    = cfg["renderDistance"]
    mh    = cfg["maxHeight"]
    wl    = cfg["waterLevel"]
    ns    = cfg["noiseScale"]
    seed  = cfg["seed"]
    biomes = cfg["biomes"] or ["Forest"]
    parts = []

    for cx in range(-rd, rd + 1):
        for cz in range(-rd, rd + 1):
            wx = (cx + 0.5) * cs
            wz = (cz + 0.5) * cs

            biome_n   = fbm(wx * ns * 0.5, wz * ns * 0.5, seed + 100)
            biome_idx = int(biome_n * len(biomes)) % len(biomes)
            biome     = biomes[biome_idx]
            bc        = BIOME_COLORS.get(biome, BIOME_COLORS["Forest"])
            hs        = BIOME_HEIGHT_SCALE.get(biome, 1.0)

            h_norm = max(0, min(1, fbm(wx * ns, wz * ns, seed))) * hs
            h      = max(4, h_norm * mh)
            is_water = h < wl

            if is_water:
                parts.append(make_part(
                    f"G_{cx}_{cz}", wx, h/2, wz, cs, max(2, h), cs,
                    bc["r"]//2, bc["g"]//2, bc["b"]//2
                ))
                parts.append(make_part(
                    f"W_{cx}_{cz}", wx, wl, wz, cs, 2, cs,
                    BIOME_WATER_COLOR["r"], BIOME_WATER_COLOR["g"], BIOME_WATER_COLOR["b"],
                    transp=0.45
                ))
            else:
                parts.append(make_part(
                    f"C_{cx}_{cz}", wx, h/2, wz, cs, max(4, h), cs,
                    bc["r"], bc["g"], bc["b"]
                ))

            # Props
            if biome == "Forest" and not is_water:
                for t in range(rng.randint(2, 5)):
                    tx = wx + rng.uniform(-cs*0.4, cs*0.4)
                    tz = wz + rng.uniform(-cs*0.4, cs*0.4)
                    th = rng.uniform(8, 16)
                    parts.append(make_part(f"Tr_{cx}_{cz}_{t}", tx, h+th/2, tz, 2, th, 2, 101, 79, 37))
                    parts.append(make_part(f"Lv_{cx}_{cz}_{t}", tx, h+th+3, tz, 8, 6, 8, 62, 142, 65, shape="Ball"))

            if biome == "Swamp" and not is_water:
                for t in range(rng.randint(1, 3)):
                    tx = wx + rng.uniform(-cs*0.4, cs*0.4)
                    tz = wz + rng.uniform(-cs*0.4, cs*0.4)
                    th = rng.uniform(5, 12)
                    parts.append(make_part(f"SwTr_{cx}_{cz}_{t}", tx, h+th/2, tz, 2, th, 2, 60, 40, 20))
                    parts.append(make_part(f"SwLv_{cx}_{cz}_{t}", tx, h+th+2, tz, 6, 4, 6, 40, 80, 30, shape="Ball"))

            if biome == "Volcanic" and not is_water:
                for ri in range(rng.randint(1, 3)):
                    rx = wx + rng.uniform(-cs*0.3, cs*0.3)
                    rz = wz + rng.uniform(-cs*0.3, cs*0.3)
                    rs = rng.uniform(4, 10)
                    parts.append(make_part(f"Rk_{cx}_{cz}_{ri}", rx, h+rs/2, rz, rs, rs*0.7, rs, 60, 30, 20, shape="Ball"))

            if biome == "Tundra" and not is_water:
                for ri in range(rng.randint(1, 2)):
                    rx = wx + rng.uniform(-cs*0.3, cs*0.3)
                    rz = wz + rng.uniform(-cs*0.3, cs*0.3)
                    rs = rng.uniform(3, 7)
                    parts.append(make_part(f"Sn_{cx}_{cz}_{ri}", rx, h+rs/2, rz, rs, rs, rs, 220, 235, 245, shape="Ball"))

    return parts

# ─────────────────────────────────────────────
# SPAWN GENERATOR
# ─────────────────────────────────────────────

def generate_spawns(cfg, rng):
    biomes  = cfg["biomes"] or ["Forest"]
    density = cfg["mobs"]["density"]
    rd      = cfg["renderDistance"]
    cs      = cfg["chunkSize"]
    spawns  = []
    count   = max(1, density * (2*rd + 1))
    for i in range(count):
        bx = rng.uniform(-rd*cs, rd*cs)
        bz = rng.uniform(-rd*cs, rd*cs)
        spawns.append(make_part(f"SP_{i}", bx, 2, bz, 4, 1, 4, 255, 80, 80))
    return spawns

# ─────────────────────────────────────────────
# SCRIPT SOURCES
# ─────────────────────────────────────────────

def make_world_config_lua(cfg):
    biomes_lua = "{" + ", ".join(f'"{b}"' for b in (cfg["biomes"] or ["Forest"])) + "}"
    return f'''-- WorldConfig.lua (auto-generated {datetime.now().strftime("%Y-%m-%d %H:%M")})
return {{
    WORLD_NAME      = "{xml_escape(cfg["worldName"])}",
    SEED            = {cfg["seed"]},
    CHUNK_SIZE      = {cfg["chunkSize"]},
    RENDER_DISTANCE = {cfg["renderDistance"]},
    MAX_HEIGHT      = {cfg["maxHeight"]},
    WATER_LEVEL     = {cfg["waterLevel"]},
    NOISE_SCALE     = {cfg["noiseScale"]:.4f},
    BIOMES          = {biomes_lua},
    MOBS = {{
        DENSITY    = {cfg["mobs"]["density"]},
        DIFFICULTY = "{cfg["mobs"]["difficulty"]}",
        BOSSES     = {"true" if cfg["mobs"]["bosses"] else "false"},
        GROUP_AI   = {"true" if cfg["mobs"]["groupAI"] else "false"},
    }},
    STRUCTURES = {{
        VILLAGES   = {"true" if cfg["structures"]["villages"] else "false"},
        DUNGEONS   = {"true" if cfg["structures"]["dungeons"] else "false"},
        RIVERS     = {"true" if cfg["structures"]["rivers"] else "false"},
        ORES       = {"true" if cfg["structures"]["ores"] else "false"},
    }},
    SYSTEMS = {{
        DAY_NIGHT_CYCLE    = {"true" if cfg["systems"]["dayNightCycle"] else "false"},
        WEATHER            = {"true" if cfg["systems"]["weather"] else "false"},
        BASE_BUILDING      = {"true" if cfg["systems"]["baseBuilding"] else "false"},
        CLANS              = {"true" if cfg["systems"]["clans"] else "false"},
        DAY_LENGTH_MINUTES = {cfg["systems"]["dayLengthMinutes"]},
    }},
}}
'''

INIT_SRC = """-- init.server.lua (auto-generated)
local SSS = game:GetService(\"ServerScriptService\")
local cfg = require(SSS:WaitForChild(\"WorldConfig\"))
print(\"[World] Init — Seed:\", cfg.SEED)
print(\"[World] Biomes:\", table.concat(cfg.BIOMES, \", \"))
print(\"[World] Render Distance:\", cfg.RENDER_DISTANCE, \"chunks\")
print(\"[World] Max Height:\", cfg.MAX_HEIGHT)
"""

# ─────────────────────────────────────────────
# ASSEMBLE .rbxlx
# ─────────────────────────────────────────────

def build_rbxlx(cfg):
    rng    = random.Random(cfg["seed"])
    parts  = generate_terrain(cfg, rng)
    spawns = generate_spawns(cfg, rng)

    terrain_xml = "\n    ".join(parts)
    spawn_xml   = "\n    ".join(spawns)
    wc_src      = make_world_config_lua(cfg)

    return f'''<?xml version="1.0" encoding="utf-8"?>
<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd"
        version="4">

<!-- Generated by build_world.py | {xml_escape(cfg["worldName"])} | seed:{cfg["seed"]} | {datetime.now().strftime("%Y-%m-%d %H:%M")} -->

<Item class="Workspace">
  <Properties>
    <string name="Name">Workspace</string>
    <bool name="StreamingEnabled">true</bool>
    <float name="Gravity">196.2</float>
  </Properties>
  <Item class="Model">
    <Properties><string name="Name">Terrain_Chunks</string></Properties>
    {terrain_xml}
  </Item>
  <Item class="Model">
    <Properties><string name="Name">SpawnPoints</string></Properties>
    {spawn_xml}
  </Item>
  <Item class="Part"><Properties>
    <string name="Name">Baseplate</string>
    <bool name="Anchored">true</bool>
    <bool name="Locked">true</bool>
    {make_cframe(0, -10, 0)}
    <Vector3 name="Size"><X>2048</X><Y>20</Y><Z>2048</Z></Vector3>
    <Color3 name="Color"><R>0.388</R><G>0.372</G><B>0.384</B></Color3>
  </Properties></Item>
</Item>

<Item class="Lighting">
  <Properties>
    <string name="Name">Lighting</string>
    <float name="Brightness">2.2</float>
    <float name="ClockTime">13.5</float>
    <bool name="GlobalShadows">true</bool>
    <string name="Technology">ShadowMap</string>
    <Color3 name="Ambient"><R>0.45</R><G>0.45</G><B>0.5</B></Color3>
    <Color3 name="OutdoorAmbient"><R>0.65</R><G>0.68</G><B>0.72</B></Color3>
  </Properties>
</Item>

<Item class="ServerScriptService">
  <Properties><string name="Name">ServerScriptService</string></Properties>
  <Item class="ModuleScript"><Properties>
    <string name="Name">WorldConfig</string>
    <ProtectedString name="Source">{xml_escape(wc_src)}</ProtectedString>
  </Properties></Item>
  <Item class="Script"><Properties>
    <string name="Name">init.server</string>
    <ProtectedString name="Source">{xml_escape(INIT_SRC)}</ProtectedString>
  </Properties></Item>
</Item>

<Item class="ReplicatedStorage">
  <Properties><string name="Name">ReplicatedStorage</string></Properties>
  <Item class="RemoteEvent"><Properties><string name="Name">WorldEvents</string></Properties></Item>
  <Item class="RemoteFunction"><Properties><string name="Name">InventoryRemote</string></Properties></Item>
</Item>

<Item class="StarterPlayer">
  <Properties><string name="Name">StarterPlayer</string></Properties>
  <Item class="StarterPlayerScripts">
    <Properties><string name="Name">StarterPlayerScripts</string></Properties>
    <Item class="LocalScript"><Properties>
      <string name="Name">HUD_Bootstrap</string>
      <ProtectedString name="Source">print(\"[Client] Ready:\", game.Players.LocalPlayer.Name)</ProtectedString>
    </Properties></Item>
  </Item>
</Item>

</roblox>'''

# ─────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────

def main():
    if len(sys.argv) < 2:
        print("Usage: python build_world.py world_config.json [output.rbxlx]")
        sys.exit(1)

    config_path = Path(sys.argv[1])
    if not config_path.exists():
        print(f"Error: config file not found: {config_path}")
        sys.exit(1)

    with open(config_path, "r", encoding="utf-8") as f:
        cfg = json.load(f)

    out_name = sys.argv[2] if len(sys.argv) >= 3 else cfg.get("worldName", "MyWorld").replace(" ", "_") + ".rbxlx"
    out_path = Path(out_name)

    print(f"[build_world] Building '{cfg.get('worldName')}' — seed {cfg.get('seed')} ...")
    xml = build_rbxlx(cfg)

    with open(out_path, "w", encoding="utf-8") as f:
        f.write(xml)

    size_kb = out_path.stat().st_size / 1024
    print(f"[build_world] Done → {out_path} ({size_kb:.1f} KB)")
    print(f"              Open in Roblox Studio: File → Open from File → {out_path}")

if __name__ == "__main__":
    main()
