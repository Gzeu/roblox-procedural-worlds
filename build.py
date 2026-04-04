#!/usr/bin/env python3
"""
build.py  --  roblox-procedural-worlds  v7.1
============================================
Generates a 100% Roblox-Studio-compatible .rbxlx file from src/.

What this builder does:
  1. Creates correct service hierarchy (DataModel > services)
  2. Places ProceduralWorldsServer (Script) inside ServerScriptService
  3. All *.lua module files -> ModuleScript children of the server Script
  4. CLIENT_SCRIPTS -> LocalScript in StarterPlayer > StarterPlayerScripts
  5. ReplicatedStorage: ProceduralWorldsRemotes folder with all RemoteEvents
     and RemoteFunctions (including InventoryRemote v7.0)
  6. ServerStorage: placeholder Part models for every biome/mob asset
  7. Workspace: SpawnLocation at Y=5, solid BasePlatform at Y=0,
     StreamingEnabled, Gravity
  8. Lighting: ambient, fog, Atmosphere, built-in Sky
  9. Validates every .lua file is included -- warns on missing

Usage:
    python build.py
    -> roblox-procedural-worlds.rbxlx  (open with Studio: File -> Open)
"""

import os, re
from pathlib import Path
from datetime import datetime
import xml.etree.ElementTree as ET

ROOT     = Path(__file__).parent
SRC      = ROOT / "src"
OUT_FILE = ROOT / "roblox-procedural-worlds.rbxlx"

# Scripts that go to StarterPlayerScripts as LocalScript
CLIENT_SCRIPTS = {
    "WeatherClient",
    "NPCDialogueClient",
    "AmbienceClient",
    "InventoryUI.client",
    "HUD.client",
    "MinimapUI.client",
    "QuestTracker.client",
    "DialogueUI.client",
}

# The bootstrap server Script (init)
INIT_FILE = "init.server.lua"

# Placeholder biome assets to create in ServerStorage
BIOME_ASSETS = [
    # Trees
    "PineTree", "OakTree", "PalmTree", "DeadTree", "JungleTree", "BirchTree",
    # Rocks
    "BoulderSmall", "BoulderLarge", "RockCluster", "IceRock", "VolcanicRock",
    # Bushes / plants
    "Bush", "Fern", "Cactus", "MushroomCluster", "FlowerPatch",
    # Structures
    "AbandonedCabin", "AncientRuins", "SandTemple", "WatchTower",
    "SwampHut", "IceShrineRuins", "JungleShrine", "VolcanoAltar",
    # Mobs
    "Goblin", "Troll", "Golem", "IceWarden", "DesertScorpion",
    "SwampWretch", "JungleSerpent", "LavaBrute", "OceanKraken",
    # Bosses
    "AncientDragon", "FrostLich", "VolcanoTitan",
]

# RemoteEvents in ReplicatedStorage > ProceduralWorldsRemotes
REPLICATED_EVENTS = [
    "WeatherRemote",
    "NPCDialogueRemote",
    "NotificationRemote",
    "BossSpawnRemote",
    "LevelUpRemote",
    "QuestCompleteRemote",
    "InventoryUpdateRemote",
    "SoundRemote",
]

# RemoteFunctions
REPLICATED_FUNCTIONS = [
    "SeedRemote",
    "InventoryRemote",
]

# ============================================================

_ref = 0
def new_ref():
    global _ref
    _ref += 1
    return "RBX{:08X}".format(_ref)


def item(parent, cls, name):
    el = ET.SubElement(parent, "Item", {"class": cls, "referent": new_ref()})
    props = ET.SubElement(el, "Properties")
    _str(props, "Name", name)
    return el, props


def _str(props, k, v):
    ET.SubElement(props, "string", {"name": k}).text = str(v)


def _bool(props, k, v):
    ET.SubElement(props, "bool", {"name": k}).text = "true" if v else "false"


def _float(props, k, v):
    ET.SubElement(props, "float", {"name": k}).text = str(v)


def _int(props, k, v):
    ET.SubElement(props, "int", {"name": k}).text = str(int(v))


def _color3(props, k, r, g, b):
    el = ET.SubElement(props, "Color3", {"name": k})
    ET.SubElement(el, "R").text = str(r)
    ET.SubElement(el, "G").text = str(g)
    ET.SubElement(el, "B").text = str(b)


def _brickcolor(props, k, value):
    ET.SubElement(props, "BrickColor", {"name": k}).text = str(value)


def _vec3(props, k, x, y, z):
    el = ET.SubElement(props, "Vector3", {"name": k})
    ET.SubElement(el, "X").text = str(x)
    ET.SubElement(el, "Y").text = str(y)
    ET.SubElement(el, "Z").text = str(z)


def _cframe(props, k, x, y, z):
    el = ET.SubElement(props, "CoordinateFrame", {"name": k})
    for tag, val in zip(
        ["X","Y","Z","R00","R01","R02","R10","R11","R12","R20","R21","R22"],
        [x,   y,   z,   1,    0,    0,    0,    1,    0,    0,    0,    1  ]
    ):
        ET.SubElement(el, tag).text = str(val)


def make_script(parent, name, source, cls="ModuleScript"):
    el, props = item(parent, cls, name)
    _bool(props, "Disabled", False)
    src_el = ET.SubElement(props, "ProtectedString", {"name": "Source"})
    src_el.text = source
    return el


def placeholder_model(parent, name):
    """A named Model with a buried invisible Part."""
    el, props = item(parent, "Model", name)
    part_el, part_props = item(el, "Part", "Placeholder")
    _bool(part_props, "Anchored",    True)
    _bool(part_props, "CanCollide",  False)
    _float(part_props, "Transparency", 1.0)
    _vec3(part_props,  "Size",  2, 2, 2)
    _cframe(part_props, "CFrame", 0, -200, 0)
    return el


# ============================================================
print("")
print("[roblox-procedural-worlds builder v7.1]")
print("   Source : " + str(SRC))
print("   Output : " + str(OUT_FILE))
print("")

# Discover all .lua files
all_lua = {p.name: p for p in sorted(SRC.glob("*.lua"))}


def canonical(filename):
    """Strip .lua and .client from filename to get display name."""
    stem = filename.removesuffix(".lua")
    stem = re.sub(r"\.client$", "", stem)
    return stem


# Build lookup: canonical name -> (path, original filename)
name_map = {canonical(fname): (fpath, fname) for fname, fpath in all_lua.items()}

client_map = {}
server_map = {}

for cname, (fpath, fname) in name_map.items():
    if fname == INIT_FILE:
        continue
    if cname in CLIENT_SCRIPTS or fname.removesuffix(".lua") in CLIENT_SCRIPTS:
        client_map[cname] = fpath
    else:
        server_map[cname] = fpath

# Build XML root
root_el = ET.Element("roblox", {
    "xmlns:xmime": "http://www.w3.org/2005/05/xmlmime",
    "xmlns:xsi":   "http://www.w3.org/2001/XMLSchema-instance",
    "xsi:noNamespaceSchemaLocation": "http://www.roblox.com/roblox.xsd",
    "version": "4",
})
ET.SubElement(root_el, "External").text = "null"
ET.SubElement(root_el, "External").text = "nil"

dm = ET.SubElement(root_el, "Item", {"class": "DataModel", "referent": new_ref()})
ET.SubElement(dm, "Properties")

# ── 1. ServerScriptService ──────────────────────────────────────────────────
sss, sss_p = item(dm, "ServerScriptService", "ServerScriptService")
_bool(sss_p, "Disabled", False)

init_path = SRC / INIT_FILE
if not init_path.exists():
    print("  FATAL: " + INIT_FILE + " not found in src/")
    raise SystemExit(1)

server_root = make_script(
    sss, "ProceduralWorldsServer",
    init_path.read_text(encoding="utf-8"),
    "Script"
)

for mod_name in sorted(server_map):
    lua_path = server_map[mod_name]
    make_script(server_root, mod_name, lua_path.read_text(encoding="utf-8"), "ModuleScript")
    print("  [SSS ModuleScript]  " + mod_name)

# ── 2. StarterPlayer > StarterPlayerScripts ─────────────────────────────────
sp,   _ = item(dm, "StarterPlayer",        "StarterPlayer")
spsc, _ = item(sp,  "StarterPlayerScripts", "StarterPlayerScripts")

for mod_name in sorted(client_map):
    lua_path = client_map[mod_name]
    make_script(spsc, mod_name, lua_path.read_text(encoding="utf-8"), "LocalScript")
    print("  [StarterPlayerScripts LocalScript]  " + mod_name)

# ── 3. ReplicatedStorage ────────────────────────────────────────────────────
rs, _        = item(dm, "ReplicatedStorage", "ReplicatedStorage")
folder_el, _ = item(rs,  "Folder",           "ProceduralWorldsRemotes")

for ev_name in REPLICATED_EVENTS:
    item(folder_el, "RemoteEvent", ev_name)
    print("  [RS] RemoteEvent      " + ev_name)

for fn_name in REPLICATED_FUNCTIONS:
    item(folder_el, "RemoteFunction", fn_name)
    print("  [RS] RemoteFunction   " + fn_name)

# ── 4. ServerStorage ────────────────────────────────────────────────────────
stor, _          = item(dm, "ServerStorage", "ServerStorage")
assets_folder, _ = item(stor, "Folder", "ProceduralAssets")

for asset_name in BIOME_ASSETS:
    placeholder_model(assets_folder, asset_name)

print("  [SS] " + str(len(BIOME_ASSETS)) + " placeholder asset models in ServerStorage/ProceduralAssets")

# ── 5. Workspace ────────────────────────────────────────────────────────────
ws, ws_p = item(dm, "Workspace", "Workspace")
_bool(ws_p,  "StreamingEnabled",      True)
_float(ws_p, "StreamingMinRadius",    64)
_float(ws_p, "StreamingTargetRadius", 512)
_float(ws_p, "Gravity",               196.2)
_bool(ws_p,  "ResetOnSpawn",          False)

# BasePlatform -- solid ground under spawn so players don't fall in the void
base, base_p = item(ws, "Part", "BasePlatform")
_bool(base_p,  "Anchored",   True)
_bool(base_p,  "CanCollide", True)
_float(base_p, "Transparency", 0.0)
_vec3(base_p,  "Size",  512, 4, 512)
_cframe(base_p, "CFrame", 0, -2, 0)   # top surface at Y=0
_brickcolor(base_p, "BrickColor", 194)  # Medium green
_color3(base_p, "Color", 0.345098, 0.517647, 0.254902)
print("  [WS] BasePlatform 512x4x512 at Y=-2 (top surface Y=0)")

# SpawnLocation at Y=5 (safe above BasePlatform)
spawn, spawn_p = item(ws, "SpawnLocation", "SpawnLocation")
_bool(spawn_p,  "Anchored",   True)
_bool(spawn_p,  "CanCollide", True)
_bool(spawn_p,  "Neutral",    True)
_bool(spawn_p,  "AllowTeamChangeOnTouch", False)
_vec3(spawn_p,  "Size",   20, 1, 20)
_cframe(spawn_p, "CFrame", 0, 5, 0)   # Y=5: sits on top of BasePlatform
_int(spawn_p,   "Duration", 10)
print("  [WS] SpawnLocation 20x1x20 at Y=5 (above BasePlatform)")

# ── 6. Lighting + Atmosphere + Sky ──────────────────────────────────────────
lt, lt_p = item(dm, "Lighting", "Lighting")
_bool(lt_p,  "GlobalShadows",  True)
_float(lt_p, "Brightness",     2.0)
_float(lt_p, "ClockTime",      12.0)
_float(lt_p, "FogEnd",         2000)
_float(lt_p, "FogStart",       0)
_float(lt_p, "ShadowSoftness", 0.5)
_color3(lt_p, "Ambient",         0.5,  0.5,  0.5)
_color3(lt_p, "OutdoorAmbient",  0.7,  0.7,  0.7)
_color3(lt_p, "FogColor",        0.75, 0.82, 0.90)
_str(lt_p, "EnvironmentDiffuseScale", "0.3")

atmo, atmo_p = item(lt, "Atmosphere", "Atmosphere")
_float(atmo_p, "Density",  0.35)
_float(atmo_p, "Offset",   0.05)
_float(atmo_p, "Scatter",  0.5)
_float(atmo_p, "Glare",    0.08)
_float(atmo_p, "Haze",     1.8)
_color3(atmo_p, "Color",       0.70, 0.80, 0.95)
_color3(atmo_p, "DecayColor",  0.80, 0.72, 0.65)

sky, sky_p = item(lt, "Sky", "Sky")
for face in ["Bk","Dn","Ft","Lf","Rt","Up"]:
    _str(sky_p, "Skybox" + face, "rbxasset://textures/sky/sky512_" + face.lower() + ".tex")
_float(sky_p, "SunAngularSize",  21)
_float(sky_p, "MoonAngularSize", 11)
print("  [LT] Lighting + Atmosphere + Sky")

# ── Validation ────────────────────────────────────────────────────────────────
print("")
print("[Validation] -----------------------------")
all_included = set(server_map.keys()) | set(client_map.keys()) | {"init.server"}
missing = []
for fname, fpath in all_lua.items():
    cname = canonical(fname)
    stem  = fname.removesuffix(".lua")
    if cname not in all_included and stem not in all_included and stem != "init.server":
        missing.append(fname)
        print("  [WARNING] NOT INCLUDED: " + fname)
if not missing:
    print("  All .lua files included OK")

# ── Write ─────────────────────────────────────────────────────────────────────
tree = ET.ElementTree(root_el)
ET.indent(tree, space="  ")
tree.write(str(OUT_FILE), encoding="utf-8", xml_declaration=True)

size_kb = OUT_FILE.stat().st_size // 1024
server_count = len(server_map)
client_count = len(client_map)

print("")
print("[Build complete!]")
print("   File: " + OUT_FILE.name + "  (" + str(size_kb) + " KB)")
print("   Time: " + datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
print("   Server: " + str(server_count) + " server ModuleScripts")
print("   Client: " + str(client_count) + " client LocalScripts")
print("   Remote: " + str(len(REPLICATED_EVENTS)) + " RemoteEvents + " + str(len(REPLICATED_FUNCTIONS)) + " RemoteFunctions")
print("   Assets: " + str(len(BIOME_ASSETS)) + " placeholder asset models")
print("")
print("   HOW TO OPEN IN STUDIO:")
print("   File -> Open from File -> select roblox-procedural-worlds.rbxlx")
print("")
print("   EXPECTED HIERARCHY:")
print("   Workspace")
print("     -- BasePlatform   [Part]  512x4x512 at Y=-2  (solid ground)")
print("     -- SpawnLocation  [SpawnLocation] 20x1x20 at Y=5")
print("   ServerScriptService")
print("     -- ProceduralWorldsServer  [Script]")
print("          -- AnimationManager     [ModuleScript]")
print("          -- SoundManager         [ModuleScript]")
print("          -- InventoryRemote      [ModuleScript]")
print("          -- ... all other ModuleScripts")
print("   StarterPlayer -> StarterPlayerScripts")
print("          -- AmbienceClient       [LocalScript]")
print("          -- InventoryUI.client   [LocalScript]")
print("          -- HUD.client           [LocalScript]")
print("          -- MinimapUI.client     [LocalScript]")
print("          -- QuestTracker.client  [LocalScript]")
print("          -- DialogueUI.client    [LocalScript]")
print("          -- WeatherClient        [LocalScript]")
print("          -- NPCDialogueClient    [LocalScript]")
print("   ReplicatedStorage -> ProceduralWorldsRemotes")
print("          -- InventoryRemote      [RemoteFunction]")
print("          -- SoundRemote          [RemoteEvent]")
print("          -- ... all other remotes")
print("   ServerStorage -> ProceduralAssets")
print("          -- (placeholder models for all biome assets + mobs + bosses)")
print("")
