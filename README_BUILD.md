# Build System — No Rojo Required

Proiectul se compileaza direct dintr-un script Python in format `.rbxlx` (Roblox Place File).

## Quick Start

### Prima data
```
setup.bat          <- instaleaza dependente + build automat
```

### Build manual
```
build.bat          <- rebuild .rbxlx din src/
```

### Live Watch (rebuild la fiecare salvare)
```
watch.bat          <- porneste watcher-ul
```

## Cum functioneaza

```
src/*.lua  --►  build.py  --►  roblox-procedural-worlds.rbxlx  --►  Studio
```

`build.py` citeste `rojo/default.project.json` pentru a respecta mapping-ul exact
(ce merge in `ServerScriptService`, ce merge in `StarterPlayerScripts`)
si plaseaza fiecare modul in locul corect din Place File.

## Workflow zilnic

1. Editezi in VS Code orice fisier din `src/`
2. `watch.bat` detecteaza automat schimbarea si rebuilds
3. In Studio: `File -> Open -> roblox-procedural-worlds.rbxlx`
4. Play ▶

## Cerinte

- Python 3.8+ (https://python.org) — adauga la PATH la instalare
- `pip install watchdog` (rulat automat de setup.bat / watch.py)

Nimic altceva. Fara npm, fara Rojo, fara Rust, fara binar extern.
