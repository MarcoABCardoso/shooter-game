# Neon Requiem

A complete, asset-free Godot 4 top-down incremental bullet hell. Survive an escalating neon arena, evolve four weapon systems during each run, bank Flux for permanent ship upgrades, and build persistent mastery with the weapons you actually use.

## Run

Open `project.godot` in Godot 4.3 or newer and press **F6/F5**, or run:

```powershell
godot --path .
```

## Controls

- **WASD / arrow keys:** move
- **Mouse:** aim the Pulse Cannon
- **Space:** phase dash (brief invulnerability)
- **Esc / P:** pause
- Weapons fire automatically.

## Design notes

See [DESIGN_DECISIONS.md](DESIGN_DECISIONS.md) for the living design record and tuning locations.

See [ARCHITECTURE.md](ARCHITECTURE.md) for module responsibilities, dependency rules, and recipes for adding enemies, weapons, and upgrades.

## Validation

```powershell
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --script res://tests/catalog_validation.gd
```
