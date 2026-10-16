# HAUNTED SHIFT — Godot Implementation Instructions

This document is the copy/paste implementation guide for a small, playable **Godot 4.x** version of HAUNTED SHIFT. It uses GDScript, one main scene, and one autoload for all keyboard input. The game is drawn with Godot's built-in `_draw()` methods, so no external art or internet connection is required.

> **Rule priority:** `AGENTS.md` is mandatory and overrides this document. Use only the four arrow keys, Z, and Space. Do not add mouse input, clickable buttons, extra keyboard shortcuts, or other input devices.

## 1. Project settings

1. Create or open your Godot 4 project.
2. Open **Project → Project Settings → Display → Window**.
3. Set:
   - **Viewport Width:** `960`
   - **Viewport Height:** `540`
   - **Window Width Override:** `1280` (optional)
   - **Window Height Override:** `720` (optional)
   - **Stretch Mode:** `canvas_items`
   - **Stretch Aspect:** `keep`
4. Under **Application → Run**, set **Main Scene** to `res://Main.tscn` after creating it.
5. No custom Input Map actions are required. The `InputManager` below reads the six allowed physical keys centrally.
6. Use Godot 4.x. This guide uses Godot 4 GDScript syntax.

## 2. Create the files and scene tree

Create these files:

```text
res://
├── AGENTS.md                      # Keep the mandatory rules file in the project root
├── README.md                      # Add the run instructions from section 8
├── instructions.md                # This document
├── Main.tscn
└── scripts/
    ├── InputManager.gd
    └── Main.gd
```

Create `scripts/` if it does not exist.

### Create the main scene

1. Create a new **2D Scene** with a `Node2D` root.
2. Rename the root to `Main`.
3. Attach `res://scripts/Main.gd` to the root.
4. Save the scene as `res://Main.tscn`.
5. In **Project → Project Settings → Autoload**, add `res://scripts/InputManager.gd` with the node name **InputManager** and enable it.
6. Set `Main.tscn` as the project’s main scene.

The game world, player, ghosts, collectibles, HUD, title screen, and results screen are drawn by `Main.gd`; therefore, no extra child nodes are needed. The visual entities are simple vector shapes generated at runtime.

## 3. `scripts/InputManager.gd`

Paste this entire code into `res://scripts/InputManager.gd`. It must be the only script that reads keyboard events.

```gdscript
extends Node

# Centralized six-key input. Other scripts query these actions; they do not
# inspect InputEvent or key constants themselves.

var held := {
    "up": false,
    "down": false,
    "left": false,
    "right": false,
    "primary": false,
    "secondary": false,
}

var just_pressed := {
    "up": false,
    "down": false,
    "left": false,
    "right": false,
    "primary": false,
    "secondary": false,
}

var _key_to_action := {
    KEY_UP: "up",
    KEY_DOWN: "down",
    KEY_LEFT: "left",
    KEY_RIGHT: "right",
    KEY_Z: "primary",
    KEY_SPACE: "secondary",
}

func _ready() -> void:
    # Run after normal gameplay nodes so one-frame press flags remain readable
    # throughout the frame, then reset at the end of the frame.
    process_priority = 1000
    get_window().focus_exited.connect(_on_focus_exited)

func _input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event := event as InputEventKey
        var key_code: int = key_event.physical_keycode
        if key_code == KEY_NONE:
            key_code = key_event.keycode

        if not _key_to_action.has(key_code):
            return

        var action: String = _key_to_action[key_code]

        if key_event.pressed and not key_event.echo:
            if not held[action]:
                just_pressed[action] = true
            held[action] = true
        elif not key_event.pressed:
            held[action] = false

        # Stop page scrolling if exported to a browser. This does not block
        # keyboard focus or use any non-keyboard input.
        if key_code in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_SPACE]:
            get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
    # Input is polled by gameplay nodes earlier in this frame.
    for action in just_pressed.keys():
        just_pressed[action] = false

func is_held(action: String) -> bool:
    return bool(held.get(action, false))

func was_just_pressed(action: String) -> bool:
    return bool(just_pressed.get(action, false))

func clear_all() -> void:
    for action in held.keys():
        held[action] = false
        just_pressed[action] = false

func _on_focus_exited() -> void:
    clear_all()
```

**Important:** Keep the Autoload node name exactly `InputManager`. Do not add direct key checks in `Main.gd`.

## 4. `scripts/Main.gd`

Attach this complete script to the `Main` `Node2D`. It includes movement, collectibles, ghosts, collision handling, the ward pulse, dash, timer, title screen, win/loss screen, and restart.

```gdscript
extends Node2D

enum GameState { TITLE, PLAYING, RESULTS }

const WORLD_SIZE := Vector2(960.0, 540.0)
const PLAYER_RADIUS := 13.0
const PLAYER_SPEED := 220.0
const DASH_SPEED := 520.0
const DASH_DURATION := 0.16
const DASH_COOLDOWN := 2.5
const WARD_RANGE := 125.0
const WARD_COOLDOWN := 1.25
const ROUND_TIME := 150.0
const REQUIRED_OBJECTS := 8
const GHOST_RADIUS := 14.0
const GHOST_SPEED_START := 62.0
const DAMAGE_IMMUNITY := 1.15

const ARENA := Rect2(28.0, 66.0, 904.0, 446.0)
const EXIT_POSITION := Vector2(886.0, 286.0)

var state: GameState = GameState.TITLE
var player_position := Vector2(130.0, 285.0)
var last_direction := Vector2.RIGHT
var player_health := 3
var score := 0
var objects_collected := 0
var time_left := ROUND_TIME
var result_text := ""
var dash_timer := 0.0
var dash_cooldown_left := 0.0
var ward_cooldown_left := 0.0
var damage_immunity_left := 0.0
var round_elapsed := 0.0
var spawn_warning_left := 0.0
var extra_ghost_spawned := false
var ward_flash_left := 0.0
var dash_direction := Vector2.RIGHT

var collectibles: Array[Vector2] = []
var ghosts: Array[Dictionary] = []

func _ready() -> void:
    get_window().size = Vector2i(1280, 720)
    queue_redraw()

func _process(delta: float) -> void:
    # All screen transitions use a fresh Z press. Holding Z cannot skip screens.
    match state:
        GameState.TITLE:
            if InputManager.was_just_pressed("primary"):
                _start_game()
            # Space on the title screen is deliberately harmless.
        GameState.PLAYING:
            _update_game(delta)
        GameState.RESULTS:
            round_elapsed += delta
            if InputManager.was_just_pressed("primary") and round_elapsed >= 1.0:
                _start_game()

    queue_redraw()

func _start_game() -> void:
    InputManager.clear_all()
    state = GameState.PLAYING
    player_position = Vector2(130.0, 285.0)
    last_direction = Vector2.RIGHT
    player_health = 3
    score = 0
    objects_collected = 0
    time_left = ROUND_TIME
    round_elapsed = 0.0
    dash_timer = 0.0
    dash_cooldown_left = 0.0
    ward_cooldown_left = 0.0
    damage_immunity_left = 0.0
    ward_flash_left = 0.0
    spawn_warning_left = 0.0
    extra_ghost_spawned = false
    result_text = ""
    collectibles.clear()
    ghosts.clear()

    # Fixed, reachable positions keep the first run fair and testable.
    var object_positions: Array[Vector2] = [
        Vector2(250, 120), Vector2(385, 170), Vector2(540, 105),
        Vector2(720, 150), Vector2(300, 370), Vector2(470, 420),
        Vector2(650, 355), Vector2(790, 430), Vector2(170, 440),
        Vector2(575, 250), Vector2(400, 285), Vector2(750, 270)
    ]
    for p in object_positions:
        collectibles.append(p)

    _add_ghost(Vector2(600, 155), 0)
    _add_ghost(Vector2(720, 390), 1)

func _add_ghost(spawn_position: Vector2, ghost_type: int) -> void:
    ghosts.append({
        "position": spawn_position,
        "type": ghost_type,
        "speed": GHOST_SPEED_START + float(ghost_type) * 8.0,
        "stun": 0.0,
        "phase": randf_range(0.0, TAU)
    })

func _update_game(delta: float) -> void:
    round_elapsed += delta
    time_left = maxf(0.0, time_left - delta)
    dash_cooldown_left = maxf(0.0, dash_cooldown_left - delta)
    ward_cooldown_left = maxf(0.0, ward_cooldown_left - delta)
    damage_immunity_left = maxf(0.0, damage_immunity_left - delta)
    ward_flash_left = maxf(0.0, ward_flash_left - delta)

    if time_left <= 0.0:
        _finish_round(false, "TIME'S UP")
        return

    # Telegraph a new ghost for 1.5 seconds before it enters the arena.
    if not extra_ghost_spawned and round_elapsed >= 32.0:
        if spawn_warning_left <= 0.0:
            spawn_warning_left = 1.5
        else:
            spawn_warning_left -= delta
            if spawn_warning_left <= 0.0:
                extra_ghost_spawned = true
                _add_ghost(Vector2(850.0, 100.0), 2)

    var movement := Vector2.ZERO
    if InputManager.is_held("up"):
        movement.y -= 1.0
    if InputManager.is_held("down"):
        movement.y += 1.0
    if InputManager.is_held("left"):
        movement.x -= 1.0
    if InputManager.is_held("right"):
        movement.x += 1.0

    if movement.length_squared() > 0.0:
        movement = movement.normalized()
        last_direction = movement

    # Fresh Space press starts a short dash; holding Space cannot retrigger it.
    if InputManager.was_just_pressed("secondary") and dash_cooldown_left <= 0.0:
        dash_direction = last_direction
        dash_timer = DASH_DURATION
        dash_cooldown_left = DASH_COOLDOWN

    if dash_timer > 0.0:
        dash_timer = maxf(0.0, dash_timer - delta)
        player_position += dash_direction * DASH_SPEED * delta
    else:
        player_position += movement * PLAYER_SPEED * delta

    player_position.x = clampf(player_position.x, ARENA.position.x + PLAYER_RADIUS, ARENA.end.x - PLAYER_RADIUS)
    player_position.y = clampf(player_position.y, ARENA.position.y + PLAYER_RADIUS, ARENA.end.y - PLAYER_RADIUS)

    # Fresh Z press triggers a defensive pulse. It pushes nearby ghosts away.
    if InputManager.was_just_pressed("primary") and ward_cooldown_left <= 0.0:
        ward_cooldown_left = WARD_COOLDOWN
        ward_flash_left = 0.22
        for i in range(ghosts.size()):
            var ghost_position: Vector2 = ghosts[i]["position"]
            var offset: Vector2 = ghost_position - player_position
            if offset.length() <= WARD_RANGE:
                var push_direction := offset.normalized()
                if push_direction == Vector2.ZERO:
                    push_direction = Vector2.RIGHT
                ghosts[i]["position"] = ghost_position + push_direction * 92.0
                ghosts[i]["stun"] = 0.45

    _update_collectibles()
    _update_ghosts(delta)

    if objects_collected >= REQUIRED_OBJECTS and player_position.distance_to(EXIT_POSITION) < 32.0:
        _finish_round(true, "YOU ESCAPED!")
        return

    if player_health <= 0:
        _finish_round(false, "CAUGHT BY THE HAUNTING")

func _update_collectibles() -> void:
    for i in range(collectibles.size() - 1, -1, -1):
        if player_position.distance_to(collectibles[i]) < PLAYER_RADIUS + 12.0:
            collectibles.remove_at(i)
            objects_collected += 1
            score += 100

func _update_ghosts(delta: float) -> void:
    for i in range(ghosts.size()):
        var ghost_position: Vector2 = ghosts[i]["position"]
        var stun_time: float = ghosts[i]["stun"]
        if stun_time > 0.0:
            ghosts[i]["stun"] = maxf(0.0, stun_time - delta)
            continue

        var toward_player := player_position - ghost_position
        if toward_player.length_squared() > 1.0:
            var ghost_speed: float = float(ghosts[i]["speed"])
            ghost_speed += minf(24.0, round_elapsed * 0.10)
            ghost_position += toward_player.normalized() * ghost_speed * delta
        ghosts[i]["position"] = ghost_position

        if player_position.distance_to(ghost_position) < PLAYER_RADIUS + GHOST_RADIUS:
            if damage_immunity_left <= 0.0:
                player_health -= 1
                damage_immunity_left = DAMAGE_IMMUNITY
                # Knock the player away to prevent repeated contact damage.
                var away := (player_position - ghost_position).normalized()
                if away == Vector2.ZERO:
                    away = Vector2.RIGHT
                player_position += away * 48.0
                player_position.x = clampf(player_position.x, ARENA.position.x + PLAYER_RADIUS, ARENA.end.x - PLAYER_RADIUS)
                player_position.y = clampf(player_position.y, ARENA.position.y + PLAYER_RADIUS, ARENA.end.y - PLAYER_RADIUS)

func _finish_round(won: bool, message: String) -> void:
    state = GameState.RESULTS
    result_text = message
    if won:
        score += int(time_left * 5.0)
    # This timer also prevents a held Z from instantly restarting the result.
    round_elapsed = 0.0
    InputManager.clear_all()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("#10111f"))

    if state == GameState.TITLE:
        _draw_title()
        return

    _draw_arena()
    _draw_collectibles()
    _draw_exit()
    _draw_ghosts()
    _draw_player()
    _draw_hud()

    if state == GameState.RESULTS:
        _draw_results()

func _draw_title() -> void:
    draw_rect(Rect2(40, 38, 880, 464), Color("#191a2d"), true, 18.0)
    draw_circle(Vector2(480, 165), 48, Color("#6f4ba8"))
    draw_circle(Vector2(465, 151), 12, Color("#c9f7ff"))
    draw_circle(Vector2(495, 151), 12, Color("#c9f7ff"))
    draw_circle(Vector2(465, 151), 5, Color("#171526"))
    draw_circle(Vector2(495, 151), 5, Color("#171526"))
    draw_string(ThemeDB.fallback_font, Vector2(218, 255), "HAUNTED SHIFT", HORIZONTAL_ALIGNMENT_LEFT, -1, 42, Color("#f2efff"))
    draw_string(ThemeDB.fallback_font, Vector2(255, 300), "COLLECT 8 CURSED OBJECTS. FIND THE EXIT.", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#8fe7f2"))
    draw_string(ThemeDB.fallback_font, Vector2(300, 345), "ARROWS  MOVE     Z  WARD     SPACE  DASH", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#ded9f4"))
    draw_string(ThemeDB.fallback_font, Vector2(340, 405), "Press Z to start", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#ffd76a"))
    draw_string(ThemeDB.fallback_font, Vector2(300, 448), "DODGE GHOSTS. ESCAPE BEFORE TIME RUNS OUT.", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#b9b5ce"))

func _draw_arena() -> void:
    draw_rect(ARENA, Color("#20243a"), true, 12.0)
    # Decorative floor tiles.
    var tile_x := ARENA.position.x + 10.0
    while tile_x < ARENA.end.x:
        draw_line(Vector2(tile_x, ARENA.position.y + 8.0), Vector2(tile_x, ARENA.end.y - 8.0), Color("#292d45"), 1.0)
        tile_x += 48.0
    var tile_y := ARENA.position.y + 8.0
    while tile_y < ARENA.end.y:
        draw_line(Vector2(ARENA.position.x + 8.0, tile_y), Vector2(ARENA.end.x - 8.0, tile_y), Color("#292d45"), 1.0)
        tile_y += 48.0

    # Non-lethal furniture blocks, clearly visible and easy to route around.
    var obstacles: Array[Rect2] = [
        Rect2(345, 95, 42, 82), Rect2(495, 350, 70, 35),
        Rect2(625, 190, 38, 68), Rect2(205, 250, 50, 30)
    ]
    for obstacle in obstacles:
        draw_rect(obstacle, Color("#45415f"), true, 5.0)
        draw_rect(obstacle, Color("#6e6688"), false, 2.0, true)

    if spawn_warning_left > 0.0 and not extra_ghost_spawned:
        draw_circle(Vector2(850, 100), 30.0, Color(0.95, 0.25, 0.55, 0.16))
        draw_arc(Vector2(850, 100), 30.0, 0.0, TAU, 48, Color("#ff729b"), 3.0)
        draw_string(ThemeDB.fallback_font, Vector2(740, 75), "GHOST INCOMING!", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#ff9bb8"))

func _draw_collectibles() -> void:
    for p in collectibles:
        draw_circle(p, 13.0, Color(0.2, 0.95, 0.9, 0.16))
        draw_colored_polygon(PackedVector2Array([
            p + Vector2(0, -10), p + Vector2(8, 0),
            p + Vector2(0, 10), p + Vector2(-8, 0)
        ]), Color("#72f5d9"))
        draw_circle(p, 3.0, Color("#f7ffcf"))

func _draw_exit() -> void:
    var unlocked := objects_collected >= REQUIRED_OBJECTS
    var exit_color := Color("#63f2a6") if unlocked else Color("#a45170")
    draw_rect(Rect2(EXIT_POSITION - Vector2(17, 28), Vector2(34, 56)), exit_color, true, 5.0)
    draw_rect(Rect2(EXIT_POSITION - Vector2(10, 21), Vector2(20, 42)), Color("#171827"), true, 3.0)
    draw_circle(EXIT_POSITION + Vector2(5, 0), 2.5, Color("#ffe58a"))
    var label := "EXIT OPEN" if unlocked else "EXIT LOCKED"
    draw_string(ThemeDB.fallback_font, EXIT_POSITION + Vector2(-42, 43), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, exit_color)

func _draw_ghosts() -> void:
    for ghost in ghosts:
        var p: Vector2 = ghost["position"]
        var stunned: bool = float(ghost["stun"]) > 0.0
        var ghost_color := Color("#8c79ff") if not stunned else Color("#79f3ff")
        draw_circle(p, 21.0, Color(ghost_color.r, ghost_color.g, ghost_color.b, 0.13))
        draw_circle(p, GHOST_RADIUS, ghost_color)
        draw_circle(p + Vector2(-4, -2), 3.0, Color("#ffffff"))
        draw_circle(p + Vector2(4, -2), 3.0, Color("#ffffff"))
        draw_circle(p + Vector2(-4, -2), 1.5, Color("#25213d"))
        draw_circle(p + Vector2(4, -2), 1.5, Color("#25213d"))
        draw_arc(p + Vector2(0, 2), 6.0, 0.2, PI - 0.2, 12, Color("#25213d"), 1.5)

func _draw_player() -> void:
    var player_color := Color("#ffe17a")
    if damage_immunity_left > 0.0 and int(Time.get_ticks_msec() / 90) % 2 == 0:
        player_color = Color("#ffffff")
    draw_circle(player_position, 23.0, Color(0.95, 0.78, 0.3, 0.12))
    draw_circle(player_position, PLAYER_RADIUS, player_color)
    draw_circle(player_position + Vector2(-4, -3), 2.5, Color("#24243b"))
    draw_circle(player_position + Vector2(4, -3), 2.5, Color("#24243b"))
    if ward_flash_left > 0.0:
        var radius := WARD_RANGE * (1.0 - ward_flash_left / 0.22)
        draw_arc(player_position, radius, 0.0, TAU, 48, Color("#73f7ff"), 3.0)
    if dash_timer > 0.0:
        draw_line(player_position, player_position - dash_direction * 34.0, Color("#ffd76a"), 5.0)

func _draw_hud() -> void:
    draw_rect(Rect2(28, 15, 904, 40), Color("#191a2d"), true, 8.0)
    draw_string(ThemeDB.fallback_font, Vector2(44, 41), "HEALTH: " + "♥ ".repeat(player_health), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#ff7898"))
    draw_string(ThemeDB.fallback_font, Vector2(270, 41), "SCORE: " + str(score), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#f2efff"))
    draw_string(ThemeDB.fallback_font, Vector2(440, 41), "OBJECTS: " + str(objects_collected) + "/" + str(REQUIRED_OBJECTS), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#72f5d9"))
    draw_string(ThemeDB.fallback_font, Vector2(730, 41), "TIME: " + str(ceili(time_left)), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#ffd76a"))
    var dash_text := "READY" if dash_cooldown_left <= 0.0 else str(snappedf(dash_cooldown_left, 0.1))
    var ward_text := "READY" if ward_cooldown_left <= 0.0 else str(snappedf(ward_cooldown_left, 0.1))
    draw_string(ThemeDB.fallback_font, Vector2(42, 530), "SPACE DASH: " + dash_text + "     Z WARD: " + ward_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#b9b5ce"))
    if objects_collected < REQUIRED_OBJECTS:
        draw_string(ThemeDB.fallback_font, Vector2(590, 530), "COLLECT " + str(REQUIRED_OBJECTS - objects_collected) + " MORE TO OPEN EXIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#8fe7f2"))
    elif player_position.distance_to(EXIT_POSITION) >= 32.0:
        draw_string(ThemeDB.fallback_font, Vector2(630, 530), "EXIT OPEN: REACH THE DOOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#63f2a6"))

func _draw_results() -> void:
    draw_rect(Rect2(130, 115, 700, 310), Color(0.06, 0.06, 0.12, 0.94), true, 18.0)
    var title_color := Color("#72f5d9") if result_text == "YOU ESCAPED!" else Color("#ff7898")
    draw_string(ThemeDB.fallback_font, Vector2(255, 205), result_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, title_color)
    draw_string(ThemeDB.fallback_font, Vector2(335, 260), "FINAL SCORE: " + str(score), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#f2efff"))
    draw_string(ThemeDB.fallback_font, Vector2(310, 325), "Press Z to play again", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("#ffd76a"))
    draw_string(ThemeDB.fallback_font, Vector2(335, 365), "ARROWS MOVE  |  Z WARD  |  SPACE DASH", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#b9b5ce"))
```

## 5. Make the `.tscn` file

If you created the scene through the editor and attached `Main.gd`, Godot generates `Main.tscn` for you. That is preferred. If you want to create it manually, use:

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/Main.gd" id="1_main"]

[node name="Main" type="Node2D"]
script = ExtResource("1_main")
```

## 6. First run checklist

1. Confirm `InputManager.gd` is enabled as an Autoload named exactly `InputManager`.
2. Confirm `Main.tscn` has `Main.gd` attached.
3. Run the project.
4. The title screen must show `PRESS Z TO START` visually. The title prompt uses the exact required wording: `Press Z to start`.
5. Press and release Z to start.
6. Hold an arrow to move continuously, then release it to stop.
7. Press Space once to dash; holding it must not repeat the dash.
8. Press Z once to activate the ward pulse; holding it must not repeat the pulse.
9. Collect eight objects, then reach the exit to win.
10. Take three hits or wait out the timer to lose.
11. On the results screen, hold Z: it must not restart automatically. Release Z, wait at least one second, then press Z to restart.
12. Alt-tab away while moving, then return. Movement must not continue because focus loss clears held keys.

## 7. Important prototype limitations

This first implementation is a playable arcade prototype, not a finished commercial game. It uses simple drawn geometry and a single arena rather than a tile-based mansion. The furniture is decorative in this version; it does not block movement. That keeps collision behavior forgiving while the core loop is tested. Add solid maze walls, more room layouts, audio, and polished sprites only after the first playable build passes the mandatory checklist.

Before submitting, verify the project by running it in your installed Godot version. If Godot reports a parser error, fix that error before adding features; do not pile more systems on top of a broken baseline.

## 8. `README.md` run instructions

Create `README.md` with:

```markdown
# HAUNTED SHIFT

A small top-down arcade horror game made with Godot 4 and GDScript.

## Run locally
1. Open the project folder in Godot 4.
2. Set `res://Main.tscn` as the main scene if it is not already selected.
3. Press F6 to run the current scene, or F5 to run the project.

## Controls
- Arrow keys: move
- Z: start / defensive ward / restart
- Space: dash

No internet connection is required during play.
```

## 9. Compliance checklist — run after every change

- [ ] Only Up/Down/Left/Right Arrows, Z and Space are used anywhere in the game code.
- [ ] No mouse/touch/click handlers exist.
- [ ] Holding an arrow gives continuous movement; releasing stops it; no reliance on key-repeat.
- [ ] Z works for start, confirm and restart; both `z` and `Z` accepted through the physical Z key.
- [ ] Screen changes need a fresh Z press; holding Z through game over does not restart instantly.
- [ ] Space is used only for dash in gameplay, has a cooldown, and is not needed more than about once every 2 seconds.
- [ ] No mechanic needs opposite keys held together.
- [ ] Releasing all keys at once never causes an instant loss.
- [ ] An accidental Z or Space press is never harmful.
- [ ] No button mashing, frame-perfect timing, or reactions faster than 1 second required.
- [ ] Text, player and threats are readable from about 2 metres.
- [ ] Nothing steals focus (no pop-ups, alerts or new windows).
- [ ] Title screen says `Press Z to start` and shows the controls.
- [ ] Game over says `Press Z to play again`.
- [ ] Runs locally with the command in `README.md`.

**Do not mark the checklist complete until you have run and tested the game.**
