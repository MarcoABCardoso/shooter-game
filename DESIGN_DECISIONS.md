# Neon Requiem — Design Reference

This file is the adjustable design contract for the game. Change a value in the noted script when tuning.

## Product direction

### D001: Finite stage progression in one bounded arena

- **Decision:** Stage 1 escalates for 120 seconds, evacuates its surviving swarm, and concludes with the Overseer Array. Normal spawning remains suspended throughout the boss encounter. Additional finite stages can provide their own encounter scripts, bosses, and rewards; an endless Overdrive mode is reserved for future expansion.
- **Why:** Authored conclusions give build growth a destination and let bosses test a different skill than crowd control while preserving the asset-light arena.
- **Adjust:** Stage timing and intro duration live in `scripts/core/game_balance.gd`; lifecycle cadence lives in `scripts/systems/spawn_director.gd`.

### D002: Behavior-driven run evolution plus persistent growth

- **Decision:** Combat continuously measures Anchored/Roaming, Close/Distant, and Focus/Spread tendencies. Defeating enemies grants resonance and Flux directly, avoiding progression drops entirely. Resonance sets the cadence for automatic mutations, Flux buys permanent ship upgrades, and weapon damage grants persistent mastery.
- **Why:** The run's build should record how the player fought, while remaining understandable and deliberately steerable.
- **Adjust:** Sampling and smoothing live in `scripts/core/behavior_profile.gd`; combined mutations live in `scripts/content/evolution_catalog.gd`; permanent bonuses and mastery curves live in `scripts/profile.gd`.

### D003: Movement aims, weapons auto-fire

- **Decision:** WASD/arrow keys move, the mouse aims, Space dashes, and all weapons fire automatically.
- **Why:** This keeps attention on positioning through dense patterns without removing directional agency.
- **Adjust:** Input mappings are in `project.godot`; cadence and targeting are in `scripts/player.gd`.

### D004: Four synergistic weapon families

- **Decision:** Pulse Cannon (aimed projectile), Orbit Blades (defensive contact ring), Arc Lash (chain lightning), and Nova Burst (periodic radial clear). They unlock and develop through combined behavioral mutations.
- **Why:** The set covers focused DPS, close defense, crowd chaining, and emergency area control with readable visual identities.
- **Adjust:** Base weapon data is in `scripts/content/weapon_catalog.gd`; evolution definitions are in `scripts/content/evolution_catalog.gd`.

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

- **Decision:** Pause and run-end states disable processing for the entire `run_entities` group. Evolution never pauses the simulation.
- **Why:** Enemy AI, bullets, pickups, and effects must freeze consistently while menus remain interactive. Toggling only player input creates hidden state drift.

### D013: Reallocatable weapon mastery

- **Decision:** Earned mastery ranks enter a shared pool and default to the weapon that earned them. The Callibrations screen can move ranks between weapons, while each weapon's effective mastery is capped at twice its native earned mastery.
- **Why:** Use-based progression still rewards learning every weapon, but players can trade effectiveness away from less-favored systems to specialize in a preferred combat style.
- **Adjust:** Rank curves, allocation transactions, the 2x cap, and effective damage bonuses live in `scripts/profile.gd`; presentation lives in `scripts/ui/game_ui.gd`.

### D014: Bosses interrupt the crowd-control rhythm

- **Decision:** The Stage 1 Overseer is assembled from a central core and three connected geometric modules. Its Target Lock, Firewall, and Vector Charge attacks are separately telegraphed; armor reduces damage between white-core recovery windows. Wide-area weapons retain useful armor-stripping damage.
- **Why:** The encounter redirects attention toward readable timing and focused exploitation without invalidating the build developed during the stage.
- **Adjust:** Boss behavior and vector presentation live in `scripts/entities/enemy.gd`; projectile patterns and swarm evacuation live in `scripts/systems/combat_director.gd`.

### D015: Stage bosses award ability-slot alternatives

- **Decision:** Clearing Stage 1 unlocks Vector Parry. It occupies the same Space input and recharge HUD slot as Phase Dash, reflects nearby projectiles caught in a forward arc, and can be equipped or declined at stage clear.
- **Why:** A mechanical alternative is more memorable than a numeric reward and turns the boss's telegraph lesson into a tool for later stages.
- **Adjust:** Ability execution lives in `scripts/entities/player.gd`; ownership and equip state live in `scripts/profile.gd`.

## Initial balance reference

| System | Starting value | Growth |
|---|---:|---:|
| Player hull | 100 | Behavioral mutations; +12 permanent rank |
| Player speed | 300 px/s | Behavioral mutations; +3.5% permanent rank |
| Pulse cannon | 15 damage / 0.34 s | Behavioral mutations + 2.5% per mastery rank |
| Enemy durability | Type-specific | Multiplied by `1 + elapsed / 155` |
| Spawn interval | 0.82 s | Divided by `1 + elapsed / 105`, floor 0.16 s |
| Elite cadence | 60 s | Fixed |
| Stage 1 boss | 120 s | Ends normal spawning; 2.4 s evacuation intro |
| Dash | 0.18 s movement, 0.30 s invulnerability | 1.25 s cooldown |

## Scope included in the first playable build

- Focused title screen, separate permanent-upgrade hangar, discovery-gated Arsenal Library, and save reset.
- Complete Stage 1 lifecycle: spawn, combat, continuous behavior sampling, automatic resonance mutations, elite, swarm evacuation, modular boss, defeat or stage clear, reward, retry.
- Four weapons, use-based mastery, five permanent upgrades, combo multiplier, dash, pickups, damage feedback, particles, screen shake, and pause.
- Mouse/keyboard and keyboard-only movement; gamepad support is a later decision.

## Deferred decisions

- Meta-story, characters, online leaderboards, multiple arenas, gamepad-first aiming, accessibility modifiers, and music are intentionally left open.
