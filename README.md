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
- **Esc / P:** pause

Weapons automatically target enemies. On phones and tablets, the run HUD adds
a movement stick plus dedicated ability and pause buttons. Touch controls stay
hidden on desktop.

Weapons fire automatically. Each resonance level pauses combat for a deterministic weapon-evolution choice.

## Progression

- A new profile starts with Pulse Cannon and one weapon slot.
- Clearing Stage 1 unlocks Orbit Blades. Defeating the Stage 5 Overseer unlocks Vector Parry and a second weapon slot.
- Deploying opens a five-stage selection route. Each cleared stage unlocks the next.
- Every stage awards a first-clear Flux bonus equal to the enemy Flux earned during that successful deployment.
- Weapons and active skills earn their own permanent mastery. Mastery is intrinsic and cannot be reallocated.
- Every resonance level shows all three upgrade dimensions for every equipped weapon. Choose the weapon and dimension; there are no random rolls.
- Each weapon dimension can gain at most five ranks per run. Pulse improves damage, fire rate, or projectile speed; the other weapons expose similarly identity-specific paths.
- The expanded skill tree begins at Amplified Core and branches into positional damage, projectile speed/size/splash, salvage, weapon-specific damage, shields, and active-skill recharge.
- Skill nodes use Flux, support multiple ranks, and may require parent ranks, stage clears, or item mastery. A stage milestone remains visible while everything beyond it stays hidden until that stage is cleared.
- **Respec All** refunds every Flux point spent on the tree.

Stage 1 is a short, intentionally forgiving drone-only deployment designed to be cleared without permanent upgrades. Stage 2 introduces Strikers, Stage 3 introduces elites, Stage 4 adds Gunners, and Stage 5 adds Tanks before the Overseer assembles for a telegraph-driven duel.

## Design notes

See [MASTER_PLAN.md](MASTER_PLAN.md) for the intended full-game direction,
creator-led development chapters, scope boundaries, and playable milestones.

See [DESIGN_DECISIONS.md](DESIGN_DECISIONS.md) for the living design record and tuning locations.

See [ARCHITECTURE.md](ARCHITECTURE.md) for module responsibilities, dependency rules, and extension recipes.

## Validation

```powershell
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --script res://tests/catalog_validation.gd
godot --headless --path . --script res://tests/run_upgrade_progression.gd
godot --headless --path . --script res://tests/skill_tree_progression.gd
godot --headless --path . --script res://tests/skill_tree_ui.gd
godot --headless --path . --script res://tests/skill_effect_runtime.gd
godot --headless --path . --script res://tests/mastery_progression.gd
godot --headless --path . --script res://tests/stage_one_encounter.gd
godot --headless --path . --script res://tests/mobile_controls.gd
```
