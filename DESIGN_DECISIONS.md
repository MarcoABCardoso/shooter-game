# Neon Requiem — Decision Log

This file is the adjustable design contract for the game. Change a value in the noted script when tuning; update this log when changing direction.

## 2026-08-08 — Product direction

### D001: One-arena incremental bullet hell

- **Decision:** Runs take place in an endless, bounded neon arena. Enemy density, health, speed, and bullet pressure rise continuously; an elite arrives every 60 seconds and a boss every 120 seconds.
- **Why:** A single arena keeps the project asset-light while allowing the build to invest in combat feel and progression depth.
- **Adjust:** Spawn pacing and scaling live in `scripts/game.gd` under `DIFFICULTY` and `_update_spawning()`.

### D002: Two progression horizons plus weapon mastery

- **Decision:** XP creates build choices inside a run. Flux earned from kills is banked on defeat and buys permanent ship upgrades. Damage dealt by each weapon grants persistent weapon mastery, improving that weapon automatically over many runs.
- **Why:** The player should feel meaningful growth within minutes, across sessions, and simply by favoring a weapon.
- **Adjust:** Upgrade pools are in `scripts/game.gd`; permanent bonuses and mastery curves are in `scripts/profile.gd`.

### D003: Movement aims, weapons auto-fire

- **Decision:** WASD/arrow keys move, the mouse aims, Space dashes, and all weapons fire automatically.
- **Why:** This keeps attention on positioning through dense patterns without removing directional agency.
- **Adjust:** Input mappings are in `project.godot`; cadence and targeting are in `scripts/player.gd`.

### D004: Four synergistic weapon families

- **Decision:** Pulse Cannon (aimed projectile), Orbit Blades (defensive contact ring), Arc Lash (chain lightning), and Nova Burst (periodic radial clear). They unlock through run upgrades rather than random drops.
- **Why:** The set covers focused DPS, close defense, crowd chaining, and emergency area control with readable visual identities.
- **Adjust:** Base weapon data is in `scripts/player.gd`; upgrade definitions are in `scripts/game.gd`.

### D005: Neon vector geometry only

- **Decision:** Ships, enemies, bullets, pickups, particles, arena, and interface decoration are drawn with Godot primitives. No external images or fonts are required.
- **Why:** It produces a cohesive look, keeps the repository small, and makes color/shape changes instant.
- **Adjust:** Entity drawing lives with each script in `scripts/entities/`; palette constants are in `scripts/game.gd`.

### D006: Readability beats visual density

- **Decision:** Player threats are warm magenta/orange, player offense is cyan/green, collectible resources are yellow, and enemy bodies are darker than their outlines. Telegraphs precede dangerous attacks.
- **Why:** Bullet hell difficulty should come from patterns and decisions, not ambiguous ownership.

### D007: Forgiving early, exponential late

- **Decision:** The player starts with 100 hull, a short invulnerable dash, and modest regeneration opportunities. Difficulty grows with elapsed time and kill pressure, with bosses acting as build checks.
- **Why:** New players get time to learn; established profiles reach the demanding phase faster through stronger builds.

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

- **Decision:** Pause, level-up, and run-end states disable processing for the entire `run_entities` group.
- **Why:** Enemy AI, bullets, pickups, and effects must freeze consistently while menus remain interactive. Toggling only player input creates hidden state drift.

## Initial balance reference

| System | Starting value | Growth |
|---|---:|---:|
| Player hull | 100 | +20 run choice; +12 permanent rank |
| Player speed | 300 px/s | +10% run choice; +3.5% permanent rank |
| Pulse cannon | 15 damage / 0.34 s | Upgrade choices + 2.5% per mastery rank |
| Enemy durability | Type-specific | Multiplied by `1 + elapsed / 155` |
| Spawn interval | 0.82 s | Divided by `1 + elapsed / 105`, floor 0.16 s |
| Elite cadence | 60 s | Fixed |
| Boss cadence | 120 s | Fixed |
| Dash | 0.18 s movement, 0.30 s invulnerability | 1.25 s cooldown |

## Scope included in the first playable build

- Title/hangar screen, control guide, permanent upgrade shop, and save reset.
- Complete run lifecycle: spawn, combat, XP choices, elites, bosses, defeat, rewards, retry.
- Four weapons, use-based mastery, five permanent upgrades, combo multiplier, dash, pickups, damage feedback, particles, screen shake, and pause.
- Mouse/keyboard and keyboard-only movement; gamepad support is a later decision.

## Deferred decisions

- Meta-story, characters, online leaderboards, multiple arenas, gamepad-first aiming, accessibility modifiers, and music are intentionally left open.
