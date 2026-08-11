# AGENTS.md

This file applies to the entire repository. It describes how automated coding agents should work on Neon Requiem.

## Project overview

Neon Requiem is a Godot 4.3+ top-down bullet hell written in typed GDScript. The project intentionally uses procedural vector drawing for visuals, signal-connected modules, plain dictionary catalogs for content, and disposable local JSON save data during pre-release development.

Before making a non-trivial change, read:

- `README.md` for player-facing behavior and validation commands.
- `ARCHITECTURE.md` for module ownership, dependency direction, and extension recipes.
- `DESIGN_DECISIONS.md` for gameplay contracts and tuning locations.

Treat those documents as active design constraints. Update them when a change intentionally alters the documented architecture or product behavior.

## Architecture rules

- Keep `scripts/game.gd` as the composition root and lifecycle state machine. It wires dependencies and translates module signals into state changes.
- Put immutable definitions and balance data in `scripts/content/`. Catalogs must not depend on runtime systems, UI, or scene-tree state.
- Put mutable per-run values in `scripts/core/run_session.gd`. Keep it independent of nodes and presentation.
- Put spawning, combat orchestration, and weapon behavior in `scripts/systems/` according to the ownership table in `ARCHITECTURE.md`.
- Keep entity-local movement, collision, drawing, and attack behavior in `scripts/entities/`.
- Keep world rendering in `scripts/presentation/` and interface rendering in `scripts/ui/`.
- Keep `scripts/ui/game_ui.gd` as the controller-facing UI facade. Delegate focused presentation to child views such as `RunHud`, `OverlayView`, `StageGraphView`, and `SkillTreeView`.
- Communicate across systems with signals wired at the composition root. Do not give modules a reference to `game.gd` or make them reach into unrelated modules.
- Avoid duplicating catalog data, unlock policy, balance values, or save defaults in presentation code.

Dependencies should continue to point from composition toward focused modules:

```text
game.gd
├── core/
├── content/
├── systems/
├── presentation/
├── ui/
└── entities/
```

## Implementation conventions

- Use typed GDScript for parameters, return values, signals, and collections where practical.
- Prefer small, cohesive functions and explicit names over comments that restate the code.
- Preserve existing public signals and facade methods unless the task explicitly calls for an API change.
- Use `preload("res://...")` for required script dependencies and existing `class_name` types where that improves clarity.
- Use `UIFactory` for interface controls that should match the established visual language.
- Keep gameplay visuals asset-free and built from Godot primitives unless a design decision explicitly changes that constraint.
- Put tunable values in the owning catalog or balance module rather than scattering literals through runtime code.
- Keep deterministic run-upgrade behavior deterministic; do not introduce random offerings without changing the design contract.
- Preserve simulation-level pausing through the `run_entities` group. UI needed during pause must remain responsive.
- Do not hand-edit generated `.uid`, `.import`, or `.godot/` cache contents. If Godot generates a required `.uid` for a new tracked script, include it without modifying its value.

## Persistence and progression

- Pre-release saves are disposable. Schema changes may replace defaults and reset all existing progress without backward-compatible migration or repair logic for older formats.
- Continue handling a missing or corrupt current-format save safely and preserve explicit reset support.
- Keep permanent profile state separate from `RunSession` state.
- Flux transactions, unlocks, loadout changes, skill purchases, and mastery banking belong to `SaveProfile`.
- When adding content with persistent state, update the relevant catalog, profile defaults, and catalog-validation tests together.
- Preserve lossless skill respec and intrinsic, non-transferable item mastery unless the requested design explicitly changes them.

## Testing

Run the narrowest relevant test while iterating, then run the full suite for changes that cross module boundaries, touch shared catalogs, alter progression, or modify `game.gd`/`game_ui.gd`.

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

If the executable is named `godot4`, substitute that command name. Do not encode a local executable path in repository files.

Testing expectations:

- Add or update regression coverage for behavior changes.
- Extend `catalog_validation.gd` when adding catalog entries, effect families, stages, mastery keys, or persistent identifiers.
- Use `smoke.gd` for end-to-end lifecycle and integration contracts, not exhaustive per-module cases.
- Keep tests deterministic and independent of a pre-existing local save.
- Treat capture scripts under `tests/capture_*.gd` as visual-review helpers, not substitutes for assertions.

## Change discipline

- Inspect the current working tree before editing and preserve unrelated user changes.
- Prefer focused, behavior-preserving refactors. Avoid mixing broad renames or formatting churn with functional changes.
- Search for every identifier before changing a signal, save key, catalog ID, node name used by tests, or public method.
- Update documentation and tests in the same change when their contracts move.
- Never commit local saves, editor caches, logs, captures, machine-specific paths, credentials, or personal environment details.

## Definition of done

A change is complete when:

1. Ownership and dependency direction remain clear.
2. Player-visible behavior matches the request and documented design.
3. Relevant regression coverage exists and passes.
4. The full suite passes when shared contracts were touched.
5. `git diff --check` reports no whitespace errors.
6. The final diff contains no unrelated or machine-specific changes.
