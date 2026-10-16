# HAUNTED SHIFT
## Game Design Document (GDD)

**Version:** 1.0  
**Genre:** Top-down arcade horror / survival  
**Engine:** Godot  
**Platform:** Desktop PC, offline  
**Target playtime:** 2–4 minutes per round  
**Players:** 1  
**Design pillars:** Fast, chaotic, readable, forgiving, replayable

## 1. High Concept

The player is a night-shift worker trapped inside a haunted building. Collect cursed objects, evade increasingly aggressive ghosts, unlock the exit, and escape before losing all health.

HAUNTED SHIFT combines arcade survival, short bursts of panic, supernatural abilities, and quick restarts. The experience should be immediately understandable to someone playing it for the first time at a public demo.

**Core hook:** The building becomes more dangerous as the round progresses, forcing the player to make quick but readable decisions.

## 2. Core Gameplay Loop

1. Start from the title screen.
2. Explore the haunted building.
3. Collect cursed objects to increase the score.
4. Avoid ghosts using movement and a defensive dash.
5. Use a harmless defensive ward pulse to create space.
6. Collect enough objects to unlock the exit.
7. Escape to win, or lose all health to end the round.
8. View the result and restart with Z.

## 3. Controls (Mandatory)

Only these six keys may be used for gameplay or menus.

| Key | Gameplay | Menus |
|---|---|---|
| Up Arrow | Move up | Navigate up |
| Down Arrow | Move down | Navigate down |
| Left Arrow | Move left | Navigate left |
| Right Arrow | Move right | Navigate right |
| Z / z | Activate defensive ward pulse | Start, confirm, restart |
| Space | Dash in the current movement direction | Harmless visual effect |

### Input Rules

- Track held-key state every frame.
- Holding an arrow produces continuous movement; releasing it stops movement.
- Support diagonal movement with normalized speed.
- Opposing directions cancel safely.
- Use fresh-press detection for Z and Space actions.
- Holding Z or Space must not repeat a one-time action.
- Require Z to be released and pressed again for every screen transition.
- Ignore Z for the first second of the game-over screen.
- Clear held-key state when the window loses focus.
- Prevent arrow and Space input from scrolling the browser if exported to HTML5.
- No mouse, touchscreen, gamepad, microphone, WASD, Enter, Escape, or other keys.
- Releasing all keys simultaneously must never cause an instant loss.

## 4. Player

**Role:** Night-shift worker attempting to escape.

**Abilities:**

- **Movement:** Smooth eight-direction movement.
- **Ward Pulse (Z):** A short-range defensive effect that briefly pushes ghosts away or interrupts their pursuit. It has no limited charges and cannot harm the player.
- **Dash (Space):** A brief burst of movement in the current direction, with a cooldown of approximately 2.5 seconds.

If no movement direction has been selected, the dash uses a safe default direction.

**Health:** Three hits before game over, with brief damage immunity after being hit.

## 5. Enemies

### The Stalker
- Slowly pursues the player.
- Telegraphs dangerous appearances.
- Moves faster as the round progresses.
- Cannot cause repeated instant damage through continuous contact.

### The Wanderer
- Patrols predefined routes.
- Changes direction occasionally.
- Creates obstacles and encourages route planning.

Enemy attacks and new hazards must provide at least one second of reaction time. Enemy behavior should remain deterministic enough for players to learn and improve.

## 6. Collectibles and Objectives

**Cursed Objects**
- Increase score when collected.
- Spawn in accessible, visible areas.
- Never spawn directly on a damaging enemy or inside inaccessible geometry.

**Exit Door**
- Starts locked.
- Unlocks when the required number of objects is collected.
- Displays a clear visual state change when unlocked.

**Round Timer**
- Targets a 2–4 minute round.
- Timer expiration ends the round with a clear result.
- It must not cause an unavoidable loss without adequate warning.

## 7. Game Screens

### Title Screen
- Displays `HAUNTED SHIFT`.
- Shows the objective and all six controls.
- Displays the exact prompt `Press Z to start`.
- No clickable buttons.

### Gameplay Screen
- Displays player, ghosts, collectibles, exit, health, score, and timer.
- Provides clear visual warnings for threats.
- Keeps critical information high-contrast and readable from approximately two metres.

### Game Over / Results
- Displays escaped or caught status.
- Displays final score.
- Displays the exact prompt `Press Z to play again`.
- Ignores Z during the first second.
- Requires a fresh Z press after release.

## 8. Visual and Audio Direction

**Visual style:** Dark pixel-art haunted building with high-contrast purple, cyan, and warm yellow highlights.

**Visual priorities:**
- Player is always distinguishable from enemies.
- Ghost attacks have clear warning animations.
- Collectibles glow against the environment.
- Damage, dash readiness, and exit unlocking have obvious feedback.
- Screen shake and flashes are brief and never obscure threats.

**Audio:**
- Ambient haunted-house background.
- Distinct sounds for collecting objects, dashing, taking damage, and unlocking the exit.
- Audio must never be required to detect a threat.

## 9. Technical Design

**Engine:** Godot.

**Core systems:**
1. `InputManager`: centralized six-key mapping, held state, and fresh presses.
2. `Player`: movement, health, ward pulse, and dash.
3. `GhostAI`: pursuit, patrol, warning, and collision behavior.
4. `RoundManager`: timer, score, collectible count, win/loss conditions.
5. `ScreenManager`: title, gameplay, and results transitions.

Keep the architecture small and modular. Avoid unnecessary plugins and external runtime dependencies.

## 10. Milestones

**M1 — Playable foundation:** Title screen, movement, input manager, health, and restart.

**M2 — Objective:** Collectibles, scoring, timer, and exit unlocking.

**M3 — Enemy:** One functioning ghost with readable warnings and safe collision handling.

**M4 — Abilities and escalation:** Ward pulse, dash cooldown, additional enemy behavior, and gradual difficulty progression.

**M5 — Polish:** Art, lighting, particles, audio, and HUD.

**M6 — Compliance:** Test every applicable `AGENTS.md` checklist item and verify local run instructions.

Each milestone must leave the game runnable and playable before work proceeds.

## 11. Scope Boundaries

**Must-have**
- Complete start-to-finish round.
- Six-key-only controls.
- Responsive movement.
- Collectibles, scoring, and exit.
- Ghost AI and forgiving damage.
- Timer and results.
- Reliable restart.
- Local offline execution.

**Optional, only after compliance**
- Additional ghost types.
- Randomized room layouts.
- High-score persistence.
- Extra visual effects.

**Out of scope**
- Online multiplayer.
- Login or online services.
- Mouse-based aiming.
- Inventory menus requiring extra keys.
- Mechanics requiring rapid tapping or frame-perfect timing.

## 12. Compliance and Acceptance Criteria

Before the demo, verify:

- Only the four arrows, Z, and Space are used.
- No mouse or click handlers exist.
- Held movement and release behavior work correctly.
- Z works for start and restart with fresh-press protection.
- Space is optional, infrequent, and does not scroll the page.
- No mechanic requires opposite keys together.
- Releasing every key at once cannot cause instant loss.
- Accidental Z or Space presses are harmless.
- No button mashing or reactions faster than one second are required.
- Text, player, and threats remain readable at demo distance.
- No pop-ups, dialogs, or new windows steal focus.
- Title and game-over prompts match the required wording.
- The game launches locally using the command documented in `README.md`.

**Definition of Done:** A first-time player can understand the objective, start with Z, move immediately, survive a complete round, see the result, and restart without needing any other input or external service.