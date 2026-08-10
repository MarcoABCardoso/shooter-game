# Neon Requiem — Design Reference

This file is the adjustable design contract for the game. Change a value in the noted script when tuning.

## Product direction

### D001: Five finite stages in one bounded arena

- **Decision:** Deploy opens a stage-select graph whose revealed nodes form the player ship's vector silhouette. Only unlocked nodes exist, and each is labeled solely by stage number. Stages 1–4 end after their surviving swarm evacuates; Stage 5 concludes with the Overseer Array and suspends normal spawning during the duel.
- **Why:** Stage selection makes progression legible, gives early permanent growth a purpose, and reserves the boss as a campaign milestone instead of a first-run wall.
- **Adjust:** Stage rosters, timing, health, spawn pressure, elite cadence, and boss presence live in `scripts/content/stage_catalog.gd`; lifecycle cadence lives in `scripts/systems/spawn_director.gd`.

### D002: Deliberate hangar builds plus persistent growth

- **Decision:** Weapons, active skill, and graph skills are chosen in the hangar. Each resonance level then offers all three uncapped dimensions for every equipped weapon, letting the player deliberately evolve damage, cadence, projectile behavior, coverage, or weapon-specific capacity. There are no random offerings. Flux buys graph nodes only, while damage and active-skill use grant native mastery.
- **Why:** Bullet-hell movement naturally converges toward similar measured behavior, but a completely fixed run lacks tactical authorship. Explicit hangar choices plus deterministic per-level specialization keep builds legible and player-directed.
- **Adjust:** Persistent loadout transactions live in `scripts/profile.gd`; graph content lives in `scripts/content/skill_tree_catalog.gd`; per-run choices and their five-rank cap live in `scripts/content/run_upgrade_catalog.gd` and `scripts/core/run_session.gd`.

### D003: Movement and active skills are the only combat inputs

- **Decision:** WASD/arrow keys move, Space activates the equipped skill, and weapons automatically acquire targets. The ship smoothly faces its movement direction without target-driven rotation. Touch uses the same movement-plus-skill model with one stick.
- **Why:** Positioning is the core skill, and removing manual aim keeps the challenge consistent across mouse, keyboard, and touch devices.
- **Adjust:** Input mappings are in `project.godot`; cadence and targeting are in `scripts/systems/weapon_system.gd`.

### D004: Unlockable weapon loadouts

- **Decision:** A new profile starts with Pulse Cannon and one weapon slot. Stage 1 unlocks Orbit Blades. Stage 5 unlocks the second slot; Arc Lash and Nova Burst are reserved for future routes.
- **Why:** A sparse reward path makes each unlock legible and prevents the first clear from flooding the player with overlapping systems.
- **Adjust:** Base weapon data is in `scripts/content/weapon_catalog.gd`; ownership, slots, and selection live in `scripts/profile.gd`.

### D005: Neon vector geometry only

- **Decision:** Ships, enemies, bullets, pickups, particles, arena, and interface decoration are drawn with Godot primitives. No external images or fonts are required.
- **Why:** It produces a cohesive look, keeps the repository small, and makes color/shape changes instant.
- **Adjust:** Entity drawing lives with each script in `scripts/entities/`; palette constants are in `scripts/game.gd`.

### D006: Readability beats visual density

- **Decision:** Player threats are warm magenta/orange, player offense is cyan/green, collectible resources are yellow, and enemy bodies are darker than their outlines. Telegraphs precede dangerous attacks.
- **Why:** Bullet hell difficulty should come from patterns and decisions, not ambiguous ownership.

### D007: Tutorial-clearable first stage, escalating later stages

- **Decision:** Stage 1 lasts 55 seconds, contains only Drones, has no elites, and is intentionally beatable without permanent upgrades while still punishing passive movement. Stage 2 adds Strikers and expects modest growth; Stage 3 introduces elites; Stage 4 adds Gunners; Stage 5 adds Tanks and the boss.
- **Why:** The first clear teaches movement, auto-targeting, resonance, and banking without demanding a grind. Later stages then validate the loadout and skill-tree growth the player earned.

### D008: Local, forward-compatible persistence

- **Decision:** The profile is JSON at `user://neon_requiem_save.json`, with a version number, defensive defaults, and explicit reset support.
- **Why:** Saves remain inspectable and migration-friendly.

### D009: Godot retained after Phaser 4 review

- **Decision:** Keep Godot 4.3+ as the target after considering Phaser 4.
- **Why:** Godot supplies physics, scene lifecycle, local saves, and desktop export without adding a web build stack. Phaser would be a good choice for instant URL distribution, but that is not currently a requirement and Phaser 4's moving API would increase maintenance risk.
- **Adjust:** The gameplay data is intentionally kept in plain dictionaries, so a browser port remains feasible if distribution priorities change.

### D010: Minimal procedural sound

- **Decision:** Feedback tones are generated at runtime with `AudioStreamGenerator`; there are no imported sound files.
- **Why:** The audio stays consistent with the asset-free vector constraint and still communicates firing, damage, pickups, upgrades, and defeat.
- **Adjust:** Systems request tones through signals; generation is isolated in `scripts/audio.gd` and can later be replaced by authored audio without touching gameplay.

### D011: Signal-connected modular architecture

- **Decision:** Refactor the initial composition into content catalogs, an isolated `RunSession`, independent spawn/combat/weapon systems, a presentation layer, and a UI layer. Keep `game.gd` as the composition root and lifecycle state machine.
- **Why:** Enemies, weapons, upgrades, UI, and balance can be changed independently; data definitions have one owner; system dependencies remain visible at the root; test seams exist without a framework dependency.
- **Adjust:** Module contracts and extension recipes are documented in `ARCHITECTURE.md`. New cross-system behavior should be expressed as a signal and wired in `game.gd` rather than by giving modules references to each other.

### D012: Simulation-level pause

- **Decision:** Manual pause, run-end, and resonance-choice states disable processing for the entire `run_entities` group. The upgrade overlay stays responsive while combat is frozen.
- **Why:** Enemy AI, bullets, pickups, and effects must freeze consistently while menus remain interactive. Toggling only player input creates hidden state drift.

### D013: Native item mastery

- **Decision:** Each weapon and active skill owns the mastery it earns. Weapon mastery increases that weapon's damage; active-skill mastery shortens its recharge. Mastery cannot be reassigned.
- **Why:** Persistent familiarity remains valuable without recreating a second respec system beside the Flux skill graph.
- **Adjust:** Rank curves and bonuses live in `scripts/profile.gd`; accrual lives in `scripts/core/run_session.gd`.

### D014: Bosses interrupt the crowd-control rhythm

- **Decision:** The Stage 5 Overseer is assembled from a central core and three connected geometric modules. Its Target Lock, Firewall, and Vector Charge attacks are separately telegraphed; armor reduces damage between white-core recovery windows. Wide-area weapons retain useful armor-stripping damage.
- **Why:** The encounter redirects attention toward readable timing and focused exploitation without invalidating the build developed during the stage.
- **Adjust:** Boss behavior and vector presentation live in `scripts/entities/enemy.gd`; projectile patterns and swarm evacuation live in `scripts/systems/combat_director.gd`.

### D015: Sparse equipment rewards plus first-clear Flux

- **Decision:** Stage 1 unlocks only Orbit Blades. Stages 2–4 grant no equipment. Defeating the Stage 5 boss unlocks Vector Parry and the second weapon slot. Every stage's first clear grants bonus Flux equal to the enemy Flux earned in that run.
- **Why:** Equipment unlocks remain memorable while each first clear still accelerates permanent growth without requiring repeated farming.
- **Adjust:** Ability execution lives in `scripts/entities/player.gd`; ownership and equip state live in `scripts/profile.gd`.

## Initial balance reference

| System | Starting value | Growth |
|---|---:|---:|
| Player hull | 100 | Behavioral mutations; +12 permanent rank |
| Player speed | 300 px/s | Fixed; movement physics are unaffected by facing and targeting |
| Pulse cannon | 4.5 damage / 0.34 s / 190 px range | Skill tree + 2.5% per native mastery rank |
| Stage 1 | 55 s, Drones only | 0.68× health base; faster pressure; no elites or boss |
| Stage 2 | 75 s, adds Strikers | 0.90× health base; no elites |
| Stage 3 | 90 s, adds elites | Elite every 42 s |
| Stage 4 | 105 s, adds Gunners | Higher pressure; elite every 38 s |
| Stage 5 | 120 s, adds Tanks | Elite every 34 s; Overseer boss after evacuation |
| Dash | 0.18 s movement, 0.30 s invulnerability | 1.25 s cooldown |

## Scope included in the first playable build

- Focused title screen, hangar, discovery-gated Arsenal Library, and save reset.
- Five-stage selection and unlock route with staged enemy introductions, deterministic resonance evolution choices, swarm evacuation, modular Stage 5 boss, rewards, and retry.
- Hangar weapon and active-skill loadouts, expanded stage-gated Flux skill graph with free respec, native mastery, four weapons, combo multiplier, pickups, feedback, and pause.
- Keyboard and single-stick touch movement; gamepad support is a later decision.

## Deferred decisions

- Meta-story, characters, online leaderboards, multiple arenas, gamepad support, accessibility modifiers, and music are intentionally left open.
