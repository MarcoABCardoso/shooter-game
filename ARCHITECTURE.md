# Architecture

Neon Requiem uses a small composition root and signal-connected modules. The root creates dependencies and controls state transitions; modules do not reach back into the root controller.

## Dependency direction

```text
game.gd (composition and lifecycle)
├── core/          shared values and mutable run state
├── content/       data catalogs and upgrade application
├── systems/       spawning, combat, weapons
├── presentation/  world rendering
├── ui/            menus, HUD, overlays, widget styles
└── entities/      player, enemy, projectile, pickup, burst
```

Dependencies point downward. Content catalogs never depend on systems. Entities may read their catalog, but do not know about the game controller or UI. Systems emit signals for outcomes instead of mutating menus or save data.

## Responsibilities

| Module | Owns | Does not own |
|---|---|---|
| `scripts/game.gd` | Lifecycle, state transitions, dependency wiring | Balance data, drawing, widgets, combat algorithms |
| `core/run_session.gd` | Time, XP, level, Flux, kills, combo, run mastery | Nodes or presentation |
| `content/*.gd` | Enemy/weapon/upgrade definitions | Runtime state |
| `systems/spawn_director.gd` | Difficulty cadence and spawn requests | Enemy construction |
| `systems/combat_director.gd` | Entity construction, collisions, drops, combat events | Weapon cadence, UI, profile mutation |
| `systems/weapon_system.gd` | Weapon timers, targeting, damage, weapon effects | Drops, progression choices |
| `ui/game_ui.gd` | Screens and HUD projection | Gameplay mutation; it emits intent signals |
| `presentation/arena_view.gd` | Arena, grid, crosshair, screen shake | Rules and entity lifecycle |
| `profile.gd` | Versioned serialization and profile transactions | Upgrade balance definitions |

## Extension recipes

### Add or tune an enemy

1. Add its values to `content/enemy_catalog.gd`.
2. If it uses an existing movement family and silhouette, no other change is required.
3. For a new behavior, add one isolated behavior branch to `entities/enemy.gd`.
4. Add its availability rule to `EnemyCatalog.choose_standard()` or request it explicitly from `SpawnDirector`.

### Add a weapon upgrade

1. Add a choice to `content/upgrade_catalog.gd`.
2. Add its mutation to `UpgradeCatalog.apply()`.
3. If it changes timers on unlock, handle that notification in `WeaponSystem.on_upgrade_applied()`.

### Add a new weapon family

1. Add default runtime data and order to `content/weapon_catalog.gd`.
2. Implement its cadence and targeting inside `systems/weapon_system.gd`.
3. Add its mastery key to `SaveProfile.DEFAULT_DATA` and `RunSession.mastery`.
4. Add upgrades to `content/upgrade_catalog.gd` and a visual label/icon in `ui/game_ui.gd` if needed.

### Add a permanent augment

1. Add a definition to `content/meta_upgrade_catalog.gd`.
2. Add its rank key to `SaveProfile.DEFAULT_DATA.upgrades`.
3. Consume its named bonus when configuring the relevant runtime system.

## Communication contracts

- Directors request visual/audio feedback with signals.
- `CombatDirector` reports pickups, kills, and weapon damage; `game.gd` commits them to `RunSession`.
- `GameUI` reports user intent; `game.gd` decides whether a state transition is valid.
- Pausing changes process mode for the `run_entities` group, freezing the simulation without freezing the UI.

## Tests

- `tests/smoke.gd` validates menu → run → spawning → level-up → upgrade → weapon flow.
- `tests/catalog_validation.gd` validates content IDs, required fields, and save/catalog consistency.
- `tests/capture_run.gd` stages a deterministic-looking combat frame for visual regression checks.
