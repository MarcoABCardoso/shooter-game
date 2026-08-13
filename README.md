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
**Drift Cache** before **Overseer Lock**. Signal Hold is a one-minute survival
stage in a fixed arena: learn movement, automatic fire, active skills, and not
getting hit before objective rules arrive. Drift Cache then introduces moving
Signal Defense fields, and Relay Breach introduces destructible target groups
across connected chambers. Clearing an objective chamber plays a visible
completion pulse and opens forward travel without removing enemy pressure. The
camera remains fixed during a locked chamber, then scrolls through a horizontal
dead zone in the connecting corridor. Final completion evacuates the remaining
enemies, clears transient player and weapon effects, and offers a single return
to the hangar. The hangar renders
Signal Hold, Relay Breach, and Overseer Lock as one route spine, with Drift Cache
visibly branching from the opener. Disabled buttons communicate campaign gates,
and completed links change state without adding status copy. Each mission shows
only its current survival timer or objective deadline.
Retreat banks 75% of earned Flux, defeat banks 50%, both preserve earned mastery,
and stage completion banks all rewards.

Each equipped weapon now owns two named transformation plans. Pulse becomes the
stationary Sentinel or kiting Harrier; Orbit becomes the pursuing Interceptor or
projectile-screen Aegis; Arc becomes the crowd-clearing Conduit or priority-target
Executioner; and Nova becomes the formation-setting Singularity or defensive
Purifier. Native mastery reveals a second follow-up for each plan. Press Q to
toggle Nearest and Ranged Threats targeting modes. Phase Dash is standard
equipment alongside Orbit Blades, Arc Lash, and the formation-setting Gravity
Tether. Drift Cache unlocks Vector Parry, while securing the Overseer unlocks
the advanced Nova Burst.

Pulse Cannon builds Focus while it keeps firing into the same target, making
target-priority control and exposed boss windows part of its baseline plan.
Phase Dash now commits to a long, low-damage, projectile-clearing lane. Gravity
Tether gathers only the forward field, so it cannot pull rear threats through
the ship.

## Progression

- A new profile starts with Pulse Cannon, Orbit Blades, and Arc Lash competing
  for one weapon slot, plus Phase Dash and Gravity Tether as active-skill choices.
- Phase Dash is available immediately; Drift Cache unlocks Vector Parry and a meaningful Flux reserve.
- Equipment rewards receive a dedicated arsenal reveal before returning to the hangar.
- Clearing Signal Hold reveals the optional cache and required breach routes. Relay Breach reveals the sector boss.
- Defeating the Overseer secures Null Meridian and unlocks Nova Burst.
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
