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
| `core/run_session.gd` | Time, signal level, Flux, kills, combo, and mastery earned during a run | Nodes or presentation |
| `content/*.gd` | Enemy, weapon, deterministic run-upgrade, skill-tree, library, and permanent-augment definitions | Runtime state |
| `systems/spawn_director.gd` | Difficulty cadence and stage encounter states | Enemy construction |
| `systems/combat_director.gd` | Entity construction, collisions, drops, combat outcomes | Weapon cadence or UI |
| `systems/weapon_system.gd` | Equipped weapon timers, targeting, damage, skill effects, and selected run mutations | Drops or choice presentation |
| `ui/game_ui.gd` | Screens, HUD, loadout editor, skill graph, and Arsenal Library | Gameplay mutation; it emits intent signals |
| `presentation/arena_view.gd` | Arena, grid, crosshair, screen shake | Rules and entity lifecycle |
| `profile.gd` | Versioned slots, migration, unlocks, loadouts, native mastery, and Flux transactions | Balance definitions |

## Extension recipes

### Add or tune an enemy

1. Add its values to `content/enemy_catalog.gd`.
2. Add isolated behavior to `entities/enemy.gd` only when it needs a new movement or attack family.
3. Add its availability rule to `EnemyCatalog.choose_standard()` or request it from `SpawnDirector`.

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

### Add a permanent augment

1. Add a definition to `content/meta_upgrade_catalog.gd`.
2. Add its rank key to `SaveProfile.DEFAULT_DATA.upgrades`.
3. Consume its named bonus when configuring the relevant runtime system.

## Communication contracts

- Directors request visual/audio feedback with signals.
- `CombatDirector` reports kills, Flux, resonance score, repairs, and weapon damage; `game.gd` commits them to `RunSession`.
- `SpawnDirector` emits the Stage 1 boss transition; `game.gd` owns stage completion and reward persistence.
- `GameUI` reports menu intent; `game.gd` validates state transitions and asks `SaveProfile` to transact.
- Equipped weapons and the active skill are snapshotted when a run starts. Each resonance level pauses simulation and presents every uncapped dimension for every equipped weapon.
- `RunUpgradeCatalog` owns deterministic per-weapon choices; `RunSession` owns their five-rank-per-dimension run state.
- Damage and active-skill use accumulate native mastery, which is banked with the run.
- Skill purchases and full refunds are profile transactions; combat only consumes named bonuses.
- Manual pausing freezes the `run_entities` group while UI remains active.

## Tests

- `tests/smoke.gd` validates title → hangar → loadout/skill tree → deterministic resonance choice → combat flow.
- `tests/run_upgrade_progression.gd` validates per-weapon ownership, stacking, caps, and run reset.
- `tests/catalog_validation.gd` validates enemies, loadouts, skill nodes, mastery keys, and save/catalog consistency.
- `tests/skill_tree_progression.gd` validates ranks, prerequisites, Flux costs, effects, and lossless respec.
- `tests/mastery_progression.gd` validates native weapon and active-skill mastery.
- `tests/stage_one_encounter.gd` validates the boss, stage completion, weapon/slot unlocks, and Vector Parry.
