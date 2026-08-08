# Neon Requiem

A complete, asset-free Godot 4 top-down incremental bullet hell. Clear a focused first stage where movement, engagement range, and target selection continuously steer how four weapon systems evolve, then dismantle the modular Overseer Array. Bank Flux for permanent ship upgrades and build persistent mastery with the weapons you actually use.

## Play online

[Play Neon Requiem in your browser](https://marcoabcardoso.github.io/shooter-game/)

## Run

Open `project.godot` in Godot 4.3 or newer and press **F6/F5**, or run:

```powershell
godot --path .
```

## Controls

- **WASD / arrow keys:** move
- **Mouse:** aim the Pulse Cannon
- **Space:** equipped ability (Phase Dash initially; Vector Parry after clearing Stage 1)
- **Esc / P:** pause
- Weapons fire automatically.

The live behavior readout shows three continuous axes: Anchored/Roaming, Close/Distant, and Focus/Spread. Resonance levels do not pause combat or ask for a choice; the current combined profile mutates the build automatically.

The start screen links to a discovery-gated Arsenal Library covering weapons, abilities, and all eight behavior-driven in-run evolutions. Permanent augments live on their own upgrade screen and are purchased with banked Flux. The Callibrations screen can reroute earned weapon mastery into a shared pool; each weapon can reach at most twice its native mastery, and new ranks default to the weapon that earned them.

Stage 1 culminates at 02:00. The swarm evacuates, the Overseer assembles from three connected attack modules, and regular spawning stops for a telegraph-driven duel. Clearing it unlocks Vector Parry as a drop-in replacement for Phase Dash.

## Design notes

See [DESIGN_DECISIONS.md](DESIGN_DECISIONS.md) for the living design record and tuning locations.

See [ARCHITECTURE.md](ARCHITECTURE.md) for module responsibilities, dependency rules, and recipes for adding enemies, weapons, and upgrades.

## Validation

```powershell
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --script res://tests/catalog_validation.gd
godot --headless --path . --script res://tests/behavior_progression.gd
godot --headless --path . --script res://tests/stage_one_encounter.gd
```
