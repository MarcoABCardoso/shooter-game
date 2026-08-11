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

### C002: Combat is organized into short, focused stages

- **Commitment:** A stage presents one legible strategic thesis and gives the
  player its objective, arena rule, and important threats before deployment.
  Different objective families are separate stages with a hangar/build decision
  between them. Multi-part stages deepen the same thesis rather than changing
  the exam after the build is locked.
- **Why:** The current gauntlets are engaging because pressure rises quickly.
  Direct play also showed that chaining unrelated objectives rewards generic
  survival builds over engineering for a known problem.
- **Consequence:** Campaign variety comes from distinct stages and routes. A
  mixed-objective gauntlet is an explicitly advertised optional challenge, not
  the default campaign container.

### C003: Important choices are infrequent and transformational

- **Commitment:** Resonance or an equivalent resource automatically improves
  baseline weapon power. The player chooses less often, and important choices
  change behavior, introduce a tradeoff, or commit the stage to a strategy.
  Evolution paths and prerequisites remain visible.
- **Why:** A recurring choice between small damage, rate, and speed bonuses tends
  to have a calculable best answer and interrupts combat without producing a new
  way to play.
- **Consequence:** Generic stat growth belongs in automatic curves or permanent
  progression. Stage choices own weapon identities, interactions, and
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

- **Contract:** Pausing, modal stage decisions, and terminal combat states
  freeze the complete simulation while required UI remains responsive.
- **Why:** Freezing only the player creates hidden enemy, projectile, pickup, and
  timer drift.
- **Adjust:** Simulation entities remain coordinated through the `run_entities`
  group or a replacement with the same whole-simulation guarantee.

## Working hypotheses

These ideas guide the next playable work but are not commitments merely because
they are written here.

### H001: Focused stages and reusable objectives

The three-mission operation hypothesis is rejected for the default campaign.
Chapter 1 play proved Signal Defense, Relay Breach, and the Overseer individually,
but chaining them locked an optimized build before forcing it through unrelated
challenges. The current slice exposes them as separate hangar deployments so the
player can inspect a problem, configure for it, and bank that stage independently.

Candidate mission families are Assault, Elite Hunt, Signal Defense, Breach,
Salvage, Anomaly, and Boss. A family survives only if it makes builds prioritize,
move, or target differently.

Every stage needs content-defined time pressure with a visible countdown.
Pressure prevents safe objective missions from becoming farming spaces and asks
the player to execute the build rather than wait for more rewards. The first
comparison uses generous deadlines appropriate to opening stages.

Objective mechanics are reusable vocabulary, not fixed stage templates. Future
stages should compose objectives, placements, encounter profiles, and arena
rules in new combinations; repeating one obstacle layout with more health and
more enemies does not count as new level design.

A stage may contain several waves, spaces, or phases when each elaborates the
same strategic question. The sector route supplies larger-scale continuity while
the hangar between stages preserves deliberate specialization.

### H002: Automatic targeting with optional added agency

Automatic targeting remains the baseline. Direct play found three cyclic modes
awkward and found no useful case for Highest Health while clearing more small
enemies is always safer. The integration slice now toggles only between Nearest
and Ranged Threats, with a prominent persistent cue instead of continuous aim.

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
reset. Movement now spends stored charge in proportion to displacement, so a
small correction costs some power and settling down resumes charging without the
full startup delay. Phase Mooring preserves charge through Phase Dash.

Its implemented foil is a short-range, auto-targeting scatter weapon whose damage
requires constant kiting and aggressive spacing. These builds should be
describable through their positioning behavior, not their damage percentages.
Direct play found both styles equally interesting but Scatter substantially more
powerful, so the integration tuning reduces its pellet damage and movement cadence
advantage without erasing its close-range identity. Direct play found Bastion
and Scatter balanced through different strengths. Sentinel plus Vector Parry
felt intentional and powerful, especially when returning concentrated Overseer
fire; Parry retains the same timing-and-payoff rhythm as Dash while producing a
meaningfully different use. All tested configurations were fun enough to invite
immediate comparison. Build-specific achievements may reinforce identity; permanent Flux
advantages require caution because they can make one style the mandatory farm.

### H004: Authored music and restrained narrative

Signal Defense, Relay Breach, and the Overseer handoff compare two authored
combat tracks, a boss layer, procedural action tones, and mission transmissions.
Direct play found the music adequate polish rather than a defining strength. The
chained prototype's clear cue was too large for an ordinary intermission; the
focused-stage model removes that transition entirely. Explanatory transmissions
and Parry result banners also narrated outcomes already clear on screen. Cues
should be reserved for information or atmosphere the action does not communicate.

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
| **D001: Five finite stages in one bounded arena** | Partially reframed by C002 | Finite stages and hangar reconfiguration correctly support build specialization. The exact count and single-arena campaign remain prototype history. |
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
| **D015: Sparse equipment rewards plus first-clear Flux** | Reopened | Memorable unlocks remain desirable. The exact reward schedule and first-clear formula must be redesigned for stages and a larger campaign. |

## Current prototype balance reference

These values describe the playable Chapter 1 stage slice. They are tuning
references, not targets for the future campaign.

| System | Current starting value | Current growth |
|---|---:|---:|
| Player hull | 100 | Behavioral mutations; +12 permanent rank |
| Player speed | 300 px/s | Fixed; movement physics are unaffected by facing and targeting |
| Pulse Cannon | 5 damage / 0.34 s / 190 px range | Skill tree + 2.5% per native mastery rank |
| Signal Defense | 18 s hold objective | Drone pressure; leaving the field decays progress |
| Relay Breach | 80 s deadline | Three linked targets under Drone/Striker pressure |
| Overseer Lock | 105 s deadline | Gunner screen followed by the multi-pattern boss |
| Phase Dash | 0.18 s movement, 0.30 s invulnerability | 1.25 s cooldown |

Current tuning locations remain:

- Encounter rosters, durations, health, and pressure:
  `scripts/content/encounter_catalog.gd`
- Enemy base values: `scripts/content/enemy_catalog.gd`
- Weapon base values: `scripts/content/weapon_catalog.gd`
- Stage transformations: `scripts/content/operation_evolution_catalog.gd`
- Permanent graph content: `scripts/content/skill_tree_catalog.gd`
- Profile mastery curves and unlock transactions: `scripts/profile.gd`
- Boss behavior and vector presentation: `scripts/entities/enemy.gd`

## Current playable scope

The prototype currently includes:

- A title screen, hangar, discovery-gated Arsenal Library, and save reset.
- Three independently selectable stages with partial retreat/defeat recovery:
  objective-driven Signal Hold, a linked Relay Breach, and Overseer Lock. Each
  returns to the hangar before another deployment.
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
- The exact campaign map, route rules, and stage failure rules.
- The final quantity of weapons, skills, enemies, arenas, and threat levels.
- The extent of authored narrative, music, voice, and external presentation
  assets.
- Gamepad support, subject to eventual platform and control decisions.
- Optional score modes and offline or online leaderboards.

Online multiplayer, cooperative play, competitive infrastructure, fully
procedural campaigns, endless permanent-stat scaling, a large voiced cast,
user-generated content, and hundreds of interchangeable items are outside the
critical path described by the master plan.
