# Neon Requiem Design Reference

## How to read this document

This file records the design ideas currently guiding Neon Requiem. It does not
pretend that every behavior already implemented in the prototype is a permanent
product decision.

Entries are divided into four kinds:

- **Creative commitments** define the game being made and should change only
  through an intentional change of direction.
- **Technical contracts** protect the implementation and may evolve when the
  architecture genuinely requires it.
- **Working hypotheses** are promising ideas that must earn their place through
  building and playing them.
- **Prototype history** explains why the current playable build works as it does
  without granting those choices permanent authority.

The longer path from the current build to the intended full game is described in
[`MASTER_PLAN.md`](MASTER_PLAN.md).

## Creative commitments

### C001: Build engineering is the primary fantasy

- **Commitment:** The player deliberately assembles and evolves a ship, then
  moves, targets, and uses active abilities in ways that exploit that build.
  Action skill matters, but building well is the main source of authorship.
- **Why:** Movement in a bullet-heavy arena can otherwise converge toward one
  generally correct style. Distinct equipment rules let different runs ask for
  different behavior.
- **Consequence:** Weapons, active skills, targeting rules, permanent
  progression, and encounters must create recognizable strategies rather than a
  collection of independent percentage bonuses.

### C002: Combat is organized into short sorties and varied operations

- **Commitment:** Concentrated combat missions remain short and intense. Several
  missions with different rhythms may form a larger operation, with decisions or
  recovery between them.
- **Why:** The current gauntlets are engaging because pressure rises quickly.
  Extending the same pressure uniformly would create fatigue rather than depth.
- **Consequence:** Campaign length comes from mission variety, build development,
  routes, and changing combat questions rather than a single long survival timer.

### C003: Important choices are infrequent and transformational

- **Commitment:** Resonance or an equivalent resource automatically improves
  baseline weapon power. The player chooses less often, and important choices
  change behavior, introduce a tradeoff, or commit the operation to a strategy.
  Evolution paths and prerequisites remain visible.
- **Why:** A recurring choice between small damage, rate, and speed bonuses tends
  to have a calculable best answer and interrupts combat without producing a new
  way to play.
- **Consequence:** Generic stat growth belongs in automatic curves or permanent
  progression. Operation choices own weapon identities, interactions, and
  transformations.

### C004: Permanent progression grants power and possibility

- **Commitment:** Progression makes the player numerically stronger and unlocks
  additional build options. The campaign permits a struggling player to gain
  power before returning to a difficult encounter.
- **Why:** Permanent growth is part of the game's accessibility model. Reaching
  the ending should not require high-end reflexes when planning, persistence, and
  a better-equipped profile can provide another route.
- **Consequence:** Power remains bounded enough that build understanding matters.
  Optional routes, Flux skills, intrinsic mastery, and campaign unlocks should
  cooperate rather than become redundant currencies. A complete profile must
  still choose which benefits are active rather than automatically applying
  everything it has ever unlocked.

### C005: Campaign difficulty is not a pure reflex gate

- **Commitment:** Required encounters can be overcome through some combination
  of build knowledge, permanent growth, optional preparation, and execution. No
  mandatory encounter should demand advanced reactions alone.
- **Why:** The intended fantasy is engineering a solution and learning how to
  operate it, not proving mastery of a fixed action moveset.
- **Consequence:** Bosses expose readable vulnerabilities, failure preserves some
  useful progress, and the campaign may become easier as the profile grows.
  Post-game challenges may demand tighter execution.

### C006: Procedural vector identity and combat readability

- **Commitment:** Ships, enemies, projectiles, pickups, arena elements, and
  interface decoration use a cohesive neon vector language. Player threats are
  warm magenta or orange, player offense is cyan or green, collectible resources
  are yellow, and dangerous actions are telegraphed.
- **Why:** The procedural geometry is distinctive, flexible, and well suited to
  readable bullet-heavy combat.
- **Consequence:** Readability beats visual density. The visual identity does not
  forbid authored music, richer sound, external fonts, or a carefully justified
  presentation asset.

### C007: The campaign has a definitive ending and an optional post-game

- **Commitment:** Defeating the final campaign boss resolves the main conflict
  and produces a satisfying ending. Threat levels, challenges, achievements,
  alternate routes, and new build options open beyond it.
- **Why:** The campaign should respect players who want a complete finite game,
  while the build system can support further experimentation for those who stay.
- **Consequence:** Post-game content expands or transforms the game; it does not
  reveal that the campaign ending was merely an unfinished prerequisite.

### C008: Creator-led iteration

- **Commitment:** The project advances through playable increments, direct play,
  taste, and practical judgment. It does not require telemetry, formal test
  cohorts, surveys, feedback forms, or statistical targets.
- **Why:** Neon Requiem is made by a tiny creator-and-AI team, not a product
  organization with a dedicated research operation.
- **Consequence:** Informal outside feedback is welcome but optional. Automated
  tests protect correctness and regressions; they do not determine whether a
  design is fun.

## Technical contracts

### T001: Godot remains the engine

- **Contract:** Godot 4.3 or newer remains the implementation target.
- **Why:** The existing project benefits from Godot's physics, scene lifecycle,
  local persistence, procedural drawing, and export options. Rewriting the engine
  does not advance the current product direction.

### T002: Signal-connected modular architecture

- **Contract:** `scripts/game.gd` remains the composition root and lifecycle
  state machine. Content catalogs, mutable run state, focused systems, entities,
  presentation, and UI retain clear ownership. Cross-system outcomes travel
  through signals wired at the composition root.
- **Why:** The separation already lets content and mechanics change without
  giving every module knowledge of the entire game.
- **Adjust:** Module responsibilities and extension recipes live in
  [`ARCHITECTURE.md`](ARCHITECTURE.md).

### T003: Local, disposable pre-release persistence

- **Contract:** Profile data remains local and supports explicit reset plus safe
  handling of a missing or corrupt save. Backward compatibility is not a
  requirement before release.
- **Why:** The current save belongs to a changing prototype with one known
  player. Preserving obsolete progression would constrain the new campaign for
  no meaningful benefit.
- **Consequence:** An incompatible schema change may replace the profile defaults
  and discard all existing progress without migration or repair logic for older
  formats.
- **Adjust:** Current save ownership lives in `scripts/profile.gd`.

### T004: Simulation-level pause

- **Contract:** Pausing, modal operation decisions, and terminal combat states
  freeze the complete simulation while required UI remains responsive.
- **Why:** Freezing only the player creates hidden enemy, projectile, pickup, and
  timer drift.
- **Adjust:** Simulation entities remain coordinated through the `run_entities`
  group or a replacement with the same whole-simulation guarantee.

## Working hypotheses

These ideas guide the next playable work but are not commitments merely because
they are written here.

### H001: Three-mission operations

An operation will likely contain about three short missions and last roughly
10-15 minutes including intermissions. Failure preserves partial rewards and may
allow a retry, retreat, or operation restart depending on the mission.

Candidate mission families are Assault, Elite Hunt, Signal Defense, Breach,
Salvage, Anomaly, and Boss. A family survives only if it makes builds prioritize,
move, or target differently.

The first operation-spine play confirmed that escalation and pauses are useful,
but three back-to-back Assault encounters still feel like one repeated
kite-and-fire problem and are too intense for an opener. The current comparison
uses a short, lower-pressure Signal Defense opener. Intermissions fully repair
hull and preserve operation upgrades. Voluntary retreat recovers 75% of Flux
versus 50% after defeat, with mastery banked in both cases.

The Evolution and control play confirmed Signal Defense as a strong change of
pace, but also made the two following Assault missions feel indistinguishable.
The opener was the first objective prototype, not an intended one-off. The next
slice gives missions two and three their own immediately legible objectives so
the operation contains three actual rhythms rather than one objective followed
by two survival timers.

Operations are the sole deployment structure. The selectable prototype route and
its scalar upgrade loop have been removed rather than retained as a second mode.

### H002: Automatic targeting with optional added agency

Automatic targeting remains the baseline. Direct play found three cyclic modes
awkward and found no useful case for Highest Health while clearing more small
enemies is always safer. The next comparison switches only between Nearest and
Ranged Threats, with a prominent persistent cue instead of continuous aim.

The keyboard-and-mouse comparison confirmed that Ranged Threats can prioritize a
Gunner while nearer enemies compete for automatic targeting. Touch and controller
mappings follow only if the simpler two-mode control survives its next comparison.

Future targeting doctrines such as lowest health, densest cluster, or a
persistent marked target must first demonstrate a tactical case the baseline
modes do not cover.

### H003: Chassis or doctrines

A small chassis or doctrine layer may create broad loadout rules, such as one
amplified weapon, two balanced weapons, or three weaker weapons. It should be
omitted if it becomes another menu of minor stat bonuses or duplicates the skill
tree.

The implemented first behavior target is a Sentinel build that finds a safe
position and accumulates damage, knockback, or range while remaining nearly
stationary. Direct play validated the tension but rejected an all-or-nothing
reset. Movement should spend stored charge in proportion to displacement, so a
small correction costs some power and settling down resumes charging without the
full startup delay. Phase Mooring should preserve charge through Phase Dash;
directional input must not clear it before the ability activates.

Its implemented foil is a short-range, auto-targeting scatter weapon whose damage
requires constant kiting and aggressive spacing. These builds should be
describable through their positioning behavior, not their damage percentages.
Direct play found both styles equally interesting but Scatter substantially more
powerful, so their output should move toward parity without erasing Scatter's
close-range movement advantage. The strong desire to try another build validates
further build work once the operation has more than one meaningful mission
rhythm. Build-specific achievements may reinforce identity; permanent Flux
advantages require caution because they can make one style the mandatory farm.

### H004: Authored music and restrained narrative

Representative authored music, richer sound, and reactive boss layers should be
explored because they may substantially elevate the neon arcade identity.

Narrative begins with a clear conflict, short transmissions, focused voices or
signals, connected Library entries, recognizable boss identities, and a
definitive ending. A large cast, extensive voice acting, and a high-volume event
system are not assumed.

### H005: Working content range

The current planning range is three sectors, six to eight weapons, four active
skills, two or three chassis or doctrine families, eight to twelve regular enemy
behaviors, three major bosses, and five to seven mission families.

These are boundaries for thinking, not quotas. Content earns its place through
distinct behavior and manageable interaction cost.

### H006: Threat levels expand danger and power together

Post-game threats may add enemy traits, boss variations, arena complications,
and increased rewards while also opening new transformations, doctrines, or
other player power. The post-game should not become the same encounters with
larger health values and stricter reflex requirements.

## Prototype decision history

The original decisions below explain the current playable build. Their IDs are
preserved so code, tests, and earlier discussion remain understandable.

| Original decision | Current disposition | Historical value |
|---|---|---|
| **D001: Five finite stages in one bounded arena** | Superseded | Produced a legible compact campaign and proved that the Overseer works as a finite milestone. The full game moves to sectors, operations, mission variety, and multiple arenas. |
| **D002: Deliberate hangar builds plus persistent growth** | Reframed as C001, C003, and C004 | Correctly identified tactical authorship as the missing layer. Frequent exhaustive scalar resonance choices are now considered a prototype weakness. |
| **D003: Movement and active skill are the only combat inputs** | Reopened as H002 | Auto-targeting prevented control overload and remains the baseline. Additional targeting agency is now worth exploring without committing to manual aim. |
| **D004: Unlockable weapon loadouts** | Partially retained | Progressive equipment discovery remains useful. The exact Pulse, Orbit, Stage 1, Stage 5, and second-slot schedule is prototype content. |
| **D005: Neon vector geometry only** | Reframed as C006 | Procedural vector visuals remain central. Treating the absence of all imported presentation assets as a product requirement was unnecessarily broad. |
| **D006: Readability beats visual density** | Retained in C006 | This remains a core encounter and presentation principle. |
| **D007: Tutorial-clearable first stage** | Principle retained in C005 | The opening campaign route should not require grinding. The exact 55-second Drone roster is prototype balance. |
| **D008: Local, forward-compatible persistence** | Superseded by T003 | Local storage and reset remain useful, but prototype saves are now explicitly disposable and need no migration path. |
| **D009: Godot retained after Phaser review** | Retained as T001 | The engine question is closed unless a future distribution requirement fundamentally changes. |
| **D010: Minimal procedural sound** | Reopened as H004 | Runtime tones proved the feedback loop. They are not a permanent restriction on music or sound production. |
| **D011: Signal-connected modular architecture** | Retained as T002 | The refactor remains the correct foundation for larger mission and build systems. |
| **D012: Simulation-level pause** | Retained as T004 | The current resonance overlay may change, but whole-simulation pause remains correct. |
| **D013: Native item mastery** | Expanded by C004 | Intrinsic, non-transferable mastery remains valuable. It may unlock transformations and interactions as well as bounded power. |
| **D014: Bosses interrupt the crowd-control rhythm** | Principle retained | Bosses should create readable exploitation windows and test build understanding. The Overseer's exact attacks remain authored prototype content. |
| **D015: Sparse equipment rewards plus first-clear Flux** | Reopened | Memorable unlocks remain desirable. The exact reward schedule and first-clear formula must be redesigned for operations and a larger campaign. |

## Current prototype balance reference

These values describe the playable Signal Breach slice. They are tuning
references, not targets for the future campaign.

| System | Current starting value | Current growth |
|---|---:|---:|
| Player hull | 100 | Behavioral mutations; +12 permanent rank |
| Player speed | 300 px/s | Fixed; movement physics are unaffected by facing and targeting |
| Pulse Cannon | 5 damage / 0.34 s / 190 px range | Skill tree + 2.5% per native mastery rank |
| Signal Defense | 18 s hold objective | Drone pressure; leaving the field decays progress |
| Striker Screen | 75 s Assault | Introduces Strikers after the opener |
| Gunner Lock | 68 s Assault | Adds Gunners and timed elite pressure |
| Phase Dash | 0.18 s movement, 0.30 s invulnerability | 1.25 s cooldown |

Current tuning locations remain:

- Encounter rosters, durations, health, and pressure:
  `scripts/content/encounter_catalog.gd`
- Enemy base values: `scripts/content/enemy_catalog.gd`
- Weapon base values: `scripts/content/weapon_catalog.gd`
- Operation transformations: `scripts/content/operation_evolution_catalog.gd`
- Permanent graph content: `scripts/content/skill_tree_catalog.gd`
- Profile mastery curves and unlock transactions: `scripts/profile.gd`
- Boss behavior and vector presentation: `scripts/entities/enemy.gd`

## Current playable scope

The prototype currently includes:

- A title screen, hangar, discovery-gated Arsenal Library, and save reset.
- A three-mission Signal Breach operation spine with intermissions and partial
  reward recovery. It opens with objective-driven Signal Defense, then advances
  through two escalating Assault missions.
- Automatic resonance growth, two visible Pulse evolution tiers,
  Sentinel and Scatter positioning builds, and keyboard target-priority cycling.
- Weapon and active-skill loadouts, a Flux skill graph with free respec, native
  mastery, four implemented weapon families, a combo multiplier, pickups, pause,
  and feedback.
- Keyboard and single-stick touch movement.

This is evidence that the compact loop works. It is raw material for the opening
sector, not a promise that every current mission, reward, duration, or menu
survives unchanged.

## Intentionally open questions

- Final release platforms, storefronts, pricing, and distribution.
- The final targeting and aiming control model.
- Whether chassis or doctrines justify their complexity.
- The exact campaign map and operation failure rules.
- The final quantity of weapons, skills, enemies, arenas, and threat levels.
- The extent of authored narrative, music, voice, and external presentation
  assets.
- Gamepad support, subject to eventual platform and control decisions.
- Optional score modes and offline or online leaderboards.

Online multiplayer, cooperative play, competitive infrastructure, fully
procedural campaigns, endless permanent-stat scaling, a large voiced cast,
user-generated content, and hundreds of interchangeable items are outside the
critical path described by the master plan.
