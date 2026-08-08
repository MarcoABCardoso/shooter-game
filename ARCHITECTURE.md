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
| `core/run_session.gd` | Time, resonance, Flux, kills, combo, mastery, evolution history | Nodes or presentation |
| `core/behavior_profile.gd` | Rolling movement, range, and target-distribution measurements | Weapons, nodes, or presentation |
| `content/*.gd` | Enemy, weapon, evolution, library, and permanent-upgrade definitions | Runtime state |
| `systems/spawn_director.gd` | Difficulty cadence and spawn requests | Enemy construction |
| `systems/combat_director.gd` | Entity construction, collisions, drops, combat events | Weapon cadence, UI, profile mutation |
| `systems/weapon_system.gd` | Weapon timers, targeting, damage, weapon effects | Drops, behavioral classification |
| `ui/game_ui.gd` | Screens, HUD, and scrollable discovery-gated Arsenal Library projection | Gameplay mutation; it emits intent signals |
| `presentation/arena_view.gd` | Arena, grid, crosshair, screen shake | Rules and entity lifecycle |
| `profile.gd` | Versioned serialization, discovery state, mastery allocation, and profile transactions | Upgrade balance definitions |

## Extension recipes

### Add or tune an enemy

1. Add its values to `content/enemy_catalog.gd`.
2. If it uses an existing movement family and silhouette, no other change is required.
3. For a new behavior, add one isolated behavior branch to `entities/enemy.gd`.
4. Add its availability rule to `EnemyCatalog.choose_standard()` or request it explicitly from `SpawnDirector`.

### Add a behavioral evolution

1. Add or tune a combined profile in `content/evolution_catalog.gd`.
2. Apply its weapon/player mutation in `EvolutionCatalog.apply()`.
3. Keep measurement formulas isolated in `core/behavior_profile.gd`; mutations consume the profile rather than changing how behavior is measured.
4. Add matching player-facing mechanics and acquisition text to `content/library_catalog.gd`.

### Add a new weapon family

1. Add default runtime data and order to `content/weapon_catalog.gd`.
2. Implement its cadence and targeting inside `systems/weapon_system.gd`.
3. Add its mastery XP and allocation keys to `SaveProfile.DEFAULT_DATA` and its run key to `RunSession.mastery`.
4. Add the family to relevant profiles in `content/evolution_catalog.gd` and its HUD label in `ui/game_ui.gd` if needed.

### Add a permanent augment

1. Add a definition to `content/meta_upgrade_catalog.gd`.
2. Add its rank key to `SaveProfile.DEFAULT_DATA.upgrades`.
3. Consume its named bonus when configuring the relevant runtime system.

## Communication contracts

- Directors request visual/audio feedback with signals.
- `CombatDirector` reports kills, direct resonance and Flux, rare repair pickups, and weapon damage; `game.gd` commits them to `RunSession`.
- `GameUI` reports menu intent; `game.gd` decides whether a state transition is valid.
- Mastery ranks enter a profile-owned shared allocation pool at run banking time; the UI requests one-point allocation transactions and combat reads the resulting effective bonus.
- Resonance levels snapshot the live behavioral profile and mutate the build without pausing combat.
- Manual pausing changes process mode for the `run_entities` group, freezing the simulation without freezing the UI.

## Tests

- `tests/smoke.gd` validates menu → run → spawning → resonance → automatic evolution → weapon flow.
- `tests/catalog_validation.gd` validates content IDs, evolution profiles, required fields, and save/catalog consistency.
- `tests/behavior_progression.gd` validates continuous sampling, deliberate profile steering, and mutation application.
- `tests/capture_run.gd` stages a deterministic-looking combat frame for visual regression checks.
- `tests/capture_library.gd` stages the discovery-gated Arsenal Library for visual regression checks.
