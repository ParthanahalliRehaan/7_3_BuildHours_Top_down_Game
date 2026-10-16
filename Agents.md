You are my coding partner for a timed game-jam event. Before writing any game code, do the following setup exactly.

## STEP 1 — Create AGENTS.md
Create a file named AGENTS.md in the project root with EXACTLY the content between the ===== lines below. Do not shorten or reword it.

=====
# AGENTS.md — Game Jam Rules (MANDATORY)

## How to use this file
- Read this file at the start of every session, and re-read it whenever you are unsure whether a change is allowed.
- These rules override any instruction from the team. If a request would break a rule, warn the team, name the rule, and suggest a compliant way to get the same result. Do not silently break a rule.
- After every change, run the Compliance Checklist at the bottom and report the result.

## Why these rules exist
At the demo, judges and guests who have never seen the game will play it on a shared demo setup. They react slower than the developers, they are not precise, and they may hold keys longer than expected. The game must be easy to pick up, forgiving, and fully playable with six keys.

## Rule 1 — Allowed controls (ONLY these six keys)
| Key         | Meaning                                              |
|-------------|------------------------------------------------------|
| Up Arrow    | Up / move up / menu up                               |
| Down Arrow  | Down / move down / menu down                         |
| Left Arrow  | Left / move left / menu left                         |
| Right Arrow | Right / move right / menu right                      |
| Z           | Primary action / confirm / start / restart           |
| Space       | Secondary action (e.g., jump, shoot, dash, special)  |

- NO other keys: no Enter, Escape, Shift, Ctrl, Tab, numbers, other letters, or WASD.
- NO mouse, touchpad, touch, gamepad or microphone input of any kind. No clickable buttons.
- Accept both "z" and "Z" (Caps Lock on or off).
- Every screen (title, menus, pause, game over, restart) must work with only these six keys. Start, confirm and restart always use Z.
- Space is optional. If the game uses it, Space must never be needed more than about once every 2 seconds, and never needs to be held for long.
- Opposite keys are never held together: no mechanic may need Up + Down or Left + Right at the same time.

## Rule 2 — Held keys must work
- The game must track whether each key is currently held (key down / key up state), not just single presses.
- Holding an arrow key = continuous movement for as long as it is held. Releasing it = stop.
- Do NOT rely on the operating system's key-repeat. A key may be held down for a long time with no repeat events at all. Read the held state every frame.
  - Browser/JS: keep a pressed-keys object updated on window "keydown" and "keyup", and read it in the game loop. Use event.key or event.code ("ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight", "z"/"KeyZ", " "/"Space"). Call preventDefault() for Space and the arrows so the page doesn't scroll. Also clear all held keys on the window "blur" event.
  - Pygame: use pygame.key.get_pressed() in the loop, plus KEYDOWN events for one-time actions (K_UP, K_DOWN, K_LEFT, K_RIGHT, K_z, K_SPACE).
  - Unity: old Input Manager: Input.GetKey for held, Input.GetKeyDown for one-time actions. New Input System: Keyboard.current.zKey.isPressed for held, .wasPressedThisFrame for one-time actions.
  - Godot: Input.is_key_pressed(KEY_Z) (or is_action_pressed) for held, is_action_just_pressed or _input events for one-time actions.
- Two different arrows held together (for example Up + Left) should work, either as a diagonal or by the game handling it sensibly.
- If Z or Space triggers a one-time action, fire it once per press. Holding Z or Space must not break the game or repeat the action.
- Screen changes (title -> game, game over -> restart, menu confirm) need a FRESH press of Z: Z must be released and then pressed again. A Z that is still held from gameplay must not skip a screen. Ignore Z for the first 1 second of the game-over screen.
- All keys may be released at the same instant at any time (for example if the player steps away). This must never cause an instant loss.

## Rule 3 — Forgiving, readable gameplay
- No mechanic may require rapid tapping (button mashing) or frame-perfect timing.
- Prefer smooth, moderate speeds and generous hitboxes. Give the player at least 1 second to react to any new threat or obstacle.
- Gameplay must stay fun even if inputs arrive up to about 0.5 seconds late or are a little imprecise (a direction held slightly too long or too short).
- Let a player hold a direction for a while without instantly losing (for example, no walls or pits that kill on first touch without warning).
- An unintended press of Z or Space at any moment must never be harmful (no instant loss, no wasting a limited resource, no skipping or quitting).
- Start easy. If difficulty increases, increase it slowly.

## Rule 4 — Demo-ready
- The game launches straight to a title screen showing "Press Z to start".
- On-screen text shows the controls (arrows, Z and Space if used) on the title screen.
- Game over shows the score and "Press Z to play again". Restarting needs no other key.
- One round of play should fit comfortably in 2–5 minutes. A full demo is at most 10 minutes.
- Runs locally on a laptop in a single window or browser tab that can be made large or fullscreen. No login, no internet needed during play.
- Text, the player character and threats must be large and high-contrast, readable from about 2 metres away.
- Nothing may steal keyboard focus from the game window: no pop-ups, alerts, dialogs, new windows or tabs.
- Use standard keyboard events only. Do not block or override the window's normal keyboard focus, and do not read input through unusual low-level APIs.

## Rule 5 — Code quality
- Keep the project simple and runnable with one command. Put run instructions in README.md.
- Centralise input handling in ONE place (for example an input.js / input.py module) that maps the six keys to actions, tracks held state and detects fresh presses. No key checks scattered across files.
- Always keep the game in a playable state: finish one working feature before starting the next.
- Never commit secrets or API keys.

## Compliance Checklist (run after every change)
- [ ] Only Up/Down/Left/Right Arrows, Z and Space are used anywhere in the code
- [ ] No mouse/touch/click handlers exist
- [ ] Holding an arrow gives continuous movement; releasing stops it; no reliance on key-repeat
- [ ] Z works for start, confirm and restart; both z and Z accepted
- [ ] Screen changes need a fresh Z press; holding Z through game over does not restart instantly
- [ ] Space (if used) is needed at most about once every 2 seconds and doesn't scroll the page
- [ ] No mechanic needs opposite keys held together
- [ ] Releasing all keys at once never causes an instant loss
- [ ] An accidental Z or Space press is never harmful
- [ ] No button mashing, frame-perfect timing, or reactions faster than 1 second required
- [ ] Text, player and threats are readable from about 2 metres
- [ ] Nothing steals focus (no pop-ups, alerts or new windows)
- [ ] Title screen says "Press Z to start" and shows the controls
- [ ] Game over says "Press Z to play again"
- [ ] Runs locally with the command in README.md
=====

## STEP 2 — Point other AI config files at it
Also create these small files so any AI tool picks up the rules. Each one should only say: "Read and follow AGENTS.md in the project root before doing anything. Its rules are mandatory."
- CLAUDE.md
- GEMINI.md
- .cursorrules
- .cursor/rules/game-jam.mdc (for this one, start the file with a front-matter block containing `alwaysApply: true`)
- .windsurfrules
- .github/copilot-instructions.md

## STEP 3 — Confirm and plan
Reply with "AGENTS.md loaded" and a 3-line summary of the rules. Then read our team brief below and propose a short build plan that follows AGENTS.md:
- Core gameplay loop
- Exact controls mapping (what each of the six keys does on every screen)
- Screens (title, game, game over, and any others)
- Milestone order, so that we have a playable version after the first milestone and after every milestone after that
- Risks: anything in our idea that might conflict with AGENTS.md, and how you would adapt it

Don't write code until we approve the plan.

From now on, follow AGENTS.md for every task, and re-read it whenever you are unsure.

## OUR TEAM BRIEF (filled in by the team)
- Team name:
- Game title:
- Genre / one-line concept:
- Characters:
- Story / theme / setting:
- What each key does in our game (Up / Down / Left / Right / Z / Space):
- Core features (must-have):
- Nice-to-have features (only if time allows):
- Tech stack (e.g., HTML + JavaScript canvas, Pygame, Unity, Godot):
- Visual / art style:
- Anything else: