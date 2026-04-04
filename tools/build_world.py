#!/usr/bin/env python3
"""
build_world.py  v3.0
Generates a Roblox .rbxlx world from world_config.json
New in v3.0: river carving, dungeon rooms, multi-layer underground,
             large structures (towers/ruins), --watch flag, --format rojo
"""

import json, math, random, argparse, os, sys, time, shutil, hashlib
from xml.etree import ElementTree as ET
from xml.dom import minidom

# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
parser = argparse.ArgumentParser(description="Procedural World Builder v3.0")
parser.add_argument("config", nargs="?", default="world_config.json")
parser.add_argument("--output", "-o", default="output/world.rbxlx")
parser.add_argument("--watch", action="store_true", help="Rebuild on config save")
parser.add_argument("--format", choices=["rbxlx", "rojo"], default="rbxlx")
args = parser.parse_args()

# ---------------------------------------------------------------------------
# Noise helpers
# ---------------------------------------------------------------------------
def fade(t): return t * t * t * (t * (t * 6 - 15) + 10)
def lerp(a, b, t): return a + t * (b - a)

_perm = list(range(256))
random.shuffle(_perm)
_perm += _perm

def grad(h, x, y):
    h &= 3
    if h == 0: return  x + y
    if h == 1: return -x + y
    if h == 2: return  x - y
    return -x - y

def perlin(x, y):
    xi, yi = int(math.floor(x)) & 255, int(math.floor(y)) & 255
    xf, yf = x - math.floor(x), y - math.floor(y)
    u, v   = fade(xf), fade(yf)
    aa = _perm[_perm[xi]   + yi]
    ab = _perm[_perm[xi]   + yi+1]
    ba = _perm[_perm[xi+1] + yi]
    bb = _perm[_perm[xi+1] + yi+1]
    return lerp(lerp(grad(aa,xf,yf),   grad(ba,xf-1,yf),   u),
                lerp(grad(ab,xf,yf-1), grad(bb,xf-1,yf-1), u), v)

def fbm(x, y, octaves=6, lacunarity=2.0, gain=0.5):
    val, amp, freq = 0.0, 0.5, 1.0
    for _ in range(octaves):
        val  += amp * perlin(x * freq, y * freq)
        amp  *= gain
        freq *= lacunarity
    return val

# ---------------------------------------------------------------------------
# Load config
# ---------------------------------------------------------------------------
def load_config(path):
    with open(path) as f:
        return json.load(f)

# ---------------------------------------------------------------------------
# Heightmap generation
# ---------------------------------------------------------------------------
def generate_heightmap(cfg, rng):
    W  = cfg.get("worldSize", 256)
    mH = cfg.get("maxHeight", 120)
    sc = cfg.get("noiseScale", 0.008)
    ox = rng.uniform(0, 1000)
    oy = rng.uniform(0, 1000)
    hmap = [[0.0]*W for _ in range(W)]
    for z in range(W):
        for x in range(W):
            n = fbm((x + ox)*sc, (z + oy)*sc)
            hmap[z][x] = max(0.0, min(1.0, (n + 1.0) / 2.0)) * mH
    return hmap

# ---------------------------------------------------------------------------
# Biome assignment
# ---------------------------------------------------------------------------
def get_biome(h, cfg):
    mH  = cfg.get("maxHeight", 120)
    wL  = cfg.get("waterLevel", 20)
    frac = h / mH
    if h <= wL:          return "Ocean"
    if frac < 0.15:      return "Beach"
    biomes = cfg.get("biomes", ["Forest"])
    if "Volcanic" in biomes and frac > 0.85: return "Volcanic"
    if "Tundra"   in biomes and frac > 0.75: return "Tundra"
    if "Swamp"    in biomes and frac < 0.25: return "Swamp"
    if "Desert"   in biomes and frac < 0.35: return "Desert"
    return biomes[0] if biomes else "Forest"

# ---------------------------------------------------------------------------
# RIVER CARVING  (hydraulic erosion — simplified steepest-descent)
# ---------------------------------------------------------------------------
def carve_rivers(hmap, cfg, rng):
    W        = len(hmap)
    wL       = cfg.get("waterLevel", 20)
    n_rivers = cfg.get("rivers", 4)
    depth    = cfg.get("riverDepth", 6)
    width    = cfg.get("riverWidth", 3)

    for _ in range(n_rivers):
        # Start near peaks
        sx = rng.randint(W//4, 3*W//4)
        sz = rng.randint(W//4, 3*W//4)
        # Walk downhill
        for _step in range(W * 2):
            # Carve current cell + neighbours within width
            for dz in range(-width, width+1):
                for dx in range(-width, width+1):
                    nx_, nz_ = sx+dx, sz+dz
                    if 0 <= nx_ < W and 0 <= nz_ < W:
                        hmap[nz_][nx_] = max(hmap[nz_][nx_] - depth * max(0, 1 - (abs(dx)+abs(dz))/(width+1)), wL - 1)
            # Move to lowest neighbour
            best_h = hmap[sz][sx]
            best_pos = None
            for dz2, dx2 in [(-1,0),(1,0),(0,-1),(0,1)]:
                nz2, nx2 = sz+dz2, sx+dx2
                if 0 <= nx2 < W and 0 <= nz2 < W and hmap[nz2][nx2] < best_h:
                    best_h, best_pos = hmap[nz2][nx2], (nx2, nz2)
            if best_pos is None:
                break
            sx, sz = best_pos
            if hmap[sz][sx] <= wL:
                break
    return hmap

# ---------------------------------------------------------------------------
# RBXLX helpers
# ---------------------------------------------------------------------------
NEXT_ID = [1]
def new_id():
    i = NEXT_ID[0]; NEXT_ID[0] += 1; return i

def make_part(parent, name, cx, cy, cz, sx, sy, sz,
              color="163 162 165", material="SmoothPlastic",
              anchored=True, can_collide=True, transparency=0):
    part = ET.SubElement(parent, "Part", ClassName="Part", referent=f"RBX{new_id()}")
    def prop(tag, typ, pname, val):
        p = ET.SubElement(part, "Properties")
        e = ET.SubElement(p, typ, name=pname)
        e.text = str(val)
        return e
    # Flattened properties block
    props = ET.SubElement(part, "Properties")
    def pp(typ, pname, val):
        e = ET.SubElement(props, typ, name=pname)
        e.text = str(val)
    pp("string",  "Name",         name)
    pp("token",   "Shape",        "0")
    pp("bool",    "Anchored",     str(anchored).lower())
    pp("bool",    "CanCollide",   str(can_collide).lower())
    pp("float",   "Transparency", str(transparency))
    pp("token",   "Material",     material)
    size_e = ET.SubElement(props, "Vector3", name="Size")
    size_e.text = f"{sx} {sy} {sz}"
    cf = ET.SubElement(props, "CoordinateFrame", name="CFrame")
    ET.SubElement(cf, "X").text = str(cx)
    ET.SubElement(cf, "Y").text = str(cy)
    ET.SubElement(cf, "Z").text = str(cz)
    for tag in ["R00","R01","R02","R10","R11","R12","R20","R21","R22"]:
        ET.SubElement(cf, tag).text = "1" if tag in ("R00","R11","R22") else "0"
    bc = ET.SubElement(props, "Color3uint8", name="BrickColor")
    bc.text = color
    return part

def make_model(parent, name):
    m = ET.SubElement(parent, "Model", ClassName="Model", referent=f"RBX{new_id()}")
    props = ET.SubElement(m, "Properties")
    n = ET.SubElement(props, "string", name="Name")
    n.text = name
    return m

# ---------------------------------------------------------------------------
# TERRAIN PARTS  (column-based with underground layers)
# ---------------------------------------------------------------------------
BIOME_COLORS = {
    "Ocean":    "23 113 184",
    "Beach":    "215 197 154",
    "Forest":   "106 127 63",
    "Swamp":    "75 100 55",
    "Desert":   "218 205 158",
    "Volcanic": "105 64 40",
    "Tundra":   "195 205 215",
}

def emit_terrain(ws, hmap, cfg, rng):
    W  = len(hmap)
    mH = cfg.get("maxHeight", 120)
    wL = cfg.get("waterLevel", 20)
    CELL = 4  # studs per cell
    terrain_model = make_model(ws, "Terrain")

    for z in range(0, W, 2):   # stride 2 to keep part count sane
        for x in range(0, W, 2):
            h  = hmap[z][x]
            ih = max(1, int(h))
            bm = get_biome(h, cfg)
            col = BIOME_COLORS.get(bm, "163 162 165")
            cx_ = (x - W/2) * CELL
            cz_ = (z - W/2) * CELL

            # === Multi-layer underground ===
            # Bedrock  y < 10
            make_part(terrain_model, "Bedrock", cx_, 5, cz_, CELL*2, 10, CELL*2,
                      color="105 102 100", material="Slate")
            # Stone  10 < y < 60
            stone_top = min(60, ih - 3)
            if stone_top > 10:
                make_part(terrain_model, "Stone", cx_, (10+stone_top)//2, cz_,
                          CELL*2, stone_top-10, CELL*2,
                          color="130 130 130", material="SmoothPlastic")
            # Dirt  60 < y < surface-3
            dirt_top = max(60, ih - 3)
            if dirt_top > 60:
                make_part(terrain_model, "Dirt", cx_, (60+dirt_top)//2, cz_,
                          CELL*2, dirt_top-60, CELL*2,
                          color="132 94 56", material="Grass")
            # Surface cap
            make_part(terrain_model, bm, cx_, ih, cz_, CELL*2, 2, CELL*2,
                      color=col, material="Grass")
            # Snow cap above 70% maxHeight
            if h > mH * 0.70 and bm != "Ocean":
                make_part(terrain_model, "SnowCap", cx_, ih+1, cz_, CELL*2, 1, CELL*2,
                          color="248 248 248", material="SmoothPlastic")
            # Water fill
            if h < wL:
                make_part(terrain_model, "Water", cx_, wL//2, cz_, CELL*2, wL, CELL*2,
                          color="23 113 184", material="SmoothPlastic", transparency=0.5)
    return terrain_model

# ---------------------------------------------------------------------------
# BIOME PROPS
# ---------------------------------------------------------------------------
def emit_props(ws, hmap, cfg, rng):
    W  = len(hmap)
    wL = cfg.get("waterLevel", 20)
    CELL = 4
    props_model = make_model(ws, "Props")

    PROP_DEFS = {
        "Desert":   [("Cactus",   4, 8,  4, "106 127 63")],
        "Swamp":    [("SwampTree",3, 14, 3, "75 100 55"), ("Moss", 4, 1, 4, "90 110 50")],
        "Volcanic": [("Boulder",  5, 5,  5, "105 64 40"), ("LavaPit", 5, 1, 5, "255 100 0")],
        "Tundra":   [("IceBoulder",4,3, 4, "195 205 215"), ("SnowMound",5,2,5,"248 248 248")],
        "Ocean":    [("OceanRock", 3, 6, 3, "130 120 110")],
        "Forest":   [("Tree",      4, 16, 4, "80 109 84")],
    }

    density = cfg.get("propDensity", 0.04)
    for z in range(0, W, 1):
        for x in range(0, W, 1):
            if rng.random() > density: continue
            h  = hmap[z][x]
            bm = get_biome(h, cfg)
            defs = PROP_DEFS.get(bm, [])
            if not defs: continue
            pname, sw, sh, sd, col = rng.choice(defs)
            cx_ = (x - W/2) * CELL + rng.uniform(-1,1)
            cz_ = (z - W/2) * CELL + rng.uniform(-1,1)
            cy_ = max(1, int(h)) + sh//2 + 1
            mat = "Neon" if "Lava" in pname else "SmoothPlastic"
            make_part(props_model, pname, cx_, cy_, cz_, sw, sh, sd, color=col, material=mat)
    return props_model

# ---------------------------------------------------------------------------
# DUNGEON ROOMS
# ---------------------------------------------------------------------------
def emit_dungeons(ws, cfg, rng):
    n_rooms = cfg.get("dungeonRooms", 6)
    W  = cfg.get("worldSize", 256)
    CELL = 4
    dung_model = make_model(ws, "Dungeons")

    rooms = []
    attempts = 0
    while len(rooms) < n_rooms and attempts < 300:
        attempts += 1
        rw = rng.randint(10, 24)
        rl = rng.randint(10, 24)
        rh = rng.randint(6, 10)
        rx = rng.randint(-W//2, W//2) * CELL
        rz = rng.randint(-W//2, W//2) * CELL
        ry = rng.randint(15, 45)  # underground
        rooms.append((rx, ry, rz, rw*CELL, rh, rl*CELL))

    # Emit room walls (hollow box — just 4 walls + floor + ceiling)
    for (rx, ry, rz, rw, rh, rl) in rooms:
        # floor
        make_part(dung_model, "DungFloor", rx, ry,      rz,  rw, 1, rl, color="105 102 100", material="Slate")
        # ceiling
        make_part(dung_model, "DungCeil",  rx, ry+rh,   rz,  rw, 1, rl, color="105 102 100", material="Slate")
        # north/south walls
        make_part(dung_model, "DungWallN", rx, ry+rh//2, rz-rl//2, rw, rh, 1, color="130 130 130")
        make_part(dung_model, "DungWallS", rx, ry+rh//2, rz+rl//2, rw, rh, 1, color="130 130 130")
        # east/west walls
        make_part(dung_model, "DungWallE", rx+rw//2, ry+rh//2, rz, 1, rh, rl, color="130 130 130")
        make_part(dung_model, "DungWallW", rx-rw//2, ry+rh//2, rz, 1, rh, rl, color="130 130 130")

    # Corridors between consecutive rooms
    for i in range(len(rooms)-1):
        ax, ay, az = rooms[i][0],  rooms[i][1]+2,  rooms[i][2]
        bx, by, bz = rooms[i+1][0], rooms[i+1][1]+2, rooms[i+1][2]
        midx, midz = (ax+bx)//2, (az+bz)//2
        # Horizontal corridor
        dx = abs(bx - ax)
        dz_ = abs(bz - az)
        if dx > 0:
            make_part(dung_model, "Corridor", (ax+bx)//2, ay, az, dx, 4, 4, color="105 102 100", material="Slate")
        if dz_ > 0:
            make_part(dung_model, "Corridor", bx, by, (az+bz)//2, 4, 4, dz_, color="105 102 100", material="Slate")
    return dung_model

# ---------------------------------------------------------------------------
# LARGE STRUCTURES: towers & ruins
# ---------------------------------------------------------------------------
def emit_structures(ws, hmap, cfg, rng):
    W  = len(hmap)
    CELL = 4
    n_struct = cfg.get("structures", 5)
    struct_model = make_model(ws, "Structures")

    for _ in range(n_struct):
        x = rng.randint(10, W-10)
        z = rng.randint(10, W-10)
        h = int(hmap[z][x])
        cx_ = (x - W/2) * CELL
        cz_ = (z - W/2) * CELL
        kind = rng.choice(["Tower", "Ruin"])

        if kind == "Tower":
            # Base
            make_part(struct_model, "TowerBase", cx_, h+4,  cz_, 12, 8, 12, color="130 130 130", material="SmoothPlastic")
            # Middle
            make_part(struct_model, "TowerMid",  cx_, h+14, cz_, 10, 12, 10, color="130 130 130", material="SmoothPlastic")
            # Top
            make_part(struct_model, "TowerTop",  cx_, h+24, cz_, 8,  6,  8,  color="163 162 165")
            # Flag
            make_part(struct_model, "TowerFlag", cx_, h+30, cz_, 1,  8,  1,  color="196 40 28")
        else:  # Ruin
            for rp in range(rng.randint(3, 7)):
                offx = rng.randint(-8, 8)
                offz = rng.randint(-8, 8)
                rh2  = rng.randint(2, 10)
                make_part(struct_model, "RuinPillar",
                          cx_+offx, h+rh2//2, cz_+offz,
                          rng.randint(2,4), rh2, rng.randint(2,4),
                          color="163 162 165")
    return struct_model

# ---------------------------------------------------------------------------
# ROJO EXPORT
# ---------------------------------------------------------------------------
def export_rojo(cfg, hmap, rng, out_dir="src"):
    os.makedirs(out_dir, exist_ok=True)
    # Write BiomeBlending stub (real Lua is in src/)
    shutil.copy2("src/BiomeBlending.lua", os.path.join(out_dir, "BiomeBlending.lua")) if os.path.exists("src/BiomeBlending.lua") else None
    # Serialise heightmap as JSON for Rojo plugin import
    with open(os.path.join(out_dir, "heightmap.json"), "w") as f:
        json.dump({"heightmap": [hmap[z] for z in range(0, len(hmap), 4)],
                   "config": cfg}, f, indent=2)
    print(f"[Rojo] Exported to {out_dir}/")

# ---------------------------------------------------------------------------
# STATS
# ---------------------------------------------------------------------------
def print_stats(hmap, cfg):
    W  = len(hmap)
    mH = cfg.get("maxHeight", 120)
    wL = cfg.get("waterLevel", 20)
    total = W * W
    ocean = sum(1 for z in range(W) for x in range(W) if hmap[z][x] <= wL)
    land  = total - ocean
    peak  = max(hmap[z][x] for z in range(W) for x in range(W))
    print("\n┌─────────────────── BUILD STATS v3.0 ───────────────────┐")
    print(f"│  Grid        : {W}×{W} cells")
    print(f"│  Max height  : {peak:.1f} / {mH}")
    print(f"│  Land cells  : {land:,}  ({100*land//total}%)")
    print(f"│  Ocean cells : {ocean:,}  ({100*ocean//total}%)")
    print(f"│  Rivers      : {cfg.get('rivers', 4)}")
    print(f"│  Dungeon rms : {cfg.get('dungeonRooms', 6)}")
    print(f"│  Structures  : {cfg.get('structures', 5)}")
    print("└────────────────────────────────────────────────────────┘\n")

# ---------------------------------------------------------------------------
# BUILD
# ---------------------------------------------------------------------------
def build(config_path, output_path, fmt):
    cfg  = load_config(config_path)
    seed = cfg.get("seed", 42)
    rng  = random.Random(seed)
    # Re-seed permutation table with world seed
    random.seed(seed)
    _perm[:] = list(range(256))
    random.shuffle(_perm)
    _perm[256:] = _perm[:256]
    random.seed(seed)

    NEXT_ID[0] = 1
    print(f"[v3.0] Building world seed={seed} ...")

    hmap = generate_heightmap(cfg, rng)
    hmap = carve_rivers(hmap, cfg, rng)

    # --- RBXLX tree ---
    root = ET.Element("roblox", **{"xmlns:xmime":"http://www.w3.org/2005/05/xmlmime",
                                    "xmlns:xsi":  "http://www.w3.org/2001/XMLSchema-instance",
                                    "xsi:noNamespaceSchemaLocation":"http://www.roblox.com/roblox.xsd",
                                    "version":"4"})
    ws = ET.SubElement(root, "Item", **{"class":"Workspace", "referent":"RBX0"})
    ET.SubElement(ws, "Properties")

    emit_terrain(ws, hmap, cfg, rng)
    emit_props(ws, hmap, cfg, rng)
    emit_dungeons(ws, cfg, rng)
    emit_structures(ws, hmap, cfg, rng)

    if fmt == "rojo":
        export_rojo(cfg, hmap, rng)
    else:
        os.makedirs(os.path.dirname(output_path) or ".", exist_ok=True)
        pretty = minidom.parseString(ET.tostring(root, encoding="unicode")).toprettyxml(indent="  ")
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(pretty)
        print(f"[v3.0] Written → {output_path}")

    print_stats(hmap, cfg)

# ---------------------------------------------------------------------------
# WATCH mode
# ---------------------------------------------------------------------------
def watch_loop(config_path, output_path, fmt):
    print(f"[--watch] Monitoring {config_path} for changes ... (Ctrl+C to stop)")
    last_hash = ""
    while True:
        try:
            with open(config_path, "rb") as f:
                h = hashlib.md5(f.read()).hexdigest()
            if h != last_hash:
                last_hash = h
                print(f"[--watch] Change detected, rebuilding ...")
                try:
                    build(config_path, output_path, fmt)
                except Exception as e:
                    print(f"[--watch] Build error: {e}")
            time.sleep(1)
        except KeyboardInterrupt:
            print("[--watch] Stopped.")
            break
        except FileNotFoundError:
            time.sleep(2)

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
if args.watch:
    watch_loop(args.config, args.output, args.format)
else:
    build(args.config, args.output, args.format)
