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

### C002: Combat is organized into focused missions

- **Commitment:** A deployment presents one legible strategic thesis through the
  arena, objectives, and threats encountered during it. Objectives may arrive
  sequentially or in small active groups so the player advances through a
  mission instead of clearing one short activity. The hangar remains a quiet
  preparation screen: mission name, deadline, and disabled-state gating are
  enough. Different objective families remain separate deployments with a
  hangar/build decision between them; multi-part missions deepen the same thesis
  rather than changing the exam after the build is locked.
- **Why:** The current gauntlets are engaging because pressure rises quickly.
  Direct play also showed that chaining unrelated objectives rewards generic
  survival builds over engineering for a known problem.
- **Consequence:** Campaign variety comes from distinct missions and routes.
  Longer missions earn their duration through progression, changing placement,
  and escalating objective groups rather than a longer survival timer. A
  mixed-family gauntlet is an explicitly advertised optional challenge, not the
  default campaign container.

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

The Chapter 2 play confirmed the separate deployments but rejected their flat
menu as campaign structure. Drift Cache looked like a peer in the required
sequence, and clearing four buttons did not make the activities feel cumulative.
The implemented comparison shows Signal Hold, Relay Breach, and Overseer Lock as
one main chain, places Drift Cache visibly off that chain, and lets each clear
change node and link state. The next play determines whether this route state and
the existing completion consequences create enough continuity without a restored
mission dossier or isolated dialogue.

The route revision read better, but the single-objective deployments ended
before they could develop into missions. The first traversal comparison gave
Signal Hold three moving defense objectives, Drift Cache an approach and
extraction, and Relay Breach three progressively revealed relay pairs. Direct
Chapter 3 review later simplified the teaching order: Signal Hold is now a
one-minute fixed-arena survival stage, so the player first learns movement,
automatic combat, and avoiding damage. Drift Cache introduces Signal Defense
through its approach and extraction fields; Relay Breach then introduces three
progressively revealed relay pairs. The hangar decision remains between each
focused family.

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

Chapter 3 does not add a chassis layer. Weapon-specific transformations already
create the broad movement and targeting rules that a chassis would currently
duplicate. The comparison set instead names eight plans: Sentinel and Harrier,
Interceptor and Aegis, Conduit and Executioner, and Singularity and Purifier.
This decision can be reopened only if a later loadout rule spans weapons in a way
their transformations and permanent graph cannot express.

### H004: Authored music and restrained narrative

Signal Defense, Relay Breach, and the Overseer handoff compare two authored
combat tracks, a boss layer, and procedural action tones. The prototype also
compared mission transmissions, but the Chapter 2 play found a lone Vela line
floating in the HUD without enough narrative structure to justify itself.
Direct play found the music adequate polish rather than a defining strength. The
chained prototype's clear cue was too large for an ordinary intermission; the
focused-stage model removes that transition entirely. Explanatory transmissions
and Parry result banners also narrated outcomes already clear on screen. Cues
should be reserved for information or atmosphere the action does not communicate.

Mission dialogue is deferred until it can establish a voice, context, and a
presentation language rather than appearing as isolated HUD copy. Narrative may
later begin with a clear conflict, focused voices or signals, connected Library
entries, recognizable boss identities, and a definitive ending. A large cast,
extensive voice acting, and a high-volume event system are not assumed.

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

### H007: Permanent upgrades need perceptible tactical value

The Chapter 2 play found projectile speed and projectile size largely irrelevant
under automatic aiming. A modifier can function correctly and still fail as a
choice when the player cannot feel a changed decision, reliability threshold, or
combat role. Chapter 3 should audit the permanent tree for these numerical dead
ends and replace them with benefits that visibly support a build identity.

The Chapter 3 candidate removes projectile speed and size from the permanent
graph. Their replacements change thresholds the player can plan around: Ranged
Threats reach, Pulse piercing, Arc jump count and reach, Orbit blade count and
projectile interception. Generic damage remains only where permanent power is
the explicit purpose; deeper branches now reinforce a named behavior.

Native mastery now reveals the second tier-two follow-up for each named weapon
plan. This keeps mastery intrinsic while making revisitation open a choice rather
than only increasing damage. The Arsenal Library exposes every discovered plan
and its tactical use before deployment.

The first Chapter 3 creator play validates the breadth: the starter quantity is
comfortable, Pulse/Orbit/Arc feel different, Gravity Tether is useful and unique,
optional Parry matters because it answers the boss, and Nova is an interesting
sector reward. Arc plus Gravity Tether is the first preferred configuration.
The same play rejects the initial baseline identities of Pulse and Dash and finds
equipment unlocks too easy to miss. The revision gives Pulse a same-target Focus
ramp, lets Dash cut a damaging projectile-clearing lane, and presents deterministic
equipment rewards on a dedicated reveal. Tether impulses now reserve braking
distance for both the pull and continued enemy pursuit so fast enemies converge
without being launched through the player. First-hangar discoverability remains
deferred tutorial work rather than a Chapter 3 build-system change.

The final Chapter 3 presentation pass keeps evolution cards and victory results
deliberately terse. Result screens do not explain persistence transactions the
player does not need to decide, and successful stages return through the hangar
instead of advertising an unusual immediate replay. Stage teardown also clears
transient player and weapon visuals so a prior loadout cannot remain on the
battlefield behind the result or the next deployment.

### H008: Onboarding follows stable structure

System unlock timing felt correct to the creator, but discoverability remains
unproven because the creator already knew where Loadout, Skill Tree, targeting,
and evolution controls lived. Add restrained first-unlock guidance after the
sector route stabilizes. Defer a larger tutorial system until the game structure
and final input presentation justify it.

### H009: Spatial travel should earn a larger arena

The creator expects forward travel to make sequential objectives feel more like
a mission than flying one or two seconds across a ring. The implemented
comparison places objectives in horizontally separated combat chambers. A
chamber constrains the gauntlet while active and uses a fixed camera. Clearing it
plays a visible completion pulse, opens a narrow corridor, and preserves enemy
pressure. Transit uses a smoothed horizontal dead zone instead of gluing the
camera to every player correction. The next objective appears on arrival. Only
final mission completion clears hostile fire and disperses enemies during a
short outro before the result screen.

This camera split is an evidence-informed design inference, not a claim that one
camera algorithm prevents motion sickness for every player. [Microsoft's camera
accessibility guidance](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/117)
recommends avoiding unnecessary camera motion and making automatic movement
adjustable; [Unity's accessibility example](https://learn.unity.com/course/design-and-development/tutorial/camera-system?version=2022.3)
defaults to static framing because excess movement can be uncomfortable, and
warns that fast movement can disorient. The current comparison therefore
minimizes scrolling during combat and avoids exact player lock during transit. A
reduced-motion camera option remains finishing work if scrolling survives direct
play.

The refined traversal play confirmed the structure: the fixed chambers,
pressure-preserving corridors, completion beat, and final evacuation scan as a
true game slice. Further camera tuning, reduced-motion options, and richer
transition presentation are finish work rather than blockers on build breadth.

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
| **D015: Sparse equipment rewards plus first-clear Flux** | Active opening-sector hypothesis | Null Meridian now uses deterministic, non-repeating first-clear Flux. A new profile can immediately engineer around Pulse, Orbit, Arc, Dash, or Gravity Tether; Drift Cache grants Vector Parry and enough Flux for meaningful permanent growth; the Overseer grants the advanced Nova Burst. The exact later-campaign schedule remains open. |

## Current prototype balance reference

These values describe the playable Chapter 2 opening-sector candidate. They are
tuning references, not targets for later sectors.

| System | Current starting value | Current growth |
|---|---:|---:|
| Player hull | 100 | Behavioral mutations; +12 permanent rank |
| Player speed | 300 px/s | Fixed; movement physics are unaffected by facing and targeting |
| Pulse Cannon | 5 damage / 0.34 s / 190 px range | Skill tree + 2.5% per native mastery rank |
| Signal Hold | 60 s survival timer | One fixed arena under fresh-profile Drone pressure; no objective vocabulary |
| Drift Cache | 22 s approach + 26 s extraction / 165 s deadline | First Signal Defense lesson; Striker/Gunner pressure, 100 first-clear Flux, and Vector Parry |
| Relay Breach | 210 s deadline | Three sequential pairs progress across the arena under Drone/Striker pressure |
| Overseer Lock | 180 s deadline | Gunner/Carrier screen followed by the multi-pattern boss; Nova unlocks on the first clear |
| Phase Dash | 0.36 s movement, 0.46 s invulnerability, 12-damage clearing lane | 2.5 s cooldown |

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

The playable opening-sector candidate currently includes:

- A title screen, hangar, discovery-gated Arsenal Library, and save reset.
- A gated Null Meridian route with partial retreat/defeat recovery: the required
  Signal Hold opener, optional Drift Cache power route, linked Relay Breach, and
  Overseer Lock. Each returns to the hangar before another deployment.
- A one-minute fixed-arena survival opener followed by content-defined objective
  sequences in Drift Cache and Relay Breach. The HUD shows only the survival
  timer or active objective step; one overall deadline governs each deployment.
- Horizontal objective-mission traversal between constrained combat chambers. Completing
  an objective opens a narrow corridor while enemies and spawning continue, then
  activates the next chamber only after the player reaches it. The camera is
  fixed for chamber combat and uses a horizontal dead zone during transit.
- Animated objective completion and a final mission outro. Intermediate
  objectives pulse before travel; final completion clears hostile fire and
  disperses enemies before the result screen appears.
- A minimal hangar: stage buttons show only name and deadline, campaign gates use
  the disabled state, and mission concepts are introduced by the mission itself.
- A content-driven sector route that places the required stage spine and optional
  preparation branch spatially, with completed nodes and links changing state.
- A starter build arsenal containing Pulse, Orbit, Arc, Dash, and Gravity Tether;
  deterministic first-clear Flux; optional Vector Parry recovery; a Nova sector
  reward; and a compact sector-completion beat pointing deeper.
- Automatic resonance growth, two visible Pulse evolution tiers,
  Sentinel and Scatter positioning builds, and keyboard target-priority cycling.
- Weapon and active-skill loadouts, eight named weapon plans with mastery-revealed
  follow-ups, a behavior-first Flux graph with free respec, native mastery, four
  implemented weapon families, three active skills, a combo multiplier, pickups,
  pause, and feedback.
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
