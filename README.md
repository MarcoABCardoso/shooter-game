# Neon Requiem

A complete, asset-free Godot 4 top-down incremental bullet hell. Survive an escalating neon arena where movement, engagement range, and target selection continuously steer how four weapon systems evolve. Bank Flux for permanent ship upgrades and build persistent mastery with the weapons you actually use.

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

The live behavior readout shows three continuous axes: Anchored/Roaming, Close/Distant, and Focus/Spread. Resonance levels do not pause combat or ask for a choice; the current combined profile mutates the build automatically.

The start screen links to a discovery-gated Arsenal Library. Permanent augments live on their own upgrade screen and are purchased with banked Flux.

## Design notes

See [DESIGN_DECISIONS.md](DESIGN_DECISIONS.md) for the living design record and tuning locations.

See [ARCHITECTURE.md](ARCHITECTURE.md) for module responsibilities, dependency rules, and recipes for adding enemies, weapons, and upgrades.

## Validation

```powershell
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --script res://tests/catalog_validation.gd
godot --headless --path . --script res://tests/behavior_progression.gd
```
