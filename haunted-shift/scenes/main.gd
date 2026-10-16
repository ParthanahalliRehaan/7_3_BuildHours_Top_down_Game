extends Node2D

const GHOST_SCENE := preload("res://scenes/ghost/Ghost.tscn")
const RELIC_SCENE := preload("res://scenes/relic/Relic.tscn")

const SKEPTIC_START := Vector2(140, 380)
# Random spawn area: inside the walls and below the HUD bar
const GHOST_AREA := Rect2(80, 120, 1120, 520)
const MIN_DISTANCE := 450.0  # never spawns on top of the skeptic

const START_HEALTH := 3
const REQUIRED_RELICS := 8
const ROUND_TIME := 150.0
const RELIC_POINTS := 100
const TIME_BONUS_PER_SECOND := 5
const EXIT_RADIUS := 50.0
const LOCKED_COLOR := Color("#a45170")
const OPEN_COLOR := Color("#63f2a6")

const RELIC_POSITIONS: Array[Vector2] = [
	Vector2(260, 160), Vector2(520, 200), Vector2(780, 150), Vector2(1000, 260),
	Vector2(300, 540), Vector2(560, 480), Vector2(820, 560), Vector2(1050, 520),
]

@onready var world: Node2D = $World
@onready var skeptic = $World/Skeptic
@onready var relics_root: Node2D = $World/Relics
@onready var exit_door: Node2D = $World/Exit
@onready var door_rect: ColorRect = $World/Exit/Door
@onready var exit_label: Label = $World/Exit/Label
@onready var spawn_timer: Timer = $GhostSpawnTimer
@onready var hud = $HUD
@onready var pause_menu = $PauseMenu
@onready var game_over = $GameOver

var ghost = null
var finished := false
var health := START_HEALTH
var score := 0
var relics_collected := 0
var time_left := ROUND_TIME

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	get_tree().paused = false
	InputManager.flush()
	skeptic.hit.connect(_on_skeptic_hit)
	for p in RELIC_POSITIONS:
		var r := RELIC_SCENE.instantiate()
		r.position = p
		r.collected.connect(_on_relic_collected)
		relics_root.add_child(r)
	skeptic.reset(SKEPTIC_START)
	spawn_timer.timeout.connect(_spawn_ghost)
	spawn_timer.start()
	_update_hud()

func _process(delta: float) -> void:
	if finished:
		return
	# Pause menu (this runs only while the game is NOT paused)
	if Input.is_action_just_pressed("ui_cancel"):
		pause_menu.open()
		return

	time_left = maxf(0.0, time_left - delta)
	if time_left <= 0.0:
		_finish(false, "TIME'S UP")
		return
	var unlocked := relics_collected >= REQUIRED_RELICS
	door_rect.color = OPEN_COLOR if unlocked else LOCKED_COLOR
	exit_label.text = "EXIT OPEN" if unlocked else "EXIT LOCKED"
	if unlocked and skeptic.global_position.distance_to(exit_door.global_position) < EXIT_RADIUS:
		_finish(true, "ESCAPED!")
		return
	_update_hud()

func _on_relic_collected() -> void:
	if finished:
		return
	relics_collected += 1
	score += RELIC_POINTS

func _on_skeptic_hit() -> void:
	if finished:
		return
	health -= 1
	if health <= 0:
		health = 0
		_finish(false, "CAUGHT!")
	_update_hud()

func _finish(won: bool, message: String) -> void:
	if finished:
		return
	finished = true
	spawn_timer.stop()
	if won:
		score += int(time_left) * TIME_BONUS_PER_SECOND
	_update_hud()
	game_over.show_result(message, won, score)  # also pauses the game

func _update_hud() -> void:
	var ward_ratio: float = 1.0 - skeptic.ward_cooldown_left / skeptic.WARD_COOLDOWN
	var dash_ratio: float = 1.0 - skeptic.dash_cooldown_left / skeptic.DASH_COOLDOWN
	hud.update_hud(health, score, relics_collected, REQUIRED_RELICS, time_left, ward_ratio, dash_ratio)

func _spawn_ghost() -> void:
	ghost = GHOST_SCENE.instantiate()
	world.add_child(ghost)
	world.move_child(ghost, skeptic.get_index())  # draw the ghost under the skeptic
	ghost.start(_random_spawn_point())

func _random_spawn_point() -> Vector2:
	var pos := Vector2.ZERO
	for i in 20:
		pos = Vector2(
			randf_range(GHOST_AREA.position.x, GHOST_AREA.end.x),
			randf_range(GHOST_AREA.position.y, GHOST_AREA.end.y))
		if pos.distance_to(skeptic.global_position) >= MIN_DISTANCE:
			break
	return pos
