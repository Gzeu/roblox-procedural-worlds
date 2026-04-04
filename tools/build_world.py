#!/usr/bin/env python3
"""
build_world.py v2.0 -- Generate .rbxlx from world_config.json
Usage: python build_world.py world_config.json [output.rbxlx]

New in v2.0:
  - Desert: cactus props (trunk + ball top + optional arms)
  - Swamp: gnarled trees with moss canopy + hanging moss
  - Mountain detection: white snow cap above 70% max height
  - Beach: sand strip at waterLevel +/- 3
  - Volcanic: lava pool props via Neon material
  - Ocean: underwater rock formations
  - Improved prop density variance per biome
  - Generation stats table printed on build
"""

import json
import sys
import math
import random
from pathlib import Path
from datetime import datetime

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

BIOME_COLORS = {
    "Forest":   {"r": 106, "g": 127, "b": 63},
    "Desert":   {"r": 196, "g": 165, "b": 90},
    "Tundra":   {"r": 139, "g": 184, "b": 212},
    "Swamp":    {"r": 61,  "g": 82,  "b": 46},
    "Volcanic": {"r": 120, "g": 42,  "b": 21},
    "Ocean":    {"r": 10,  "g": 50,  "b": 100},
}
BIOME_WATER_COLOR = {"r": 28,  "g": 86,  "b": 140}
BIOME_LAVA_COLOR  = {"r": 220, "g": 80,  "b": 10}
BIOME_SAND_COLOR  = {"r": 210, "g": 190, "b": 120}
BIOME_SNOW_COLOR  = {"r": 230, "g": 240, "b": 255}

BIOME_HEIGHT_SCALE = {
    "Forest": 1.0, "Desert": 0.7, "Tundra": 0.8,
    "Swamp": 0.4, "Volcanic": 1.4, "Ocean": 0.2,
}

def make_cframe(x, y, z):
    return (
        f'<CoordinateFrame name="CFrame">'
        f'<X>{x:.3f}</X><Y>{y:.3f}</Y><Z>{z:.3f}</Z>'
        f'<R00>1</R00><R01>0</R01><R02>0</R02>'
        f'<R10>0</R10><R11>1</R11><R12>0</R12>'
        f'<R20>0</R20><R21>0</R21><R22>1</R22>'
        f'</CoordinateFrame>'
    )

def make_part(name, x, y, z, sx, sy, sz, r, g, b, transp=0, shape="Block", material="SmoothPlastic"):
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
        f'<string name="Material">{material}</string>'
        f'</Properties></Item>'
    )

def make_tree(prefix, tx, base_y, tz, rng):
    th = rng.uniform(8, 16)
    cr = rng.uniform(4, 8)
    return [
        make_part(f"{prefix}_trunk", tx, base_y + th/2, tz, 2, th, 2, 101, 79, 37),
        make_part(f"{prefix}_can",   tx, base_y + th + cr*0.6, tz, cr*2, cr*1.2, cr*2, 62, 142, 65, shape="Ball"),
    ]

def make_swamp_tree(prefix, tx, base_y, tz, rng):
    th = rng.uniform(5, 12)
    return [
        make_part(f"{prefix}_st",   tx, base_y + th/2, tz, 2.5, th, 2.5, 55, 35, 18),
        make_part(f"{prefix}_br",   tx + rng.uniform(2,4), base_y + th*0.6, tz + rng.uniform(-2,2), 1.5, th*0.5, 1.5, 50, 30, 15),
        make_part(f"{prefix}_can",  tx, base_y + th + 2.5, tz, 9, 4, 9, 38, 72, 32, shape="Ball"),
        make_part(f"{prefix}_moss", tx + rng.uniform(-2,2), base_y + th - 1, tz + rng.uniform(-2,2), 1, rng.uniform(3,6), 1, 30, 60, 25, transp=0.25),
    ]

def make_cactus(prefix, tx, base_y, tz, rng):
    th = rng.uniform(6, 14)
    parts = [
        make_part(f"{prefix}_body", tx, base_y + th/2,     tz, 3, th, 3, 62, 120, 55),
        make_part(f"{prefix}_top",  tx, base_y + th + 1.5, tz, 3, 3, 3, 55, 110, 48, shape="Ball"),
    ]
    if rng.random() > 0.4:
        arm_h   = rng.uniform(th*0.4, th*0.7)
        arm_len = rng.uniform(3, 5)
        side    = 1 if rng.random() > 0.5 else -1
        parts += [
            make_part(f"{prefix}_armH", tx + side*arm_len/2, base_y + arm_h,     tz, arm_len, 2, 2, 62, 120, 55),
            make_part(f"{prefix}_armV", tx + side*arm_len,   base_y + arm_h + 2, tz, 2, 4, 2, 62, 120, 55),
        ]
    return parts

def make_volcanic_rock(prefix, rx, base_y, rz, rng):
    rs = rng.uniform(4, 10)
    lc = BIOME_LAVA_COLOR
    parts = [make_part(f"{prefix}_r", rx, base_y + rs/2, rz, rs, rs*0.7, rs, 60, 30, 20, shape="Ball")]
    if rng.random() > 0.55:
        parts.append(make_part(
            f"{prefix}_lava",
            rx + rng.uniform(-3,3), base_y + 0.5, rz + rng.uniform(-3,3),
            rng.uniform(4,8), 1, rng.uniform(4,8),
            lc["r"], lc["g"], lc["b"], transp=0.1, material="Neon"
        ))
    return parts

def make_tundra_boulder(prefix, rx, base_y, rz, rng):
    rs = rng.uniform(3, 7)
    return [
        make_part(f"{prefix}_b",  rx, base_y + rs/2,        rz, rs,     rs,     rs,     105, 120, 130, shape="Ball"),
        make_part(f"{prefix}_sn", rx, base_y + rs + rs*0.3, rz, rs*0.7, rs*0.3, rs*0.7, 225, 235, 250),
    ]

def make_ocean_rock(prefix, rx, base_y, rz, rng):
    rs = rng.uniform(3, 8)
    return [make_part(f"{prefix}_f", rx, base_y + rs/2, rz, rs, rs*1.5, rs, 30, 50, 80, shape="Ball")]

def generate_terrain(cfg, rng):
    cs     = cfg["chunkSize"]
    rd     = cfg["renderDistance"]
    mh     = cfg["maxHeight"]
    wl     = cfg["waterLevel"]
    ns     = cfg["noiseScale"]
    seed   = cfg["seed"]
    biomes = cfg["biomes"] or ["Forest"]
    parts  = []

    snow_threshold = mh * 0.70
    beach_lo, beach_hi = wl - 2, wl + 3
    stats = {b: 0 for b in biomes}
    stats.update({"water": 0, "beach": 0, "snow": 0})

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
            is_beach = (not is_water) and (beach_lo <= h <= beach_hi)
            is_snow  = (not is_water) and (h >= snow_threshold)

            if is_snow:
                sc = BIOME_SNOW_COLOR
            elif is_beach:
                sc = BIOME_SAND_COLOR
            else:
                sc = bc

            if is_water:
                stats["water"] += 1
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
                stats[biome] = stats.get(biome, 0) + 1
                if is_beach: stats["beach"] += 1
                if is_snow:  stats["snow"]  += 1
                parts.append(make_part(
                    f"C_{cx}_{cz}", wx, h/2, wz, cs, max(4, h), cs,
                    sc["r"], sc["g"], sc["b"]
                ))

            if not is_water:
                prefix = f"{biome}_{cx}_{cz}"
                if biome == "Forest" and not is_snow:
                    for t in range(rng.randint(2, 5)):
                        tx = wx + rng.uniform(-cs*0.4, cs*0.4)
                        tz = wz + rng.uniform(-cs*0.4, cs*0.4)
                        parts += make_tree(f"{prefix}_t{t}", tx, h, tz, rng)
                elif biome == "Swamp":
                    for t in range(rng.randint(1, 4)):
                        tx = wx + rng.uniform(-cs*0.4, cs*0.4)
                        tz = wz + rng.uniform(-cs*0.4, cs*0.4)
                        parts += make_swamp_tree(f"{prefix}_sw{t}", tx, h, tz, rng)
                elif biome == "Desert" and not is_beach:
                    for t in range(rng.randint(1, 3)):
                        tx = wx + rng.uniform(-cs*0.4, cs*0.4)
                        tz = wz + rng.uniform(-cs*0.4, cs*0.4)
                        parts += make_cactus(f"{prefix}_ca{t}", tx, h, tz, rng)
                elif biome == "Volcanic":
                    for r_i in range(rng.randint(1, 3)):
                        rx = wx + rng.uniform(-cs*0.3, cs*0.3)
                        rz = wz + rng.uniform(-cs*0.3, cs*0.3)
                        parts += make_volcanic_rock(f"{prefix}_vr{r_i}", rx, h, rz, rng)
                elif biome == "Tundra":
                    for r_i in range(rng.randint(1, 2)):
                        rx = wx + rng.uniform(-cs*0.3, cs*0.3)
                        rz = wz + rng.uniform(-cs*0.3, cs*0.3)
                        parts += make_tundra_boulder(f"{prefix}_tb{r_i}", rx, h, rz, rng)
                elif biome == "Ocean":
                    if rng.random() > 0.65:
                        rx = wx + rng.uniform(-cs*0.2, cs*0.2)
                        rz = wz + rng.uniform(-cs*0.2, cs*0.2)
                        parts += make_ocean_rock(f"{prefix}_or", rx, h, rz, rng)

    total = sum(v for k, v in stats.items())
    print("\n  Generation Stats:")
    for k, v in sorted(stats.items(), key=lambda x: -x[1]):
        bar = "\u2588" * max(0, int(v / max(total, 1) * 30))
        print(f"    {k:<12} {v:>4}  {bar}")
    print(f"    {'TOTAL':<12} {total:>4}  (parts: {len(parts)})\n")
    return parts

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

def make_world_config_lua(cfg):
    biomes_lua = "{" + ", ".join(f'"{b}"' for b in (cfg["biomes"] or ["Forest"])) + "}"
    ns = cfg["noiseScale"]
    return f"""-- WorldConfig.lua (auto-generated {datetime.now().strftime("%Y-%m-%d %H:%M")})
return {{
    WORLD_NAME      = "{xml_escape(cfg["worldName"])}",
    SEED            = {cfg["seed"]},
    CHUNK_SIZE      = {cfg["chunkSize"]},
    RENDER_DISTANCE = {cfg["renderDistance"]},
    MAX_HEIGHT      = {cfg["maxHeight"]},
    WATER_LEVEL     = {cfg["waterLevel"]},
    NOISE_SCALE     = {ns},
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
"""

INIT_SRC = """-- init.server.lua (auto-generated)
local SSS = game:GetService(\"ServerScriptService\")
local cfg = require(SSS:WaitForChild(\"WorldConfig\"))
print(\"[World] Init -- Seed:\", cfg.SEED)
print(\"[World] Biomes:\", table.concat(cfg.BIOMES, \", \"))
"""

def build_rbxlx(cfg):
    rng    = random.Random(cfg["seed"])
    parts  = generate_terrain(cfg, rng)
    spawns = generate_spawns(cfg, rng)
    terrain_xml = "\n    ".join(parts)
    spawn_xml   = "\n    ".join(spawns)
    wc_src      = make_world_config_lua(cfg)
    return f"""<?xml version="1.0" encoding="utf-8"?>
<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd"
        version="4">
<!-- build_world.py v2.0 | {xml_escape(cfg["worldName"])} | seed:{cfg["seed"]} | {datetime.now().strftime("%Y-%m-%d %H:%M")} -->
<Item class="Workspace">
  <Properties>
    <string name="Name">Workspace</string>
    <bool name="StreamingEnabled">true</bool>
    <float name="Gravity">196.2</float>
  </Properties>
  <Item class="Model"><Properties><string name="Name">Terrain_Chunks</string></Properties>
    {terrain_xml}
  </Item>
  <Item class="Model"><Properties><string name="Name">SpawnPoints</string></Properties>
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
</roblox>"""

def main():
    if len(sys.argv) < 2:
        print("Usage: python build_world.py world_config.json [output.rbxlx]")
        sys.exit(1)
    config_path = Path(sys.argv[1])
    if not config_path.exists():
        print(f"Error: {config_path} not found")
        sys.exit(1)
    with open(config_path, "r", encoding="utf-8") as f:
        cfg = json.load(f)
    out_name = sys.argv[2] if len(sys.argv) >= 3 else cfg.get("worldName","MyWorld").replace(" ","_")+".rbxlx"
    out_path = Path(out_name)
    print(f"\n[build_world v2.0] '{cfg.get('worldName')}' | seed {cfg.get('seed')}")
    xml = build_rbxlx(cfg)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(xml)
    size_kb = out_path.stat().st_size / 1024
    print(f"[build_world v2.0] Done -> {out_path} ({size_kb:.1f} KB)")

if __name__ == "__main__":
    main()
