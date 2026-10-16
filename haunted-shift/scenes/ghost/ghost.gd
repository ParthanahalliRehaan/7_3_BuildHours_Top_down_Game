extends CharacterBody2D

enum State { WANDER, CHASE, STUNNED }

const WANDER_SPEED := 60.0
const BASE_CHASE_SPEED := 95.0
const MAX_EXTRA_SPEED := 35.0
const SIGHT_RANGE := 420.0
const LOSE_RANGE := 560.0
# Inside the walls and inside the 1280x720 screen
const ARENA := Rect2(80, 120, 1120, 520)

const WANDER_COLOR := Color("#8c79ff")  # purple
const CHASE_COLOR := Color("#d04bff")   # brighter purple, it has seen you
const STUN_COLOR := Color("#79f3ff")    # cyan, harmless

var active := false
var state := State.WANDER
var elapsed := 0.0
var wander_target := Vector2.ZERO

@onready var body: ColorRect = $Color
@onready var hit_box: Area2D = $HitBox
@onready var stun_timer: Timer = $StunTimer
@onready var wander_timer: Timer = $WanderTimer

func _ready() -> void:
	add_to_group("ghost")
	stun_timer.timeout.connect(_on_stun_timer_timeout)
	wander_timer.timeout.connect(_pick_wander)

# Main calls this right after adding the ghost to the scene.
func start(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	elapsed = 0.0
	active = true
	state = State.STUNNED  # harmless (cyan) for 1.5 s after appearing
	stun_timer.start()
	wander_timer.start()
	_pick_wander()

func _random_point() -> Vector2:
	return Vector2(
		randf_range(ARENA.position.x, ARENA.end.x),
		randf_range(ARENA.position.y, ARENA.end.y))

func _pick_wander() -> void:
	wander_target = _random_point()

func _on_stun_timer_timeout() -> void:
	state = State.WANDER
	_pick_wander()

func stun(from_pos: Vector2) -> void:
	state = State.STUNNED
	stun_timer.start()
	velocity = (global_position - from_pos).normalized() * 380.0

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
		State.STUNNED:
			body.color = STUN_COLOR
			velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
		State.WANDER:
			body.color = WANDER_COLOR
			if global_position.distance_to(wander_target) < 20.0:
				_pick_wander()
			velocity = (wander_target - global_position).normalized() * WANDER_SPEED
			if dist < SIGHT_RANGE:
				state = State.CHASE
		State.CHASE:
			body.color = CHASE_COLOR
			var speed := BASE_CHASE_SPEED + minf(MAX_EXTRA_SPEED, elapsed * 0.3)
			velocity = (skeptic.global_position - global_position).normalized() * speed
			if dist > LOSE_RANGE:
				state = State.WANDER
				_pick_wander()

	move_and_slide()

	# Contact damage (only while awake and not stunned)
	if state == State.WANDER or state == State.CHASE:
		for b in hit_box.get_overlapping_bodies():
			if b.is_in_group("skeptic"):
				b.take_hit(global_position)
