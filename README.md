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
- **Space:** equipped active skill
- **Q:** cycle automatic target priority during operations
- **Esc / P:** pause

Weapons automatically target enemies. On phones and tablets, the run HUD adds
a movement stick plus dedicated ability and pause buttons. Touch controls stay
hidden on desktop.

Weapons fire automatically. During Signal Breach, ordinary resonance levels
improve baseline weapon output automatically; levels 2 and 4 pause for a visible,
behavior-changing Pulse evolution.

Deploy starts the Chapter 1 prototype operation, **Signal Breach**. It opens with
a short Signal Defense mission before two escalating Assault encounters.
Intermissions fully repair hull while build growth, Flux, mastery, and total time
carry forward. Retreat banks 75% of earned Flux, defeat banks 50%, both preserve
earned mastery, and completion banks all rewards.

The first operation transformation chooses between Bastion Array, which charges
damage, range, and knockback while the ship holds position, and Scatter Array, a
close-range spread that fires harder and faster while the ship is moving. Press
Q to cycle Nearest, Ranged Threats, and Highest Health targeting modes.

## Progression

- A new profile starts with Pulse Cannon and one weapon slot.
- Signal Breach is the sole deployment flow in the current prototype.
- Weapons and active skills earn their own permanent mastery. Mastery is intrinsic and cannot be reallocated.
- Resonance uses automatic growth and sparse transformations instead of repeated scalar choices.
- The expanded skill tree begins at Amplified Core and branches into positional damage, projectile speed/size/splash, salvage, weapon-specific damage, shields, and active-skill recharge.
- Skill nodes use Flux, support multiple ranks, and may require parent ranks or item mastery.
- **Respec All** refunds every Flux point spent on the tree.

## Design notes

See [MASTER_PLAN.md](MASTER_PLAN.md) for the intended full-game direction,
creator-led development chapters, scope boundaries, and playable milestones.

See [DESIGN_DECISIONS.md](DESIGN_DECISIONS.md) for the living design record and tuning locations.

See [ARCHITECTURE.md](ARCHITECTURE.md) for module responsibilities, dependency rules, and extension recipes.

## Validation

```powershell
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --script res://tests/catalog_validation.gd
godot --headless --path . --script res://tests/skill_tree_progression.gd
godot --headless --path . --script res://tests/skill_tree_ui.gd
godot --headless --path . --script res://tests/skill_effect_runtime.gd
godot --headless --path . --script res://tests/mastery_progression.gd
godot --headless --path . --script res://tests/mobile_controls.gd
godot --headless --path . --script res://tests/operation_spine.gd
godot --headless --path . --script res://tests/evolution_control.gd
```
