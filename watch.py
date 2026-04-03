#!/usr/bin/env python3
"""
watch.py  —  roblox-procedural-worlds
Watches src/ for changes and rebuilds .rbxlx automatically.
Usage:  python watch.py
Install deps once:  pip install watchdog
"""

import time, subprocess, sys
from pathlib import Path

SRC = Path(__file__).parent / "src"

try:
    from watchdog.observers import Observer
    from watchdog.events    import FileSystemEventHandler
except ImportError:
    print("Installing watchdog...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "watchdog", "-q"])
    from watchdog.observers import Observer
    from watchdog.events    import FileSystemEventHandler

_last_build = 0
DEBOUNCE = 1.5

class Handler(FileSystemEventHandler):
    def on_modified(self, event):
        global _last_build
        if not str(event.src_path).endswith(".lua"):
            return
        now = time.time()
        if now - _last_build < DEBOUNCE:
            return
        _last_build = now
        print(f"\n🔄  Change detected: {Path(event.src_path).name}")
        subprocess.run([sys.executable, "build.py"])

print("👀  Watching src/ for changes... (Ctrl+C to stop)")
print("    Open roblox-procedural-worlds.rbxlx in Studio")
print("    Re-open the file after each rebuild to pick up changes.\n")

subprocess.run([sys.executable, "build.py"])

obs = Observer()
obs.schedule(Handler(), str(SRC), recursive=False)
obs.start()
try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    obs.stop()
obs.join()
print("\n✅  Watcher stopped.")
