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
- **Q:** cycle automatic target priority during stages
- **Esc / P:** pause

Weapons automatically target enemies. On phones and tablets, the run HUD adds
a movement stick plus dedicated ability and pause buttons. Touch controls stay
hidden on desktop.

Weapons fire automatically. During a stage, ordinary resonance levels
improve baseline weapon output automatically; levels 2 and 5 pause for a visible,
behavior-changing Pulse evolution.

The opening sector, **Null Meridian**, begins with **Signal Hold**, then opens a
required route through **Relay Breach** and an optional power route through
**Drift Cache** before **Overseer Lock**. Each deployment develops one focused
combat problem through a short sequence of objective chambers. Clearing a
chamber plays a visible completion pulse and opens forward travel without
removing enemy pressure. The camera remains fixed during a locked chamber, then
scrolls through a horizontal dead zone in the connecting corridor. The next
objective begins only after the player arrives. Final completion evacuates the
remaining enemies before returning to the hangar. The hangar renders
Signal Hold, Relay Breach, and Overseer Lock as one route spine, with Drift Cache
visibly branching from the opener. Disabled buttons communicate campaign gates,
and completed links change state without adding status copy. The mission introduces
its current objective and overall deadline when play begins.
Retreat banks 75% of earned Flux, defeat banks 50%, both preserve earned mastery,
and stage completion banks all rewards.

Each equipped weapon now owns two named transformation plans. Pulse becomes the
stationary Sentinel or kiting Harrier; Orbit becomes the pursuing Interceptor or
projectile-screen Aegis; Arc becomes the crowd-clearing Conduit or priority-target
Executioner; and Nova becomes the formation-setting Singularity or defensive
Purifier. Native mastery reveals a second follow-up for each plan. Press Q to
toggle Nearest and Ranged Threats targeting modes. Phase Dash is standard
equipment, Drift Cache unlocks Vector Parry, and securing the Overseer unlocks
the comparison arsenal plus Gravity Tether, a formation-setup active skill.

## Progression

- A new profile starts with Pulse Cannon and one weapon slot.
- Phase Dash is available immediately; Drift Cache unlocks Vector Parry and a meaningful Flux reserve.
- Clearing Signal Hold reveals the optional cache and required breach routes. Relay Breach reveals the sector boss.
- Defeating the Overseer secures Null Meridian and unlocks Orbit Blades, Arc Lash, Nova Burst, and Gravity Tether for Chapter 3 build trials.
- First-clear stage rewards are permanent and do not repeat; earned run Flux still uses full, retreat, and defeat banking rules.
- Weapons and active skills earn their own permanent mastery. Mastery is intrinsic and cannot be reallocated.
- Resonance uses automatic growth and sparse transformations instead of repeated scalar choices.
- The permanent tree replaces imperceptible projectile speed/size bonuses with targeting reach, piercing, additional Arc jumps and Orbit blades, projectile interception, splash, defense, salvage, and active-skill cadence.
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
godot --headless --path . --script res://tests/build_breadth.gd
```
