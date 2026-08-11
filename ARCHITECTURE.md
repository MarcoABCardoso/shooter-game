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
| `core/run_session.gd` | Operation and mission position, total and per-mission time, signal level, Flux, kills, combo, and mastery earned during a deployment | Nodes or presentation |
| `content/*.gd` | Operation, mission, encounter, enemy, weapon, operation-evolution, skill-tree, and library definitions | Runtime state |
| `systems/spawn_director.gd` | Difficulty cadence and encounter states | Enemy construction |
| `systems/combat_director.gd` | Entity construction, collisions, drops, combat outcomes | Weapon cadence or UI |
| `systems/objective_director.gd` | Signal Defense progress and objective completion | Enemy construction, drawing, or lifecycle transitions |
| `systems/weapon_system.gd` | Equipped weapon timers, targeting, damage, skill effects, and selected run mutations | Drops or choice presentation |
| `ui/game_ui.gd` | Screen coordination and the stable UI façade used by `game.gd` | HUD rendering, overlay composition, or gameplay mutation |
| `ui/run_hud.gd` | Combat status, feedback banners, and mobile-control presentation | Run-state mutation or screen navigation |
| `ui/overlay_view.gd` | Reusable messages, resonance choices, and the Arsenal Library | Lifecycle decisions or profile transactions |
| `ui/mobile_controls.gd` | Mobile detection, movement stick, and touch action intent | Player or game-state mutation |
| `presentation/arena_view.gd` | Arena, grid, and screen shake | Rules and entity lifecycle |
| `profile.gd` | Local profile defaults, reset, unlocks, loadouts, native mastery, and Flux transactions | Balance definitions or backward compatibility for disposable prototype saves |

## Extension recipes

### Add or tune an enemy

1. Add its values to `content/enemy_catalog.gd`.
2. Add isolated behavior to `entities/enemy.gd` only when it needs a new movement or attack family.
3. Add its encounter availability rule to `EncounterCatalog.choose_standard()` or request it from `SpawnDirector`.

### Add or tune an operation encounter

1. Add or edit its definition in `content/encounter_catalog.gd`.
2. Reference it from a mission in `content/operation_catalog.gd`.
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

## Communication contracts

- Directors request visual/audio feedback with signals.
- `CombatDirector` reports kills, Flux, resonance score, repairs, and weapon damage; `game.gd` commits them to `RunSession`.
- `SpawnDirector` emits swarm evacuation, boss arrival, or non-boss completion from the selected encounter definition; `game.gd` owns mission completion and operation reward persistence.
- `GameUI` reports menu intent; `game.gd` validates state transitions and asks `SaveProfile` to transact.
- `GameUI` keeps controller-facing methods stable while delegating combat presentation to `RunHud` and modal content to `OverlayView`; both child views return intent through signals or callables.
- Equipped weapons and the active skill are snapshotted when an operation starts.
- `OperationCatalog` defines the representative operation and its ordered mission references. `RunSession` carries operation-scoped values across missions; `game.gd` resets encounter-local state, presents intermissions, and banks full or partial rewards only when the operation ends.
- `ObjectiveDirector` evaluates the active mission's focused objective and emits progress or completion. `ArenaView` renders that state; `game.gd` translates completion into the existing mission lifecycle.
- Operation resonance applies catalog-owned automatic growth at every level and pauses only at sparse `OperationEvolutionCatalog` breakpoints. `WeaponSystem` owns the resulting Pulse behavior and target-priority mode.
- Damage and active-skill use accumulate native mastery, which is banked with the run.
- The skill tree is the sole permanent stat-growth system. Purchases and full refunds are profile transactions; combat only consumes named effects.
- Manual pausing freezes the `run_entities` group while UI remains active.

## Tests

- `tests/smoke.gd` validates title → hangar → loadout/skill tree → operation deployment → sparse evolution → combat flow.
- `tests/catalog_validation.gd` validates operations, encounter profiles, sparse evolution paths, enemies, loadouts, skill nodes, mastery keys, and save/catalog consistency.
- `tests/skill_tree_progression.gd` validates ranks, prerequisites, Flux costs, effects, and lossless respec.
- `tests/skill_effect_runtime.gd` validates shield recharge and projectile skill-effect wiring.
- `tests/mastery_progression.gd` validates native weapon and active-skill mastery.
- `tests/mobile_controls.gd` validates movement-stick input, the ability button, and safe input release.
- `tests/operation_spine.gd` validates three connected missions, intermissions, operation-scoped state, full completion rewards, and partial retreat/defeat recovery.
- `tests/evolution_control.gd` validates Signal Defense, sparse automatic growth, visible Pulse branches, Sentinel and Scatter positioning rules, the Phase Dash interaction, and target-priority cycling.
