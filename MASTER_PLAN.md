# Neon Requiem Master Plan

## Project tracking

This section is the handoff point between work sessions. Read it before starting
implementation and update it before ending a session that changes the game or
the plan.

- **Overall status:** Chapter 1 and its mandatory integration play are complete;
  the feedback revision is implemented and validated. Chapter 2 is ready.
- **Active chapter:** Chapter 2 - Rebuild the opening sector (not started).
- **Working branch:** `codex/master-plan`
- **Last updated:** 2026-08-11

| Chapter | Status | Playable outcome |
|---|---|---|
| 1. Prove focused stages | Complete | Three focused stages and distinct builds worth optimizing for them |
| 2. Rebuild the opening sector | Not started | A compact but complete first sector using the full-game structure |
| 3. Establish build breadth | Not started | Multiple behaviorally distinct builds worth revisiting |
| 4. Complete the campaign | Not started | Three-sector campaign, final stage, and definitive ending |
| 5. Open the post-game | Not started | Threats and challenges that transform the campaign |
| 6. Finish the product | Not started | Coherent, reliable release candidate for the chosen platforms |

### Current handoff

- **Last completed:** Completed the mandatory Chapter 1 integration play across
  all configurations. Hold, Breach, and Boss felt genuinely different and all
  three builds were fun; Bastion and Scatter felt balanced, while Sentinel plus
  Vector Parry made concentrated boss fire especially satisfying. Target modes,
  displacement-spent charge, and the level-5 breakpoint worked. The play asked
  for visible anti-farming deadlines, less explanatory UI/audio, and composable
  objective layouts rather than repeated fixed stages. The revision adds mission
  timers, preserves Sentinel charge when a follow-up evolution opens, shortens
  transmissions, and removes the redundant Parry banner. A final design review
  rejected the back-to-back container: Signal Hold, Relay Breach, and Overseer
  Lock are now separate hangar deployments, so the player can optimize between
  known challenges and bank each stage independently.
- **In progress:** None. Chapter 2 has not started.
- **Next action:** Begin Chapter 2 from the proven stage vocabulary. Rebuild
  the opening sector with content-driven combinations of objectives, placements,
  encounters, and arena rules; do not multiply the current exact layouts.
- **Blockers:** None. The Chapter 1 integration play gate is complete.
- **Verification:** All nine Godot tests pass after the focused-stage adjustment,
  sequentially with explicit waits and exit-code checks on Godot 4.7.1.
  `git diff --check` passes. Known
  ObjectDB/resource-leak warnings remain visible on some clean exits.

### Active checklist: Chapter 1

- [x] Record the creator's current-playable baseline: what must survive, what has
  become weak, and what the first new build should prove.
- [x] Map deployment, reward, pause, and UI lifecycle to focused stages with
  partial-reward failure or retreat.
- [x] Define the smallest content-driven objective data needed by three real
  stages; avoid a universal mission framework.
- [x] Expose Hold, Breach, and Boss as separate hangar deployments with fresh
  run state and build reconfiguration between them.
- [x] Give the slice at least three stage rhythms, one new arena rule, and
  a miniboss or substantial boss variation.
- [x] Replace frequent scalar resonance prompts with automatic growth and a
  small, visible transformational evolution tree.
- [x] Support two builds that demand noticeably different positioning or
  targeting behavior.
- [x] Add one authored interaction between weapons, an active skill, or a
  doctrine.
- [x] Play the three cyclic target-priority modes under pressure. Keep Nearest
  and Ranged Threats; remove Highest Health and add a stronger mode cue.
- [x] Replace binary Sentinel reset with displacement-based charge drain and
  make Phase Mooring preserve charge through Dash input.
- [x] Rebalance Scatter toward Bastion without removing its close-range movement
  advantage, and move the second evolution breakpoint later in the stage.
- [x] Add one further behaviorally distinct build tied to a new mission rhythm.
- [x] Add representative music, sound, and restrained narrative framing.
- [x] Play the complete slice with both builds and record the honest design
  judgment in this handoff section.
- [x] Complete the Chapter 1 integration play with tuned Bastion, tuned Scatter,
  and Vector Parry; record whether the three objective rhythms distinguish them.

### Recorded direction after the Chapter 1 integration play

- The objectives survived the playtest; the back-to-back operation did not.
  Locking one optimized build before three unrelated challenges contradicted the
  build-engineering fantasy. Hold, Breach, and Boss are separate stages with a
  hangar decision between them. A multi-part stage must deepen one strategic
  thesis unless it explicitly advertises a generalist gauntlet.
- Signal Defense, Relay Breach, and the Overseer are three distinct modes worth
  keeping. Future levels should recombine objective mechanics, placements,
  encounters, and arena rules rather than repeat a fixed obstacle arrangement
  with increased health or enemy density.
- Every stage needs visible time pressure. Generous opening-stage deadlines
  should prevent farming without turning the first boss into a reflex gate.
- Bastion and Scatter now feel balanced through different strengths. Sentinel
  charge is readable and forgiving after the displacement change.
- Sentinel plus Vector Parry felt intentional and powerful. Returning the
  Overseer's concentrated fire was the strongest authored interaction in the
  slice. Parry shares Dash's timing-and-payoff feel but has a distinct use.
- Phase Mooring felt unreliable because selecting the level-5 follow-up cleared
  the accumulated charge it was meant to preserve. Follow-up evolution selection
  must not reset the Sentinel reserve.
- Nearest/Ranged Threats and the later second breakpoint both worked.
- The Overseer is appropriately readable and balanced for a first boss; a
  mission deadline supplies pressure without removing its observation window.
- Music adds finish but is not yet exceptional. Transmissions and HUD feedback must trust
  visible action and never explain the obvious.
- Every tested configuration was fun enough that the creator wanted to try all
  of them. Chapter 1's core playable outcome is proven.

### Recorded direction after the Operation spine play

- This section records the superseded chained-operation experiment. The later
  Chapter 1 decision keeps its objective and reward evidence but rejects its
  back-to-back container.
- Operations replace the selectable route as the campaign structure. Signal
  Breach is now the sole deployment flow; obsolete progression and tests were
  removed without a compatibility layer.
- The current mission experiment is a short Signal Defense opener because a
  spatial objective is the clearest contrast with the current kite-and-fire Assault.
  Later mission families must earn their place by producing similarly visible
  behavioral differences.
- Intermissions are valuable relief from sustained bullet pressure. They now
  fully repair hull while preserving resonance and evolution commitments.
- Retreat must be safer than defeat. The current tuning comparison recovers
  75% of earned Flux on retreat versus 50% on defeat; mastery remains banked in
  either case.
- The first intended build is Sentinel. Remaining nearly stationary builds
  damage, knockback, or range benefits; ordinary movement resets them. Later
  evolutions may permit slow repositioning without a reset, while active skills
  provide emergency relocation or push enemies away.
- The immediate contrasting build is a short-range, auto-targeting scatter
  weapon that becomes effective through constant kiting and aggressive spacing.
- Scalar resonance choices remain a chore and are now automatic baseline growth.
  Generic projectile speed is absent unless a specific weapon
  transformation makes it behaviorally relevant.
- The current targeting prototype cycles discrete priority modes with one key.
  Keyboard and mouse are the minimum Chapter 1 comparison target; other input
  mappings follow only if the control earns its place.
- Mission variety remains the next priority. The successful comparison now
  unblocks additional rhythms.

### Recorded direction after the Evolution and control play

- Signal Defense succeeds as a real rhythm change. It was the first objective
  prototype, not the intended exception in an otherwise survival-only operation.
  Missions two and three now need their own immediately legible objectives.
- Sentinel charge becomes a reserve that movement spends in proportion to
  displacement. Small corrections should lose a little power and let the player
  settle back in without repeating the entire charge delay.
- Phase Mooring should preserve Sentinel charge through Phase Dash. Directional
  input used to trigger Dash must not erase the benefit before the ability fires.
- Scatter and Bastion are equally interesting, but Scatter is much stronger.
  Tune their power toward parity while keeping Scatter's close-range kiting edge.
- Sparse pauses are working, but levels 2 and 4 arrive too close together. Keep
  the first early commitment and move the follow-up later in the stage.
- Highest Health has no useful tactical case while clearing more small enemies is
  always safer. Reduce the prototype to Nearest and Ranged Threats, and make the
  active mode unmistakable without adding aiming workload.
- The desire to try more builds is strong enough to justify another Chapter 1
  build after mission variety exists. Sentinel-specific Flux or achievement
  hooks are promising future incentives, but a raw Flux advantage must not turn
  one positioning style into the mandatory farming build.

### Tracking rules

- Use `Not started`, `In progress`, `Complete`, or `Revisit` in the chapter table.
- Mark a chapter complete only when its playable outcome exists, not when its
  supporting code or content list is merely present.
- Keep **Next action** specific enough that a fresh session can begin without
  reconstructing intent from chat history.
- Record the last meaningful result, current incomplete work, blockers, and the
  checks or playthroughs already performed.
- Add a short dated entry below when a session materially changes direction or
  completes part of the active checklist. Keep recent entries here; old detail
  belongs in git history rather than an ever-growing diary.
- Update commitments or hypotheses when play changes the design. Do not rewrite
  the plan merely to make the implementation appear complete.

### Session log

- **2026-08-11:** Rejected the back-to-back operation container after reviewing
  the completed integration play. The three objectives remain, but Signal Hold,
  Relay Breach, and Overseer Lock are now independently selected and rewarded
  stages with a hangar/build decision and fresh run state between them. Focused
  stages test optimization for a known problem; mixed-objective gauntlets are
  reserved for explicitly advertised optional challenges. No new play gate was
  added.
- **2026-08-11:** Completed the mandatory Chapter 1 integration play. All three
  mission rhythms and every tested configuration were fun; Bastion/Scatter
  balance, two-mode targeting, level-5 evolution timing, and displacement-spent
  charge worked. Sentinel plus Vector Parry was a highlight against the boss.
  Added content-defined mission deadlines, fixed follow-up evolution charge
  reset, quieted intermissions, shortened transmissions, removed redundant Parry
  narration, and established reusable objectives plus content-driven layouts as
  the level-design rule. Chapter 2 is unblocked after automated validation.
- **2026-08-11:** Implemented the Chapter 1 integration slice and stopped before
  its mandatory creator play. Signal Breach now moves from Signal Defense to a
  linked three-relay Breach and an Overseer boss. Added displacement-spent
  Sentinel charge, functional Phase Mooring, reduced Scatter output, a level-5
  second breakpoint, two-mode targeting with a persistent cue, a selectable
  Vector Parry configuration, mission transmissions, and distinct Breach/boss
  music treatment. Chapter 2 remains blocked on the integration play judgment.
- **2026-08-11:** Completed the Evolution and control play stop with both builds.
  Signal Defense, positioning contrast, operation length, and intermissions all
  worked. Planned a displacement-spent Sentinel charge, functional Phase Mooring,
  Scatter rebalance, later second evolution, two-mode targeting with a clearer
  cue, two genuinely distinct follow-up missions, and another build. Mission
  variety is the immediate content priority before the Chapter 1 integration
  stop.
- **2026-08-11:** Removed the standalone deployment route instead of preserving
  it for compatibility. Deploy now starts Signal Breach directly; operation-owned
  encounter profiles replace the campaign-stage catalog; scalar upgrade state,
  UI, progression gates, migrations, and obsolete regression tests are gone.
- **2026-08-11:** Implemented the Evolution and control comparison and stopped at
  its required play gate. Signal Defense now opens the operation; intermissions
  repair hull; retreat and defeat have distinct recovery. Operation resonance
  automatically grows output and offers sparse Bastion/Scatter transformations,
  including a Phase Dash interaction. Q cycles three target-priority modes.
- **2026-08-11:** Completed the required Operation spine play by clearing Signal
  Breach, deliberately failing, and retreating. The operation arc and pauses are
  worth keeping, but three escalating Assault missions collapse into the same
  kite-and-fire answer and overload the opener. Chose Signal Defense as the next
  contrast; future intermissions repair hull and keep upgrades, retreat must beat
  defeat economically, and operations will replace rather than coexist with the
  old deployment mode.
- **2026-08-11:** Implemented the first operation spine and stopped at its
  required creator play gate. Signal Breach connects three placeholder assault
  missions using the existing Stage 1-3 encounters, preserves operation state
  through intermissions, and distinguishes full completion rewards from 50%
  Flux recovery on retreat or defeat. Additional mission families wait on play.
- **2026-08-10:** Added mandatory creator play stops and completed the technical
  baseline. All nine existing Godot tests pass; pre-existing ObjectDB and
  resource-leak warnings remain visible on some clean test exits.
- **2026-08-10:** Recorded the creator's baseline play judgment. The rebuild must
  preserve differentiated weapons, the satisfaction of finding a strategy, and
  the confidence of "this time I've got this." Scalar in-run upgrades and an
  eventually complete permanent tree weaken choice. Chapter 1 should prove a
  Sentinel build that holds ground and keeps enemies at bay, plus better target
  agency against Gunners and on touch. Meaningful failure is part of the game's
  identity: the prototype felt most complete when a promising build created
  tension and still lost.
- **2026-08-10:** Declared pre-release saves disposable. Removed migration work
  from the plan, design contracts, architecture notes, and repository agent
  instructions. Missing or corrupt current-format saves must still fail safely.
- **2026-08-10:** Established the full-game direction, wrote the creator-led
  master plan, reclassified the prototype decisions, and added this cross-session
  tracker. Next session begins by mapping the existing lifecycle to Chapter 1.

## Purpose

This document describes the intended full game and a practical path from the
current compact campaign to that destination. It is a creative guide, not a
promise that every listed feature must ship. Playing the game, exercising taste,
and discovering a better idea may change the route.

Neon Requiem is being made by a tiny creator-and-AI team. The plan therefore
does not depend on telemetry, formal user research, test cohorts, feedback forms,
or statistically significant results. Outside reactions are useful when they
arrive, but the project advances by building playable increments, playing them,
and making direct judgments about whether they work.

Automated tests still protect technical contracts and regressions. They
establish that the game works as intended; they do not decide whether it is fun.

## The game we are making

Neon Requiem is a build-engineering action campaign made from short, intense
sorties. The player assembles a ship, deliberately evolves its weapons, and
learns to move and target in ways that exploit the resulting build. Action skill
matters, but build quality, preparation, and permanent growth let less
action-savvy players reach the ending.

The intended promise is:

> Engineer a distinctive vector warship, prove it across a sequence of readable
> combat problems, and become powerful enough to finish a complete campaign on
> your own terms.

The main campaign should feel complete after roughly 8-12 hours. Alternate
builds, optional routes, threat levels, challenges, and achievements may support
roughly 20-40 hours for players who want more. These numbers describe the desired
shape, not a quota that justifies padding.

## Creative pillars

### Build engineering over random accumulation

The player's main form of authorship is designing a build and then behaving in a
way that makes it work. Equipment, evolution paths, targeting behavior, active
skills, chassis or doctrines, and permanent progression should combine into
recognizable strategies.

Randomness may vary encounters or rewards, but it must not conceal the build
space or routinely deny the player a coherent plan. Important prerequisites and
future evolution branches remain visible.

### Short pressure, broader rhythm

The current 90-150 second gauntlet is a useful unit of high-intensity combat. It
should not be stretched into a long, uniformly exhausting survival run. Each
stage maintains one strategic thesis; the campaign gains broader rhythm by
placing different stages and hangar decisions along a sector route.

### Sparse decisions with large consequences

Weapons gain baseline power automatically as resonance rises. The player makes
fewer upgrade selections, and each selection changes behavior, creates a
tradeoff, or commits the build to a strategy. A choice that can be solved by a
small spreadsheet and has no effect on play style should usually become an
automatic improvement.

### Power is an accessibility path

The campaign may be overcome through some combination of build understanding,
permanent growth, optional missions, and execution. Players are allowed to
become stronger than a campaign obstacle. No required encounter should demand
high-end reflexes alone.

Post-game threats and fixed-build challenges may apply stricter execution tests,
provided the campaign ending does not depend on them.

### Readable vector spectacle

Procedural neon geometry remains the visual identity. Threats, player offense,
pickups, telegraphs, arena rules, and objective state must remain distinguishable
under pressure. Difficulty should come from decisions and patterns rather than
ambiguous ownership or visual noise.

### A real ending, followed by new possibilities

Defeating the final campaign boss resolves the primary conflict and produces an
ending. The post-game then opens alternate routes, transformations, challenges,
and rising threat levels. It does not retroactively turn the campaign clear into
an incomplete tutorial.

## The full-game shape

### Campaign hierarchy

```text
Campaign
|-- Sector
|   |-- Stage
|   |   |-- Focused objective
|   |   `-- Variations that deepen the same build question
|   |-- Hangar / route decision
|   `-- Sector boss
`-- Final stage and ending
```

A likely full campaign contains three sectors. Each sector has authored routes,
optional branches, several focused stages, and a major boss. The next stage's
objective, arena rule, and important threats are visible before deployment so
the player can configure deliberately. A stage may use multiple waves, spaces,
or phases only when they elaborate the same strategic question.

Failure should preserve some earned mastery and Flux. Depending on the stage,
the player may retry, retreat with partial rewards, or return to the route.
Failure must produce progress or useful knowledge without making success
irrelevant.

### Mission vocabulary

The game should grow through different combat questions, not only denser enemy
spawns. Candidate mission families include:

- **Assault:** Survive the current style of concentrated swarm pressure.
- **Elite Hunt:** Find and destroy a dangerous target before it escapes or
  completes an action.
- **Signal Defense:** Protect, rotate between, or reactivate objectives under
  measured pressure.
- **Breach:** Destroy linked relays, armor modules, or generators in an order
  chosen by the player.
- **Salvage:** Accumulate optional rewards while deciding when it is safe to
  extract.
- **Anomaly:** Adapt to one clear arena rule, environmental hazard, or altered
  combat law.
- **Boss:** Read phases, create vulnerability, and exploit a build-specific
  opening over a longer authored encounter.

Not every candidate must survive. A mission family earns its place by making
different builds move, target, or prioritize differently.

### Arenas

Multiple arenas are part of the full-game direction. They should differ
mechanically as well as visually: lanes, rotating safe regions, destructible
relays, moving boundaries, temporary cover, objective placement, or other
legible rules. Arena geometry must not compromise the clarity and responsive
movement that already work.

## Build architecture

### Loadout layers

A full build may draw from the following layers:

1. A chassis or doctrine that establishes a broad constraint or advantage.
2. One to three weapons, with two as the normal reference loadout.
3. An active skill.
4. Weapon targeting doctrines or target-priority rules.
5. Transformational evolution choices made during a stage.
6. Permanent skill, mastery, and unlock progression.

Chassis are not mandatory merely because they appear in the plan. They should be
added only if they create meaningful build rules, such as one amplified weapon,
two balanced weapons, or three weaker weapons. They should not be a disguised
list of small percentage bonuses.

### Automatic growth and evolution

Resonance automatically raises the baseline effectiveness of equipped weapons.
At a small number of visible breakpoints, the player chooses an evolution. Each
weapon should eventually support multiple coherent identities.

Examples for the Pulse Cannon include:

- A slow rail driver that rewards lining enemies up and creates piercing impact.
- A close-range scatter array that rewards aggressive positioning.
- An execution protocol whose shots split or accelerate after kills.

Later choices deepen the selected behavior instead of returning to generic
damage, rate, and speed questions. Evolution paths are visible before commitment.
Commitments normally last for the stage, encouraging a new plan next time
without punishing experimentation permanently.

### Interactions and fusion

The build system should contain authored interactions between layers. A Nova
Burst might consume projectiles captured by Vector Parry; Arc Lash might use
Pulse projectiles or Orbit Blades as conductors; a Phase Dash might leave behind
an echo that repeats a weapon action.

Not every weapon pair requires a bespoke fusion. With eight weapons there are 28
possible pairs, and with twelve there are 66. Interactions should be selected for
clarity and value rather than completed as a combinatorial checklist.

### Targeting and combat input

Auto-targeting remains the safe baseline while the following approaches are
compared through direct play:

- Automatic targeting with improved target selection.
- A button that marks or cycles a priority target.
- Mouse or second-stick aim bias that falls back to automatic targeting.
- Full manual aiming as an optional or mode-specific control.

The goal is not to add input for its own sake. Additional control succeeds only
if it helps the player express the build without overwhelming movement and threat
reading.

Targeting doctrines may offer build control without continuous aiming. Examples
include nearest target, highest health, lowest health, densest cluster, ranged
threats first, or preserving a marked target. Different weapons may use different
doctrines.

## Permanent progression

Permanent growth should make the player both stronger and broader.

- **Flux skills** provide bounded general power and strategic modifiers.
- **Item mastery** remains intrinsic to the weapon or active skill that earned
  it. Mastery may grant bounded power, unlock evolution branches, or reveal a
  specialized interaction.
- **Campaign rewards** unlock equipment, doctrines, routes, mission choices, and
  new forms of build expression.
- **Optional missions** let a struggling player gain strength before returning
  to a required encounter.

Permanent progression must not expand without limit or reduce every build to the
same overwhelming damage total. A strong profile should forgive mistakes and
open options while encounters continue to reward understanding.

Owning every permanent unlock must not mean activating every benefit at once.
Even a complete profile should make a build allocation through limited slots,
capacity, mutually exclusive branches, or another visible constraint. The exact
mechanism remains open; preserving choice after progression is the requirement.

Respec remains generous where points represent general build allocation. Native
item mastery remains non-transferable because it represents familiarity with
that item rather than a generic currency.

## Difficulty, post-game, and achievements

The main campaign is allowed to become easier as the profile grows. Optional
post-game layers provide enduring resistance:

- Threat levels add enemy traits, boss variations, arena complications, and
  higher reward potential.
- New threats also unlock additional player power or build options so progression
  is not reduced to requiring faster reactions.
- Challenge modes may use fixed, restricted, or partially normalized builds.
- Score-oriented modes may separate permanent advantages from comparable scores.
- Achievements should encourage unusual builds and decisions. Some may unlock
  starting conditions, doctrines, or cosmetic recognition rather than only
  currency.

Competitive leaderboards, daily infrastructure, and online services are not
required for the core post-game.

## Narrative, music, and presentation

The vector visual constraint does not imply a procedural-audio constraint.
Authored music, richer weapon sounds, sector themes, and reactive boss layers are
valid investments when they materially strengthen the game. A representative
audio treatment should be explored before large-scale content production so its
cost and impact are understood.

Narrative begins restrained:

- A clear campaign objective and conflict.
- Short transmissions around stages.
- A ship intelligence, rival signal, or similarly focused voice if useful.
- Library entries that connect discoveries to the world.
- Boss identities that express different hostile strategies.
- A definitive ending.

The project may grow this layer if it becomes one of the game's strengths. It
should not assume a large cast, extensive voice acting, or thousands of reactive
events before the combat structure earns that investment. AI can assist
production, but direction, selection, continuity, pacing, and integration remain
real creative work.

## Working content range

The following range keeps the intended game visible without turning counts into
obligations:

| Content | Working range |
|---|---:|
| Sectors | 3 |
| Weapons | 6-8 |
| Active skills | 4 |
| Chassis or doctrine families | 2-3 |
| Regular enemy behaviors | 8-12 |
| Major bosses | 3 |
| Mission families | 5-7 |
| Post-game threat tiers | Several, added only while they remain interesting |

Six excellent weapons are better than twelve shallow ones. Reused enemies are
valuable when new formations, objectives, arenas, and combinations make them ask
a new question.

## Scope boundaries

The initial full-game plan does not depend on:

- Online multiplayer or cooperative play.
- Competitive online infrastructure.
- Fully procedural campaigns.
- Endless permanent-stat scaling.
- A large voiced narrative system.
- User-generated content.
- Hundreds of interchangeable items.
- Platform-specific certification work.

These are not eternal prohibitions. They are excluded from the critical path so
they cannot distort the core game before it is complete.

No console, storefront, or control scheme is committed yet. Runtime input and UI
should remain adaptable without building platform-specific systems prematurely.

## Technical direction

The existing architecture remains a good foundation:

- `game.gd` stays the composition root and lifecycle state machine.
- Content catalogs own immutable stage, objective, enemy, weapon, evolution,
  and progression definitions.
- `RunSession` owns mutable deployment state without depending on nodes.
- Focused systems own spawning, combat, weapon behavior, objectives, and mission
  orchestration.
- Cross-system outcomes travel through signals wired at the composition root.
- UI remains behind the `GameUI` facade and delegates focused views.

New abstractions should emerge from playable needs rather than anticipating every
possible mission or effect. In particular, avoid building a universal effect
language, generic quest engine, or procedural encounter framework before several
real examples establish their common shape.

Likely foundational additions include:

- Operation and mission catalogs with explicit lifecycle types.
- Operation-scoped state distinct from permanent profile state.
- Weapon evolution definitions and run-scoped commitments.
- Objective orchestration separate from enemy construction.
- Arena rules exposed through focused presentation and system modules.
- Simple replacement defaults when skill, unlock, or campaign structures change.

The project is pre-release and its saves are disposable. Incompatible profile
changes may reset all progress without a migration path. Do not preserve an old
schema at the cost of a clearer game or implementation.

Removed prototype content should return only when a future stage gives it a
clear role. Existing enemies and encounter ideas may be reused where they serve
the new structure, not merely because they once existed.

## How the work advances

Each chapter below should produce something playable and worth keeping. A chapter
may be cut short, reordered, or revised when direct play reveals a better path.
There are no invented audience metrics that must be satisfied before continuing.

### Required play stops

These are mandatory creator play sessions, not research exercises. Do not begin
the next listed body of work until the result is recorded in **Current handoff**
or the **Session log**. A useful record needs only what was played, what felt
right or wrong, and what changes before continuing.

| Stop | Required play | Work that waits |
|---|---|---|
| Baseline | Play the current campaign and record what must survive, what feels weak, and the build the new direction should enable. | Runtime restructuring |
| Operation spine | Complete three connected placeholder missions; deliberately fail and retreat to inspect state, rewards, and pacing. | Additional mission families and campaign content |
| Evolution and control | Play the same operation with two intended builds, then compare the targeting variants in real pressure. | More weapons and control polish |
| Chapter 1 integration | Complete the revised three-rhythm operation with the tuned builds and one new configuration; verify each mission asks a different combat question. | Rebuilding the complete opening sector |
| Chapter 2 | Start from an empty profile, experience failure and optional power growth, then clear the entire first sector. | Broad build production |
| Chapter 3 | Play several named builds through the same demanding stage or boss and revise numerical duplicates. | Final campaign content production |
| Chapter 4 | Complete the whole campaign from an empty profile and watch the ending. The finite game must feel satisfying by itself. | Post-game production |
| Chapter 5 | Complete at least one threat run and one challenge; confirm that they change decisions rather than only health and damage. | Release finishing work |
| Chapter 6 | Complete the release candidate from an empty profile, including failure, reset, pause, and missing or corrupt save recovery. | Declaring the game finished |

The Baseline, Operation spine, Evolution and control, and Chapter 1 integration
stops are complete and recorded above. The chained-operation result is retained
as history; its container was subsequently replaced by focused stages without
adding another play target. Later stops remain incomplete until their
corresponding game exists.

### Chapter 1: Prove focused stages

Build a small set of representative stages before multiplying campaign content.

- Expose Hold, Breach, and Boss as separate, independently rewarded hangar
  deployments with fresh run state between them.
- Show each stage's objective, deadline, and important combat premise before
  deployment so the player can optimize rather than build for unknown tests.
- Keep voluntary retreat safer than defeat and preserve earned mastery in either
  case.
- Include at least three stage rhythms, one new arena rule, and a substantial
  boss variation.
- Replace frequent scalar resonance prompts with automatic growth and a small
  visible evolution tree.
- Support at least two builds that demand noticeably different positioning or
  targeting behavior.
- Make one of those builds a Sentinel: it should hold ground and keep enemies at
  bay by accumulating damage, knockback, or range while stationary. Movement
  spends stored charge in proportion to displacement; small corrections should
  preserve some benefit, while active skills may relocate the ship or push
  enemies away without invalidating the build.
- Make the immediate counter-build a short-range auto-targeting scatter weapon
  that demands constant kiting and aggressive spacing.
- Add one clear interaction between weapons, an active skill, or a doctrine.
- Prototype a keyboard-and-mouse key that switches between Nearest and Ranged
  Threats, including a way to prioritize a Gunner while closer enemies are present,
  with a prominent active-mode cue.
  Expand the mapping to touch or controller only if the control proves useful.
- Give the slice representative music, sound, and restrained narrative framing.

Chapter 1 proved three enjoyable objective families, distinct positioning builds,
and a strong Sentinel/Vector Parry interaction. It also rejected the assumption
that those objectives should be chained after locking one build. Future stages
may contain repeated or evolving forms of one objective; mixed-objective
gauntlets are optional challenges whose generalist demand is disclosed upfront.

### Chapter 2: Rebuild the opening sector

Turn the current playable campaign into a proper introduction to the larger game.

- Teach stage selection, automatic growth, evolution, retreat, banking,
  and targeting controls without presenting every system immediately.
- Reuse and revise the current enemies, encounter ideas, unlocks, and Overseer according to
  their best campaign role.
- Ensure the first required route is clearable without permanent grinding.
- Add optional routes that provide power, equipment, or mastery before the boss.
- Establish the first meaningful ending beat while pointing toward the next
  sector.
- Replace the prototype profile shape outright if the new campaign needs it.

At the end of this chapter, the game should again feel complete at a compact
scale, now using the intended full-game structure.

### Chapter 3: Establish build breadth

Expand the build language before producing the final campaign volume.

- Bring several weapon identities to full transformational depth.
- Add active skills that create different tactical plans rather than serving as
  interchangeable panic buttons.
- Decide whether chassis or doctrines earn their complexity.
- Introduce targeting doctrines if they improved control in Chapter 1.
- Expand mastery and the permanent tree around choices as well as power.
- Add enemy and objective behaviors specifically designed to distinguish builds.
- Improve the Arsenal Library so players can understand future possibilities.

This chapter ends when the available equipment supports multiple builds worth
revisiting for their behavior, not merely for completion marks.

### Chapter 4: Complete the campaign

Use the proven mission and build vocabulary to author the remaining sectors.

- Give each sector a mechanical and musical identity.
- Introduce arenas, enemy formations, objectives, and bosses in deliberate
  combinations.
- Use optional branches for recovery, risk, mastery, equipment, and story rather
  than reward-number variations alone.
- Pace unlocks so the player receives new possibilities without being flooded.
- Create a final stage that draws on build understanding developed across
  the campaign.
- Deliver a conclusive ending.

The campaign is complete when its ending feels satisfying without referring the
player to post-game content for closure.

### Chapter 5: Open the post-game

Add replay layers that transform rather than merely inflate the campaign.

- Introduce the first threat levels with new enemy, arena, and boss rules.
- Pair rising danger with new transformations, doctrines, or other player power.
- Add a focused set of challenge modes and achievements that encourage unusual
  builds.
- Consider a score mode only if its economy creates decisions deeper than
  surviving enemies with larger health totals.
- Add further threat tiers only while each produces a meaningful new experience.

### Chapter 6: Finish the product

Polish the complete experience according to the platforms eventually chosen.

- Finalize input presentation and any appropriate controller support.
- Add accessibility options that reinforce the campaign philosophy.
- Complete audio, music, feedback, onboarding, settings, credits, fresh-profile
  persistence, and performance work.
- Review every unlock description, telegraph, failure state, and transition.
- Remove obsolete prototype paths and development-only content.
- Play complete fresh-profile campaigns repeatedly, including reset and corrupt
  or missing-save recovery.

This chapter is not an invitation to add new systems. It is where the intended
game becomes coherent, reliable, and ready to leave the workshop.

## Creator-led play checks

These are prompts for direct judgment, not formal gates or surveys:

- Can two builds be described without referring only to damage numbers?
- Does each important evolution change movement, targeting, timing, or risk?
- Is there a reason to choose a non-obvious branch?
- Does a stage deepen its central build question before its intensity becomes exhausting?
- Do different mission types expose different build strengths?
- Can a struggling campaign player pursue more power without being trapped in a
  mandatory reflex test?
- Can a confident player advance with less grinding through better planning and
  execution?
- Is a death understandable?
- Does a boss create a vulnerability the build can intentionally exploit?
- Does a new weapon justify its interactions, presentation, balance, and testing
  cost?
- Is the campaign ending satisfying even if the post-game is never opened?
- After finishing a stage, do we personally want to reconfigure for another?

When the honest answer is no, revise the relevant system. No dashboard is needed
to recognize that result.

## Definition of full-sized success

Neon Requiem succeeds creatively when it delivers a complete, memorable campaign
and leaves players with builds they want to discuss or revisit. Its length comes
from consequential combinations and varied combat problems, not compulsory
grinding or repeated health inflation.

It succeeds as a project when the finished scope remains maintainable by its
actual creators, reaches a stopping point that feels intentional, and does not
require every possible expansion to justify the work already completed.
