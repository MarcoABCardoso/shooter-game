# Neon Requiem

An asset-free Godot 4 top-down bullet hell built around deliberate hangar loadouts. Choose weapons and an active skill before deployment, earn native mastery by using them, and spend banked Flux on a freely respeccable graph skill tree.

## Play online

[Play Neon Requiem in your browser](https://marcoabcardoso.github.io/shooter-game/)

## Run

Open `project.godot` in Godot 4.3 or newer and press **F6/F5**, or run:

```powershell
godot --path .
```

## Controls

- **WASD / arrow keys:** move
- **Mouse:** aim directional weapons
- **Space:** equipped active skill
- **Esc / P:** pause

Weapons fire automatically. Each resonance level pauses combat for a deterministic weapon-evolution choice.

## Progression

- A new profile can choose Pulse Cannon, Orbit Blades, or Arc Lash, with one weapon slot available.
- Clearing Stage 1 unlocks Nova Burst, a second weapon slot, and Vector Parry.
- Weapons and active skills earn their own permanent mastery. Mastery is intrinsic and cannot be reallocated.
- Every resonance level shows all three upgrade dimensions for every equipped weapon. Choose the weapon and dimension; there are no random rolls.
- Each weapon dimension can gain at most five ranks per run. Pulse improves damage, fire rate, or projectile speed; the other weapons expose similarly identity-specific paths.
- The skill tree begins at Amplified Core and branches into distant, stationary, knockback, weapon-specific, and defensive bonuses.
- Skill nodes use Flux, support multiple ranks, and may require parent ranks, stage clears, or item mastery.
- **Respec All** refunds every Flux point spent on the tree.
- Permanent Augments remain a separate, non-refundable progression track.

Stage 1 culminates at 02:00. The swarm evacuates, the Overseer assembles from three connected attack modules, and regular spawning stops for a telegraph-driven duel.

## Design notes

See [DESIGN_DECISIONS.md](DESIGN_DECISIONS.md) for the living design record and tuning locations.

See [ARCHITECTURE.md](ARCHITECTURE.md) for module responsibilities, dependency rules, and extension recipes.

## Validation

```powershell
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --script res://tests/catalog_validation.gd
godot --headless --path . --script res://tests/run_upgrade_progression.gd
godot --headless --path . --script res://tests/skill_tree_progression.gd
godot --headless --path . --script res://tests/mastery_progression.gd
godot --headless --path . --script res://tests/stage_one_encounter.gd
```
