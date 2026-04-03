#!/usr/bin/env python3
"""
build.py  —  roblox-procedural-worlds
Generates roblox-procedural-worlds.rbxlx directly from src/
No Rojo, no npm, no external tools required.
Usage:  python build.py
"""

import os, json, xml.etree.ElementTree as ET
from pathlib import Path
from datetime import datetime

ROOT      = Path(__file__).parent
SRC       = ROOT / "src"
ROJO_CFG  = ROOT / "rojo" / "default.project.json"
OUT_FILE  = ROOT / "roblox-procedural-worlds.rbxlx"

_refcount = 0
def ref():
    global _refcount
    _refcount += 1
    return f"RBX{_refcount:08X}"

def make_item(cls, name, parent):
    item = ET.SubElement(parent, "Item", {"class": cls, "referent": ref()})
    props = ET.SubElement(item, "Properties")
    ET.SubElement(props, "string", {"name": "Name"}).text = name
    return item, props

def make_script(parent, name, source, script_class="ModuleScript"):
    item, props = make_item(script_class, name, parent)
    ET.SubElement(props, "bool",  {"name": "Disabled"}).text = "false"
    src_el = ET.SubElement(props, "ProtectedString", {"name": "Source"})
    src_el.text = source
    return item

def read_lua(path):
    return Path(path).read_text(encoding="utf-8", errors="replace")

with open(ROJO_CFG) as f:
    cfg = json.load(f)

sss_tree = cfg["tree"]["ServerScriptService"]["ProceduralWorldsServer"]
sps_tree = cfg["tree"].get("StarterPlayerScripts", {})

root_el = ET.Element("roblox", {
    "xmlns:xmime": "http://www.w3.org/2005/05/xmlmime",
    "xmlns:xsi":   "http://www.w3.org/2001/XMLSchema-instance",
    "xsi:noNamespaceSchemaLocation": "http://www.roblox.com/roblox.xsd",
    "version": "4",
})
ET.SubElement(root_el, "External").text = "null"
ET.SubElement(root_el, "External").text = "nil"

dm_item = ET.SubElement(root_el, "Item", {"class": "DataModel", "referent": ref()})
ET.SubElement(dm_item, "Properties")

sss_item, sss_props = make_item("ServerScriptService", "ServerScriptService", dm_item)
ET.SubElement(sss_props, "bool", {"name": "Disabled"}).text = "false"

init_path = SRC / "init.server.lua"
if init_path.exists():
    server_item = make_script(sss_item, "ProceduralWorldsServer",
                              read_lua(init_path), script_class="Script")
else:
    server_item, _ = make_item("Script", "ProceduralWorldsServer", sss_item)

added = {"init.server.lua"}
for mod_name, mod_cfg in sss_tree.items():
    if mod_name.startswith("$"):
        continue
    lua_path_str = mod_cfg.get("$path", "") if isinstance(mod_cfg, dict) else ""
    lua_path = ROOT / lua_path_str if lua_path_str else SRC / f"{mod_name}.lua"
    if not lua_path.exists():
        print(f"  [SKIP] {lua_path.name} not found")
        continue
    make_script(server_item, mod_name, read_lua(lua_path), "ModuleScript")
    added.add(lua_path.name)
    print(f"  [OK]   {mod_name}")

for lua_file in sorted(SRC.glob("*.lua")):
    if lua_file.name in added or lua_file.name == "init.server.lua":
        continue
    mod_name = lua_file.stem
    if ".client" in lua_file.name:
        cls = "LocalScript"
    elif ".server" in lua_file.name:
        cls = "Script"
    else:
        cls = "ModuleScript"
    make_script(server_item, mod_name, read_lua(lua_file), cls)
    print(f"  [AUTO] {mod_name}")

sps_item, _ = make_item("StarterPlayer", "StarterPlayer", dm_item)
spsc_item, _ = make_item("StarterPlayerScripts", "StarterPlayerScripts", sps_item)

for mod_name, mod_cfg in sps_tree.items():
    lua_path_str = mod_cfg.get("$path", "") if isinstance(mod_cfg, dict) else ""
    lua_path = ROOT / lua_path_str if lua_path_str else SRC / f"{mod_name}.lua"
    if not lua_path.exists():
        print(f"  [SKIP] {lua_path.name} not found (StarterPlayerScripts)")
        continue
    make_script(spsc_item, mod_name, read_lua(lua_path), "LocalScript")
    print(f"  [OK]   {mod_name} (client)")

ws_item, ws_props = make_item("Workspace", "Workspace", dm_item)
ET.SubElement(ws_props, "bool",  {"name": "StreamingEnabled"}).text = "true"
ET.SubElement(ws_props, "float", {"name": "Gravity"}).text = "196.2"

tree = ET.ElementTree(root_el)
ET.indent(tree, space="  ")
tree.write(str(OUT_FILE), encoding="utf-8", xml_declaration=True)

size_kb = OUT_FILE.stat().st_size // 1024
print(f"\n✅  Built: {OUT_FILE.name}  ({size_kb} KB)")
print(f"   Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print(f"   Open in Roblox Studio -> File -> Open -> select the .rbxlx file")
