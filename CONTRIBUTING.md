# Contributing to Roblox Procedural Worlds

Thank you for your interest in contributing! This project welcomes bug reports, feature suggestions, documentation improvements, and code contributions.

## Getting Started

1. **Fork** the repository and clone it locally.
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Make your changes (see guidelines below).
4. Commit with a clear message: `git commit -m "feat: description"`
5. Push and open a **Pull Request** against `main`.

## Code Guidelines

- All Lua files must use `--!strict` at the top.
- Follow the existing module pattern: a local table, public functions on it, `return` at the end.
- Use `pcall` around any Roblox API calls that can fail (FillBlock, Clone, etc.).
- Do not use `wait()` — use `task.wait()` or `task.spawn()` instead.
- Keep functions small and focused; split into separate modules if needed.
- Type-annotate all function parameters and return values.

## Commit Message Format

Use conventional commits:

```
feat: add river carving system
fix: cave threshold off-by-one at CaveMaxY
docs: update BIOMES.md with Ocean biome detail
refactor: extract noise helpers into NoiseUtil module
```

## Adding a New Biome

1. Add a definition to `WorldConfig.Biomes` (see README for the schema).
2. Add a pole entry to `BiomeResolver.BIOME_POLES` with matching key.
3. Document it in `docs/BIOMES.md`.
4. Open a PR — no other files need to change.

## Adding a New Ore

1. Add an entry to `WorldConfig.OreVeins`.
2. No other code changes required — `OreGenerator` reads the table dynamically.

## Reporting Bugs

Open a GitHub Issue with:
- Roblox Studio version
- Steps to reproduce
- Expected vs. actual behaviour
- Console output / error messages if applicable

## Feature Requests

Open a GitHub Issue with the `enhancement` label. Please check existing issues first to avoid duplicates.

## Code of Conduct

Be respectful. Constructive criticism is welcome; personal attacks are not.
