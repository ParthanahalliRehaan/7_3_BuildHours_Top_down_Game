# HAUNTED SHIFT: Build Instructions (Godot 4.x, top-down)

> **Rule priority:** `AGENTS.md` is mandatory and overrides this document. Only six keys exist in this game: Up, Down, Left, Right, **Z**, **Space**. No mouse, no Buttons, no Enter/Esc/WASD, no other devices.

## 0. The game in 5 lines

- You are the **Skeptic**, a night guard who doesn't believe in ghosts. Top-down, one arena.
- Collect **8 cursed relics**, then walk into the **Exit door** before the **150 s** timer ends.
- One **Ghost** (AI) spawns faded for 3 s, then wanders, then chases when you get close.
- You have **3 health**. A hit gives 1.5 s of immunity plus a knockback.
- **Z** = Ward pulse (pushes and stuns the ghost, 1.5 s cooldown). **Space** = Dash (2.5 s cooldown).

## 1. Key mapping on every screen

| Key | Title | Playing | Game Over |
|---|---|---|---|
| Up / Down / Left / Right | nothing | move (hold = continuous, release = stop) | nothing |
| Z | **start** (fresh press) | ward pulse (cooldown, harmless if mashed) | **play again** (fresh press, ignored for first 1 s) |
| Space | nothing | dash (cooldown 2.5 s) | nothing |

Opposite arrows held together cancel to "no movement". They never cause a loss.

## 2. Folder layout

The Godot project root is `Haunted_Shift/` (so `res://` = that folder). Rules files live one level up, in the repo root.

```text
7_3_Buildhours_Top-down_Small_Game/
├── AGENTS.md                  # exact copy from the event
├── CLAUDE.md  GEMINI.md  .cursorrules  .windsurfrules
├── .cursor/rules/game-jam.mdc
├── .github/copilot-instructions.md
├── README.md                  # run instructions (section 10)
├── instructions.md            # this file
└── Haunted_Shift/             # Godot project (project.godot lives here)
    ├── scenes/
    │   ├── Main.tscn
    │   ├── skeptic/Skeptic.tscn
    │   ├── ghost/Ghost.tscn
    │   ├── relic/Relic.tscn
    │   └── ui/StartMenu.tscn
    │   └── ui/GameOver.tscn
    ├── scripts/InputManager.gd      # autoload, the ONLY place that reads keys
    ├── scenes/skeptic/Skeptic.gd
    ├── scenes/ghost/Ghost.gd
    ├── scenes/relic/Relic.gd
    ├── scenes/ui/GameOver.gd
    ├── scenes/Main.gd
    └── assets/ (font/, art/, resources/)
```

**No `Pause` scene.** Pausing needs a 7th key (Esc/P), and Z/Space can't be used because an accidental press must never be harmful. Skipping it keeps us compliant. The round is only 2.5 minutes.

## 3. Project Settings (do this first)

1. **Display → Window → Size:** Viewport Width `1280`, Height `720`. **Stretch → Mode** `canvas_items`, **Aspect** `keep`. Leave the window resizable (so it can go fullscreen via the OS).
2. **GUI → Theme → Custom Font:** pick your font from `assets/font/` (all Labels use it automatically).
3. **Autoload:** add `res://scripts/InputManager.gd`, node name exactly `InputManager`, enabled.
4. **Application → Run → Main Scene:** `res://scenes/Main.tscn` (after you create it).
5. Leave **Input Devices → Pointing → Emulate Touch From Mouse** OFF. Do not add anything to the Input Map.

**Global UI rules:** use only `Label` and `ColorRect` for UI. **Never** add a `Button`, `LineEdit`, `PopupMenu` or anything that takes focus. Every `ColorRect` gets **Mouse → Filter = Ignore**.

## 4. Collision layers (set once, never touch again)

Editor path: select node → Inspector → **Collision → Layer / Mask** (tick only the numbers listed).

| Node | Layer | Mask |
|---|---|---|
| Walls (StaticBody2D) | 1 | none |
| Skeptic (CharacterBody2D) | 2 | 1 |
| Ghost (CharacterBody2D) | 3 | 1 |
| Ghost → HitBox (Area2D) | none | 2 |
| Relic (Area2D) | none | 2 |

Result: skeptic and ghost both collide with walls only. They never shove each other. Damage is handled by the HitBox.

## 5. `scripts/InputManager.gd` (the ONLY key-reading file)

```gdscript
extends Node

# Six keys only. Held state is polled every frame (no OS key-repeat needed).
# Presses are latched once and consumed once, so holding Z/Space never repeats.

const KEYS := {
	"up": KEY_UP, "down": KEY_DOWN, "left": KEY_LEFT, "right": KEY_RIGHT,
	"primary": KEY_Z, "secondary": KEY_SPACE,
}

var _held := {}
var _latched := {}
var _needs_release := {}

func _ready() -> void:
	process_priority = -1000  # run before everything else each frame
	for a in KEYS:
		_held[a] = false
		_latched[a] = false
		_needs_release[a] = false

func _process(_delta: float) -> void:
	if not get_window().has_focus():
		flush()
		for a in _held:
			_held[a] = false
		return
	for a in KEYS:
		var now: bool = Input.is_key_pressed(KEYS[a])
		if _needs_release[a]:
			if not now:
				_needs_release[a] = false
			_held[a] = false
			continue
		if now and not _held[a]:
			_latched[a] = true
		_held[a] = now

func is_held(action: String) -> bool:
	return _held.get(action, false)

# Returns true ONCE per fresh press.
func consume_press(action: String) -> bool:
	if _latched.get(action, false):
		_latched[action] = false
		return true
	return false

# Opposite arrows cancel out. Diagonals are normalised.
func direction() -> Vector2:
	var x := int(_held["right"]) - int(_held["left"])
	var y := int(_held["down"]) - int(_held["up"])
	return Vector2(x, y).normalized()

# Call on EVERY screen change. Drops queued presses, and a Z/Space that is
# still physically held must be released before it counts as a fresh press.
func flush() -> void:
	for a in KEYS:
		_latched[a] = false
	_needs_release["primary"] = true
	_needs_release["secondary"] = true
```

## 6. Build steps, scene by scene

Colours are placeholders (rectangles first, art comes at the end). Sizes are big on purpose: readable from 2 m.

### 6.1 `Skeptic.tscn`

1. New Scene → root **CharacterBody2D**, rename `Skeptic`. Collision: Layer 2, Mask 1.
2. Add child **ColorRect** named `Body`: Position `(-18, -18)`, Size `(36, 36)`, Color `#ffe17a`, Mouse Filter Ignore.
3. Add child **CollisionShape2D** → Shape: new **CircleShape2D**, Radius `16`.
4. Attach `scenes/skeptic/Skeptic.gd`, save as `scenes/skeptic/Skeptic.tscn`.

```gdscript
extends CharacterBody2D

signal hit

const SPEED := 220.0
const DASH_SPEED := 560.0
const DASH_TIME := 0.16
const DASH_COOLDOWN := 2.5
const WARD_RANGE := 160.0
const WARD_COOLDOWN := 1.5
const IMMUNITY := 1.5
const KNOCK_SPEED := 420.0
const KNOCK_TIME := 0.15

var active := false
var facing := Vector2.RIGHT
var dash_left := 0.0
var dash_cooldown_left := 0.0
var ward_cooldown_left := 0.0
var ward_flash_left := 0.0
var immune_left := 0.0
var knock_left := 0.0
var knock_velocity := Vector2.ZERO

@onready var body_rect: ColorRect = $Body

func _ready() -> void:
	add_to_group("skeptic")

func reset(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	facing = Vector2.RIGHT
	dash_left = 0.0
	dash_cooldown_left = 0.0
	ward_cooldown_left = 0.0
	ward_flash_left = 0.0
	immune_left = 0.0
	knock_left = 0.0
	body_rect.modulate.a = 1.0
	active = true

func _physics_process(delta: float) -> void:
	if not active:
		velocity = Vector2.ZERO
		return

	dash_cooldown_left = maxf(0.0, dash_cooldown_left - delta)
	ward_cooldown_left = maxf(0.0, ward_cooldown_left - delta)
	ward_flash_left = maxf(0.0, ward_flash_left - delta)
	immune_left = maxf(0.0, immune_left - delta)
	body_rect.modulate.a = 0.4 if (immune_left > 0.0 and int(immune_left * 10.0) % 2 == 0) else 1.0

	var dir := InputManager.direction()
	if dir != Vector2.ZERO:
		facing = dir

	# Fresh presses only. Pressing during cooldown is harmless.
	if InputManager.consume_press("secondary") and dash_cooldown_left <= 0.0:
		dash_left = DASH_TIME
		dash_cooldown_left = DASH_COOLDOWN
	if InputManager.consume_press("primary") and ward_cooldown_left <= 0.0:
		_use_ward()

	if knock_left > 0.0:
		knock_left -= delta
		velocity = knock_velocity
	elif dash_left > 0.0:
		dash_left -= delta
		velocity = facing * DASH_SPEED
	else:
		velocity = dir * SPEED  # released keys => dir is zero => stop
	move_and_slide()
	queue_redraw()

func _use_ward() -> void:
	ward_cooldown_left = WARD_COOLDOWN
	ward_flash_left = 0.25
	for g in get_tree().get_nodes_in_group("ghost"):
		if global_position.distance_to(g.global_position) <= WARD_RANGE:
			g.stun(global_position)

# Called by the Ghost's HitBox. Ignores hits while immune.
func take_hit(from_pos: Vector2) -> void:
	if not active or immune_left > 0.0:
		return
	immune_left = IMMUNITY
	knock_left = KNOCK_TIME
	knock_velocity = (global_position - from_pos).normalized() * KNOCK_SPEED
	hit.emit()

func _draw() -> void:
	if ward_flash_left > 0.0:
		var r := WARD_RANGE * (1.0 - ward_flash_left / 0.25)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color("#73f7ff"), 4.0)
```

### 6.2 `Ghost.tscn` (one AI ghost)

1. New Scene → root **CharacterBody2D**, rename `Ghost`. Collision: Layer 3, Mask 1.
2. Child **ColorRect** `Body`: Position `(-22, -22)`, Size `(44, 44)`, Color `#8c79ff`, Mouse Filter Ignore.
3. Child **CollisionShape2D**: new **CircleShape2D**, Radius `20`.
4. Child **Area2D** named `HitBox`: Layer none, **Mask 2 only**. Under it add **CollisionShape2D** with **CircleShape2D** Radius `18` (smaller than the body, so it is forgiving).
5. Attach `scenes/ghost/Ghost.gd`, save as `scenes/ghost/Ghost.tscn`.

**AI = 4-state machine:** `SPAWNING` (3 s, faded, harmless) → `WANDER` (random points) → `CHASE` (sees you within 420 px, gives up beyond 560 px) → `STUNNED` (1.5 s after a Ward, harmless). Chase speed starts slow (95, you run at 220) and creeps up to 130 over the round.

```gdscript
extends CharacterBody2D

enum State { SPAWNING, WANDER, CHASE, STUNNED }

const WANDER_SPEED := 60.0
const BASE_CHASE_SPEED := 95.0
const MAX_EXTRA_SPEED := 35.0
const SIGHT_RANGE := 420.0
const LOSE_RANGE := 560.0
const SPAWN_TIME := 3.0
const STUN_TIME := 1.5
const ARENA := Rect2(100, 140, 1080, 500)

var active := false
var state := State.SPAWNING
var timer := 0.0
var elapsed := 0.0
var wander_target := Vector2.ZERO

@onready var body_rect: ColorRect = $Body
@onready var hit_box: Area2D = $HitBox

func _ready() -> void:
	add_to_group("ghost")

func reset(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	elapsed = 0.0
	timer = SPAWN_TIME
	state = State.SPAWNING
	_pick_wander()
	active = true

func stun(from_pos: Vector2) -> void:
	if state == State.SPAWNING:
		return
	state = State.STUNNED
	timer = STUN_TIME
	velocity = (global_position - from_pos).normalized() * 380.0

func _pick_wander() -> void:
	wander_target = Vector2(
		randf_range(ARENA.position.x, ARENA.end.x),
		randf_range(ARENA.position.y, ARENA.end.y))
	timer = 2.5

func _physics_process(delta: float) -> void:
	if not active:
		velocity = Vector2.ZERO
		return
	elapsed += delta
	var skeptic := get_tree().get_first_node_in_group("skeptic") as Node2D
	var dist := INF
	if skeptic:
		dist = global_position.distance_to(skeptic.global_position)

	match state:
		State.SPAWNING:
			timer -= delta
			body_rect.modulate = Color(1, 1, 1, 0.3 + 0.15 * sin(elapsed * 12.0))
			velocity = Vector2.ZERO
			if timer <= 0.0:
				state = State.WANDER
				body_rect.modulate = Color.WHITE
			return
		State.STUNNED:
			timer -= delta
			body_rect.modulate = Color("#79f3ff")
			velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
			if timer <= 0.0:
				state = State.WANDER
				_pick_wander()
				body_rect.modulate = Color.WHITE
		State.WANDER:
			timer -= delta
			if timer <= 0.0 or global_position.distance_to(wander_target) < 20.0:
				_pick_wander()
			velocity = (wander_target - global_position).normalized() * WANDER_SPEED
			if dist < SIGHT_RANGE:
				state = State.CHASE
		State.CHASE:
			var speed := BASE_CHASE_SPEED + minf(MAX_EXTRA_SPEED, elapsed * 0.3)
			velocity = (skeptic.global_position - global_position).normalized() * speed
			if dist > LOSE_RANGE:
				state = State.WANDER
				_pick_wander()

	move_and_slide()

	# Contact damage (only while awake, not stunned)
	if state == State.WANDER or state == State.CHASE:
		for b in hit_box.get_overlapping_bodies():
			if b.is_in_group("skeptic"):
				b.take_hit(global_position)
```

### 6.3 `Relic.tscn`

1. New Scene → root **Area2D**, rename `Relic`. Layer none, **Mask 2 only**.
2. Child **ColorRect** `Body`: Position `(-14, -14)`, Size `(28, 28)`, Rotation `45°`, Color `#72f5d9`, Mouse Filter Ignore.
3. Child **CollisionShape2D**: new **CircleShape2D**, Radius `24` (generous pickup).
4. Attach `scenes/relic/Relic.gd`, save as `scenes/relic/Relic.tscn`.

```gdscript
extends Area2D

signal collected

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("skeptic"):
		collected.emit()
		queue_free()
```

### 6.4 `StartMenu.tscn`

Root **CanvasLayer** named `StartMenu`, Layer `10`. Children (all Mouse Filter Ignore):

| Node | Type | Setup |
|---|---|---|
| `Bg` | ColorRect | Position `(0,0)`, Size `(1280,720)`, Color `#10111f` |
| `Title` | Label | Pos `(0,150)`, Size `(1280,110)`, text `HAUNTED SHIFT`, font size `96`, centered |
| `Goal` | Label | Pos `(0,280)`, Size `(1280,50)`, text `Collect 8 relics. Reach the exit.`, size `34`, centered |
| `Controls` | Label | Pos `(0,370)`, Size `(1280,50)`, text `ARROWS = MOVE     Z = WARD     SPACE = DASH`, size `36`, centered |
| `Prompt` | Label | Pos `(0,500)`, Size `(1280,80)`, text `Press Z to start`, size `60`, centered, colour `#ffd76a` |

Centering = Label Settings → Horizontal Alignment `Center` (Theme Overrides → Font Size for the size). No script needed.

### 6.5 `GameOver.tscn`

Root **CanvasLayer** `GameOver`, Layer `10`. Children (all Mouse Filter Ignore):

| Node | Type | Setup |
|---|---|---|
| `Dim` | ColorRect | Pos `(0,0)`, Size `(1280,720)`, Color `#000000d9` |
| `Result` | Label | Pos `(0,160)`, Size `(1280,100)`, size `80`, centered |
| `Score` | Label | Pos `(0,300)`, Size `(1280,70)`, size `56`, centered |
| `Prompt` | Label | Pos `(0,470)`, Size `(1280,70)`, text `Press Z to play again`, size `52`, centered, colour `#ffd76a` |
| `Hint` | Label | Pos `(0,580)`, Size `(1280,40)`, text `ARROWS = MOVE   Z = WARD   SPACE = DASH`, size `28`, centered |

Attach `scenes/ui/GameOver.gd`:

```gdscript
extends CanvasLayer

func show_result(message: String, final_score: int) -> void:
	$Result.text = message
	$Score.text = "SCORE: %d" % final_score
```

### 6.6 `Main.tscn` (the glue)

New Scene → root **Node2D** named `Main`, attach `scenes/Main.gd`, save as `scenes/Main.tscn`. Build this tree exactly:

```text
Main (Node2D)  [Main.gd]
├── World (Node2D)
│   ├── Floor        (ColorRect: Pos (40,80), Size (1200,600), Color #20243a)
│   ├── Walls        (StaticBody2D, Layer 1, Mask none)
│   │   ├── Top      (CollisionShape2D, RectangleShape2D (1280,40), Position (640,60))
│   │   ├── Bottom   (CollisionShape2D, RectangleShape2D (1280,40), Position (640,700))
│   │   ├── Left     (CollisionShape2D, RectangleShape2D (40,720),  Position (20,380))
│   │   └── Right    (CollisionShape2D, RectangleShape2D (40,720),  Position (1260,380))
│   ├── Relics       (Node2D, empty, Main fills it)
│   ├── Exit         (Node2D, Position (1190,380))
│   │   ├── Door     (ColorRect: Pos (-24,-40), Size (48,80), Color #a45170)
│   │   └── Label    (Label: Pos (-70,48), Size (140,30), size 22, centered, text "EXIT LOCKED")
│   ├── Skeptic      (instance of Skeptic.tscn)
│   └── Ghost        (instance of Ghost.tscn)
├── HUD (CanvasLayer, Layer 1)
│   ├── Bar          (ColorRect: Pos (0,0), Size (1280,70), Color #191a2d)
│   ├── HealthLabel  (Label: Pos (30,16),  size 30)
│   ├── ScoreLabel   (Label: Pos (320,16), size 30)
│   ├── RelicLabel   (Label: Pos (620,16), size 30)
│   ├── TimeLabel    (Label: Pos (1000,16), size 30)
│   └── HintLabel    (Label: Pos (30,688), Size (1220,30), size 24)
├── StartMenu        (instance of StartMenu.tscn)
└── GameOver         (instance of GameOver.tscn)
```

All ColorRects: Mouse Filter **Ignore**. Skeptic and Ghost positions are set by code (`reset()`), so leave them at `(0,0)`.

```gdscript
extends Node2D

enum State { TITLE, PLAYING, GAME_OVER }

const RELIC_SCENE := preload("res://scenes/relic/Relic.tscn")
const REQUIRED_RELICS := 8
const ROUND_TIME := 150.0
const RELIC_POINTS := 100
const START_HEALTH := 3
const SKEPTIC_START := Vector2(140, 380)
const GHOST_START := Vector2(1100, 160)
const EXIT_RADIUS := 50.0
const RELIC_POSITIONS: Array[Vector2] = [
	Vector2(260, 160), Vector2(520, 200), Vector2(780, 150), Vector2(1000, 260),
	Vector2(300, 540), Vector2(560, 480), Vector2(820, 560), Vector2(1050, 520),
]

@onready var world: Node2D = $World
@onready var relics_root: Node2D = $World/Relics
@onready var exit_door: Node2D = $World/Exit
@onready var door_rect: ColorRect = $World/Exit/Door
@onready var exit_label: Label = $World/Exit/Label
@onready var skeptic = $World/Skeptic
@onready var ghost = $World/Ghost
@onready var hud: CanvasLayer = $HUD
@onready var start_menu: CanvasLayer = $StartMenu
@onready var game_over: CanvasLayer = $GameOver

var state := State.TITLE
var state_time := 0.0
var health := START_HEALTH
var score := 0
var relics_collected := 0
var time_left := ROUND_TIME

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	skeptic.hit.connect(_on_skeptic_hit)
	_show_title()

func _show_title() -> void:
	state = State.TITLE
	state_time = 0.0
	world.visible = false
	hud.visible = false
	game_over.visible = false
	start_menu.visible = true
	skeptic.active = false
	ghost.active = false
	InputManager.flush()

func _start_game() -> void:
	state = State.PLAYING
	state_time = 0.0
	health = START_HEALTH
	score = 0
	relics_collected = 0
	time_left = ROUND_TIME
	for c in relics_root.get_children():
		c.queue_free()
	for p in RELIC_POSITIONS:
		var r := RELIC_SCENE.instantiate()
		r.position = p
		r.collected.connect(_on_relic_collected)
		relics_root.add_child(r)
	skeptic.reset(SKEPTIC_START)
	ghost.reset(GHOST_START)
	world.visible = true
	hud.visible = true
	start_menu.visible = false
	game_over.visible = false
	InputManager.flush()
	_update_hud()

func _process(delta: float) -> void:
	state_time += delta
	match state:
		State.TITLE:
			InputManager.consume_press("secondary")  # Space does nothing here
			if InputManager.consume_press("primary"):
				_start_game()
		State.PLAYING:
			_update_playing(delta)
		State.GAME_OVER:
			InputManager.consume_press("secondary")
			var pressed := InputManager.consume_press("primary")
			if pressed and state_time >= 1.0:  # ignore Z for the first 1 s
				_start_game()

func _update_playing(delta: float) -> void:
	time_left = maxf(0.0, time_left - delta)
	if time_left <= 0.0:
		_finish(false, "TIME'S UP")
		return
	var unlocked := relics_collected >= REQUIRED_RELICS
	door_rect.color = Color("#63f2a6") if unlocked else Color("#a45170")
	exit_label.text = "EXIT OPEN" if unlocked else "EXIT LOCKED"
	if unlocked and skeptic.global_position.distance_to(exit_door.global_position) < EXIT_RADIUS:
		_finish(true, "YOU ESCAPED!")
		return
	_update_hud()

func _on_relic_collected() -> void:
	relics_collected += 1
	score += RELIC_POINTS

func _on_skeptic_hit() -> void:
	health -= 1
	if health <= 0:
		_finish(false, "CAUGHT BY THE GHOST")

func _finish(won: bool, message: String) -> void:
	state = State.GAME_OVER
	state_time = 0.0
	skeptic.active = false
	ghost.active = false
	if won:
		score += int(time_left) * 5
	game_over.show_result(message, score)
	game_over.visible = true
	InputManager.flush()  # a Z still held from gameplay cannot skip this screen

func _update_hud() -> void:
	$HUD/HealthLabel.text = "HEALTH: %d" % health
	$HUD/ScoreLabel.text = "SCORE: %d" % score
	$HUD/RelicLabel.text = "RELICS: %d/%d" % [relics_collected, REQUIRED_RELICS]
	$HUD/TimeLabel.text = "TIME: %d" % ceili(time_left)
	var ward := "READY" if skeptic.ward_cooldown_left <= 0.0 else "%.1f" % skeptic.ward_cooldown_left
	var dash := "READY" if skeptic.dash_cooldown_left <= 0.0 else "%.1f" % skeptic.dash_cooldown_left
	$HUD/HintLabel.text = "Z WARD: %s     SPACE DASH: %s" % [ward, dash]
```

## 7. Milestones (a playable build after EACH one)

| # | Build | Playable result | Do not move on until |
|---|---|---|---|
| **M1** | Settings, `InputManager`, `Skeptic`, `StartMenu`, `GameOver`, bare `Main` (floor + walls, no relics/ghost; temporarily call `_finish(false,"TEST")` after a 10 s timer) | Title → move around → game over → Z → play again | Section 8 checks 1–5 pass |
| **M2** | `Relic` + Exit + HUD + win/lose by timer | You can win (8 relics + exit) or time out | Win and lose screens both show the correct text |
| **M3** | `Ghost` (spawn, wander, chase, damage) | A real round with a threat | You can lose by health and survive by running away |
| **M4** | Ward (Z) + Dash (Space) tuning | Full loop | Cooldowns visible in the HUD, mashing does nothing bad |
| **M5** | Swap rectangles for your art, font, menu resources; add music/SFX | Demo-ready | Full Section 8 checklist |

**Remove the M1 test timer once M2 is done.**

## 8. Compliance checklist (run after EVERY change)

- [ ] Only Up/Down/Left/Right, Z and Space are used anywhere. Search the project for `KEY_` and `Input.` and confirm everything is inside `InputManager.gd`.
- [ ] No mouse/touch/click handlers and no `Button` nodes exist.
- [ ] Hold an arrow: continuous movement. Release: stops. No reliance on key-repeat.
- [ ] Z works for start, ward and restart (Caps Lock on and off).
- [ ] Hold Z through the game over screen: it does **not** restart. Release it, wait 1 s, press again: it does.
- [ ] Hold Space: only one dash. It's never needed more than about once every 2.5 s.
- [ ] Hold Up + Down together: nothing breaks and you simply stand still.
- [ ] Release all keys at once mid-round: no instant loss.
- [ ] Mash Z and Space randomly on every screen: nothing harmful or skipped.
- [ ] No mashing, no frame-perfect timing, and the ghost gives you at least 3 s before it can touch you.
- [ ] Text, player and ghost readable from about 2 m (fullscreen test).
- [ ] No pop-ups, alerts or new windows.
- [ ] Title shows `Press Z to start` plus the controls.
- [ ] Game over shows the score and `Press Z to play again`.
- [ ] Runs locally with the steps in `README.md`.
- [ ] Alt-Tab away while holding an arrow and come back: no stuck movement.

**Do not tick the checklist until you have actually run the game.**

## 9. Tuning cheat-sheet (all constants, easy to change)

| What | Where | Value |
|---|---|---|
| Player speed | `Skeptic.SPEED` | 220 |
| Ghost chase speed | `Ghost.BASE_CHASE_SPEED` | 95 (+ up to 35) |
| Ghost spawn grace | `Ghost.SPAWN_TIME` | 3 s |
| Round length | `Main.ROUND_TIME` | 150 s |
| Hit immunity | `Skeptic.IMMUNITY` | 1.5 s |
| Ward / Dash cooldown | `WARD_COOLDOWN` / `DASH_COOLDOWN` | 1.5 s / 2.5 s |

Too easy? Raise `BASE_CHASE_SPEED` first, in steps of 10. Too hard? Lower it. Do not shorten the spawn grace below 3 s or the cooldown on Space below 2 s.

## 10. `README.md`

```markdown
# HAUNTED SHIFT
Top-down arcade ghost-dodger made with Godot 4 and GDScript.

## Run locally
1. Open Godot 4 and import the `Haunted_Shift/` folder (it contains `project.godot`).
2. Press F5 to run (main scene: `res://scenes/Main.tscn`).

## Controls
- Arrow keys: move
- Z: start / ward pulse / play again
- Space: dash

No internet needed during play.
```