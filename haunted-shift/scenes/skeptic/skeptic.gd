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

const NORMAL_COLOR := Color("#ffe17a")  # yellow
const WARD_COLOR := Color("#73f7ff")    # cyan flash when you press Z

var active := false
var facing := Vector2.RIGHT
var dash_left := 0.0
var dash_cooldown_left := 0.0
var ward_cooldown_left := 0.0
var ward_flash_left := 0.0
var immune_left := 0.0
var knock_left := 0.0
var knock_velocity := Vector2.ZERO

@onready var body: ColorRect = $Color

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
	modulate.a = 1.0
	body.color = NORMAL_COLOR
	active = true

func _physics_process(delta: float) -> void:
	if not active:
		velocity = Vector2.ZERO
		return

	dash_cooldown_left = maxf(0.0, dash_cooldown_left - delta)
	ward_cooldown_left = maxf(0.0, ward_cooldown_left - delta)
	ward_flash_left = maxf(0.0, ward_flash_left - delta)
	immune_left = maxf(0.0, immune_left - delta)

	# Blink while immune, cyan flash while the ward is active
	modulate.a = 0.4 if (immune_left > 0.0 and int(immune_left * 10.0) % 2 == 0) else 1.0
	body.color = WARD_COLOR if ward_flash_left > 0.0 else NORMAL_COLOR

	var dir := InputManager.direction()
	if dir != Vector2.ZERO:
		facing = dir

	# Fresh presses only. Pressing during a cooldown is harmless.
	if InputManager.consume_press("s1_dash") and dash_cooldown_left <= 0.0:
		dash_left = DASH_TIME
		dash_cooldown_left = DASH_COOLDOWN
	if InputManager.consume_press("s1_attack") and ward_cooldown_left <= 0.0:
		_use_ward()

	if knock_left > 0.0:
		knock_left -= delta
		velocity = knock_velocity
	elif dash_left > 0.0:
		dash_left -= delta
		velocity = facing * DASH_SPEED
	else:
		velocity = dir * SPEED  # keys released => dir is zero => stop
	move_and_slide()

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
