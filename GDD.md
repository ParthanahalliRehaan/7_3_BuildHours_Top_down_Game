# HAUNTED SHIFT
## Game Design Document (GDD)

**Version:** 1.1 (aligned with `instructions.md`)
**Genre:** Top-down arcade horror / survival
**Engine:** Godot 4.x (GDScript)
**Platform:** Desktop PC, offline
**Target playtime:** about 2.5 minutes per round (150 s timer)
**Players:** 1
**Design pillars:** Fast, chaotic, readable, forgiving, replayable

> `AGENTS.md` is mandatory and overrides this document. Where this GDD and `instructions.md` differ on a number or a node, `instructions.md` wins.

## 1. High Concept

You are the **Skeptic**, a night-shift guard who never believed in ghosts. Trapped in a haunted building, you must collect cursed relics, outrun a ghost, unlock the exit and escape before the timer runs out or you lose all health.

HAUNTED SHIFT is an arcade survival game built from short bursts of panic and quick restarts. Someone who has never seen it must understand it in seconds at a public demo.

**Core hook:** One ghost that clearly telegraphs itself, and two simple abilities (ward and dash) that let you take control of the chase.

## 2. Core Gameplay Loop

1. Title screen: read the goal and controls, press Z.
2. Move around the arena and collect **8 cursed relics** (+100 each).
3. The ghost fades in (3 s of harmless grace), then wanders and chases when you get close.
4. Use **Dash** (Space) to break away and **Ward** (Z) to push and stun the ghost.
5. After 8 relics the **Exit** unlocks. Walk into it to win.
6. Lose by running out of health (3 hits) or out of time.
7. Results screen: see score, press Z to play again.

## 3. Controls (Mandatory)

Only these six keys exist. Nothing else may be used for gameplay or menus.

| Key | Title | Playing | Game Over |
|---|---|---|---|
| Up / Down / Left / Right | nothing | move (hold = continuous, release = stop) | nothing |
| Z / z | start (fresh press) | Ward pulse (1.5 s cooldown) | play again (fresh press, ignored for first 1 s) |
| Space | nothing | Dash (2.5 s cooldown) | nothing |

There is no menu navigation, so the arrows do nothing on the title and results screens. There is no pause screen, because pausing would need a seventh key.

### Input Rules

- All keys are read in ONE autoload, `InputManager`. No other script reads keys.
- Held state is polled every frame (no reliance on OS key-repeat).
- Diagonal movement is normalised. Opposite arrows cancel to standing still.
- Z and Space use fresh-press detection: one press fires once, holding never repeats.
- Every screen change flushes input. A Z still held from the previous screen must be released and pressed again.
- Z is ignored for the first second of the results screen.
- Losing window focus clears all held keys.
- Releasing every key at once never causes a loss.
- No mouse, touch, gamepad, microphone, WASD, Enter or Escape. The mouse cursor is hidden. UI uses only Labels and ColorRects (no Buttons).

## 4. Player: The Skeptic

| Stat | Value |
|---|---|
| Move speed | 220 px/s, eight directions |
| Health | 3 |
| Damage immunity | 1.5 s after a hit, with blinking and a short knockback |
| Dash (Space) | 0.16 s burst at 560 px/s in the last move direction, 2.5 s cooldown |
| Ward (Z) | radius 160 px, stuns ghosts in range for 1.5 s and pushes them away, 1.5 s cooldown |

- If no direction has been chosen yet, the dash goes to the right (safe default).
- Pressing Z or Space during a cooldown does nothing, so mashing is harmless.
- The ward cannot hurt the player and has no limited charges.

## 5. Enemy: The Ghost (one type)

One AI ghost drives the whole game. It uses a small four-state machine:

| State | Behaviour | Dangerous? |
|---|---|---|
| **Spawning** | 3 s, faded and pulsing, does not move | No |
| **Wander** | Walks to random points in the arena at 60 px/s | Yes |
| **Chase** | Starts when you are within 420 px, follows you at 95 px/s (slowly rising to 130 px/s over the round), gives up beyond 560 px | Yes |
| **Stunned** | 1.5 s after a Ward hit, cyan, pushed back | No |

Fairness rules:

- Every new threat gives at least 1 second (here 3 s) of reaction time.
- The ghost is much slower than the player, so running away always works.
- Its damage hitbox is smaller than its body, and contact damage is gated by the 1.5 s immunity, so standing next to it can never drain health in one go.
- The ghost and the player collide only with walls, never with each other.

**Optional after compliance:** a second ghost type with patrol routes (the "Wanderer"), a ghost that enters after 30 s with a visible warning.

## 6. Collectibles and Objectives

**Cursed relics (8)**
- Glowing cyan diamonds at fixed, visible, reachable positions spread across the arena.
- None spawn near the ghost start position.
- Pickup radius is generous.

**Exit door**
- Right side of the arena, locked (red, "EXIT LOCKED") until 8 relics are collected.
- Turns green and reads "EXIT OPEN" when unlocked.

**Round timer**
- 150 seconds, always visible in the HUD.
- Ending on time gives a clear "TIME'S UP" result.
- Win bonus: remaining seconds x 5 points.

## 7. Game Screens

### Title Screen (`StartMenu.tscn`)
- Shows `HAUNTED SHIFT`, the goal ("Collect 8 relics. Reach the exit.") and all six controls.
- Shows the exact prompt `Press Z to start`.
- No clickable elements.

### Gameplay (`Main.tscn`)
- Arena, walls, relics, exit, Skeptic and Ghost.
- HUD: health, score, relics (x/8), time, and Z/Space cooldown readout.
- Text size 24 px or more, high contrast.

### Game Over / Results (`GameOver.tscn`)
- "YOU ESCAPED!", "TIME'S UP" or "CAUGHT BY THE GHOST".
- Final score.
- The exact prompt `Press Z to play again`.
- Z ignored for the first second, then a fresh press is required.

## 8. Visual and Audio Direction

**Style:** Dark pixel-art haunted building, high-contrast purple (ghost), cyan (relics, ward) and warm yellow (player).

**Build order:** colored rectangles first so gameplay is proven, then swap in the art, font and menu resources from `assets/`.

**Readability:**
- The player (yellow) is always distinguishable from the ghost (purple).
- Spawn, stun, immunity and ward each have a clear visual (fade-in, cyan tint, blinking, expanding ring).
- Any flash or shake is brief and never hides a threat.
- Player, ghost and text readable from about 2 m, tested fullscreen.

**Audio (M5):** ambient haunted loop, plus short sounds for relic pickup, dash, ward, damage and exit unlock. Audio is never required to notice a threat.

## 9. Technical Design

**Engine:** Godot 4.x, scene-based, no plugins, no runtime dependencies.

**Project layout** (project root = `Haunted_Shift/`):

```text
scenes/Main.tscn          + Main.gd        (state, round timer, score, HUD, screens)
scenes/skeptic/Skeptic.tscn + Skeptic.gd   (movement, health hits, ward, dash)
scenes/ghost/Ghost.tscn   + Ghost.gd       (AI state machine, contact damage)
scenes/relic/Relic.tscn   + Relic.gd       (pickup)
scenes/ui/StartMenu.tscn
scenes/ui/GameOver.tscn   + GameOver.gd
scripts/InputManager.gd                    (autoload)
assets/ (font, art, resources)
```

**Core systems:**
1. `InputManager` (autoload): the six-key mapping, held state, `direction()`, `consume_press()` and `flush()`.
2. `Skeptic`: movement, dash, ward, immunity, knockback, `take_hit()`.
3. `Ghost`: Spawning / Wander / Chase / Stunned, with HitBox damage.
4. `Main`: Title / Playing / Game Over state, timer, score, relic count, win/lose, restart. It replaces the separate RoundManager and ScreenManager from the first draft to keep the project small.

**Collision layers:** Walls 1. Skeptic 2 (mask 1). Ghost 3 (mask 1). Ghost HitBox mask 2. Relic mask 2.

**Window:** 1280x720, stretch `canvas_items`, aspect `keep`, resizable.

## 10. Milestones

Each milestone must leave the game runnable and playable before the next starts.

| # | Build | Playable result |
|---|---|---|
| **M1** | Project settings, `InputManager`, Skeptic, StartMenu, GameOver, bare Main | Title, move around, game over, Z, play again |
| **M2** | Relics, exit, HUD, timer, win/lose | A complete round you can win or run out of time |
| **M3** | Ghost AI and safe contact damage | A real round with a threat |
| **M4** | Ward and Dash tuning, gradual ghost speed-up | Full loop, cooldowns shown in the HUD |
| **M5** | Art, font, menu resources, audio, polish | Demo-ready build |
| **Gate** | Full compliance checklist run on the real build | Ready for the event |

## 11. Scope Boundaries

**Must-have**
- Complete title-to-results round with fast restart.
- Six-key-only controls with held and fresh-press handling.
- 8 relics, scoring, exit, 150 s timer.
- One ghost AI with forgiving damage.
- Ward and Dash with cooldowns.
- Local, offline run documented in `README.md`.

**Optional, only after compliance**
- A second ghost type or patrol routes.
- Static furniture obstacles the ghost has to slide around.
- Randomised relic positions.
- High-score persistence.
- Extra particles and effects.

**Out of scope**
- Pause screen, menus needing extra keys, mouse aiming.
- Online multiplayer, login, online services.
- Anything needing rapid tapping or frame-perfect timing.

## 12. Compliance and Acceptance Criteria

Before the demo, verify (this mirrors the `AGENTS.md` checklist):

- Only the four arrows, Z and Space are used. All key reads live in `InputManager.gd`.
- No mouse or click handlers and no Button nodes exist.
- Holding an arrow moves continuously, releasing stops, and diagonals work.
- Z works for start, ward and restart (Caps Lock on and off). Holding Z through game over does not restart.
- Space is used only for dash, is needed at most once per 2.5 s, and never repeats when held.
- Holding Up + Down (or Left + Right) together never breaks anything.
- Releasing every key at once never causes an instant loss.
- Accidental Z or Space presses are harmless on every screen.
- No mashing, no frame-perfect timing, and at least 3 s before the ghost can hurt you.
- Text, player and ghost are readable at demo distance.
- No pop-ups, alerts or new windows. Alt-Tab does not leave stuck keys.
- Title shows `Press Z to start` and the controls. Game over shows the score and `Press Z to play again`.
- The game launches locally using the steps in `README.md`.

**Definition of Done:** A first-time player understands the goal from the title screen, starts with Z, moves immediately, survives or loses a full round, sees the result, and restarts with Z, using nothing but the six allowed keys.