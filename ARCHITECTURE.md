# Architecture

Neon Requiem uses a small composition root and signal-connected modules. The root creates dependencies and controls state transitions; modules do not reach back into the root controller.

## Dependency direction

```text
game.gd (composition and lifecycle)
├── core/          shared values and mutable run state
├── content/       data catalogs and progression definitions
├── systems/       spawning, combat, weapons
├── presentation/  world rendering
├── ui/            menus, HUD, loadout, skill graph
└── entities/      player, enemy, projectile, pickup, burst
```

Dependencies point downward. Content catalogs never depend on systems. Entities may read catalogs but do not know about the game controller or UI. Systems emit signals for outcomes instead of mutating menus or save data.

## Responsibilities

| Module | Owns | Does not own |
|---|---|---|
| `scripts/game.gd` | Lifecycle, state transitions, dependency wiring | Balance data, drawing, widgets, combat algorithms |
| `core/run_session.gd` | Stage time, signal level, Flux, kills, combo, transformations, and mastery earned during one deployment | Nodes or presentation |
| `content/*.gd` | Stage, objective layout, encounter, enemy, weapon, stage-evolution, skill-tree, and library definitions | Runtime state |
| `systems/spawn_director.gd` | Difficulty cadence and encounter states | Enemy construction |
| `systems/combat_director.gd` | Entity construction, collisions, drops, combat outcomes | Weapon cadence or UI |
| `systems/objective_director.gd` | Sequential objective state, animated completion delays, chamber/travel handoffs, Signal Defense progress, Relay Breach target groups, and final mission handoff | Enemy construction, drawing, or campaign reward transactions |
| `systems/weapon_system.gd` | Equipped weapon timers, targeting, damage, weapon-specific transformations, projectile interception, and selected run mutations | Drops or choice presentation |
| `ui/game_ui.gd` | Screen coordination and the stable UI façade used by `game.gd` | HUD rendering, overlay composition, or gameplay mutation |
| `ui/sector_route_view.gd` | Content-driven stage placement, route-link state, and deployment buttons | Campaign transactions, unlock policy, or mission rules |
| `ui/run_hud.gd` | Combat status, feedback banners, and mobile-control presentation | Run-state mutation or screen navigation |
| `ui/overlay_view.gd` | Reusable messages, resonance choices, and the Arsenal Library | Lifecycle decisions or profile transactions |
| `ui/mobile_controls.gd` | Mobile detection, movement stick, and touch action intent | Player or game-state mutation |
| `presentation/arena_view.gd` | Objective chambers, connecting corridors, fixed combat framing, dead-zone transit follow, objective completion animation, grid, and screen shake | Rules and entity lifecycle |
| `profile.gd` | Local profile defaults, reset, stage-clear state, first-clear transactions, unlocks, loadouts, native mastery, and Flux transactions | Balance definitions or backward compatibility for disposable prototype saves |

## Extension recipes

### Add or tune an enemy

1. Add its values to `content/enemy_catalog.gd`.
2. Add isolated behavior to `entities/enemy.gd` only when it needs a new movement or attack family.
3. Add its encounter availability rule to `EncounterCatalog.choose_standard()` or request it from `SpawnDirector`.

### Add or tune a stage encounter

1. Add or edit its definition in `content/encounter_catalog.gd`.
2. Reference it from a focused stage mission in `content/operation_catalog.gd`.
3. Extend catalog and encounter validation when adding an encounter or lifecycle type.

### Add a skill-tree node

1. Add its definition, graph position, ranks, costs, and gates to `content/skill_tree_catalog.gd`.
2. Add its default rank key to `SaveProfile.DEFAULT_DATA.skill_ranks`.
3. Consume its named effect in `player.gd` or `weapon_system.gd`.
4. Extend catalog validation when introducing a new effect family.

### Add a weapon family

1. Add default runtime data and order to `content/weapon_catalog.gd`.
2. Implement cadence and targeting inside `systems/weapon_system.gd`.
3. Add mastery keys to `SaveProfile.DEFAULT_DATA` and `RunSession.mastery`, plus an unlock rule in the profile.
4. Add its hangar and Library presentation.
5. Give it two named tier-one plans and mastery-revealed follow-ups in `OperationEvolutionCatalog`; add runtime coverage in `build_breadth.gd`.

## Communication contracts

- Directors request visual/audio feedback with signals.
- `CombatDirector` reports kills, Flux, resonance score, repairs, weapon damage, and destroyed objective targets; `game.gd` wires those outcomes to the owning run or objective module.
- `SpawnDirector` emits swarm evacuation, boss arrival, or non-boss completion from the selected encounter definition; `game.gd` owns stage completion and reward persistence.
- `GameUI` reports menu intent; `game.gd` validates state transitions and asks `SaveProfile` to transact.
- `GameUI` keeps controller-facing methods stable while delegating combat presentation to `RunHud` and modal content to `OverlayView`; both child views return intent through signals or callables.
- `SectorRouteView` derives its main spine and optional branch from catalog positions, prerequisites, required/optional role, and profile clear state. It emits deployment intent through `GameUI`; it does not decide unlocks or transact rewards.
- Equipped weapons and the active skill are snapshotted when a stage starts. Returning to the hangar permits reconfiguration before another stage.
- `OperationCatalog` catalogs the opening-sector route. Each independently deployable stage owns one focused mission, an ordered objective sequence and chamber layout where appropriate, route prerequisites, one overall deadline, and first-clear rewards. `SaveProfile` owns clear state and transactions; `RunSession` carries values only for the active deployment. The historical class name remains an internal implementation detail.
- `ObjectiveDirector` advances the active mission through its content-defined objective sequence, holds completed geometry on screen for an animation beat, opens travel afterward, activates the next objective only after arrival, requests only the current Relay Breach target group, and emits a final-outro signal before mission completion.
- `game.gd` translates objective arena/travel signals into player bounds and a moving transit spawn window. Intermediate completion and travel preserve enemies and spawning. Only the final-outro signal disables spawning, clears hostile fire, and disperses enemies before rewards appear.
- `CombatDirector` spawns into the active chamber or moving transit window and assigns that arena to enemies and projectiles. `ArenaView` renders all mission chambers and corridors, locks the camera to a constrained chamber, follows horizontal transit through a dead zone, and animates completed objectives. The HUD remains screen-space through `GameUI`'s `CanvasLayer`.
- Stage resonance applies catalog-owned automatic growth at every level and pauses only at sparse `OperationEvolutionCatalog` breakpoints. Choices are filtered to the equipped weapon and its native mastery. `WeaponSystem` owns the resulting named build behavior and target-priority mode.
- Active skills remain entity-local input in `player.gd`; world-facing effects are emitted as signals. `CombatDirector` owns Gravity Tether's braking-aware formation pull, Vector Parry's projectile conversion, and Phase Dash's damaging projectile-clearing lane.
- Damage and active-skill use accumulate native mastery, which is banked with the run.
- `game.gd` clears transient `Player` and `WeaponSystem` presentation when a stage ends. Completed-stage results use one hangar action; retry remains available only after defeat or retreat.
- Stage availability is derived from catalog prerequisites and profile clear counts. `game.gd` validates deployment even when UI intent is emitted programmatically; disabled route buttons are presentation, not authorization.
- The skill tree is the sole permanent stat-growth system. Purchases and full refunds are profile transactions; combat only consumes named effects.
- Manual pausing freezes the `run_entities` group while UI remains active.

## Tests

- `tests/smoke.gd` validates title → hangar → loadout/skill tree → stage selection → sparse evolution → combat flow.
- `tests/catalog_validation.gd` validates stages, encounter profiles, sparse evolution paths, enemies, loadouts, skill nodes, mastery keys, and save/catalog consistency.
- `tests/skill_tree_progression.gd` validates ranks, prerequisites, Flux costs, effects, and lossless respec.
- `tests/skill_effect_runtime.gd` validates shield recharge and projectile skill-effect wiring.
- `tests/mastery_progression.gd` validates native weapon and active-skill mastery.
- `tests/mobile_controls.gd` validates movement-stick input, the ability button, and safe input release.
- `tests/operation_spine.gd` validates route geometry, the fixed-arena survival opener, optional-branch placement, independent stage selection, completion animation, fixed chamber framing, dead-zone transit follow, continuous intermediate pressure, final evacuation, corridor constraints and chamber handoffs, fresh run state, hangar reconfiguration, progressive relay groups, the Overseer stage, full completion rewards, and partial retreat/defeat recovery.
- `tests/evolution_control.gd` validates Signal Defense, sparse automatic growth, visible Pulse branches, displacement-spent Sentinel charge, tuned Scatter behavior, the Phase Mooring interaction, and two-mode target-priority cycling.
- `tests/build_breadth.gd` validates named Orbit, Arc, and Nova plans, mastery follow-ups, Gravity Tether setup, and formation-pressure contracts.
