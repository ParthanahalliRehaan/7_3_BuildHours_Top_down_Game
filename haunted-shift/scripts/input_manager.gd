extends Node

# Six Input Map actions only (Project Settings > Input Map). Nothing else.
# Held state is polled every frame (no OS key-repeat needed).
# Attack/dash are latched once and consumed once, so holding never repeats.

const ACTIONS := ["s1_up", "s1_down", "s1_left", "s1_right", "s1_attack", "s1_dash"]
const FRESH_ONLY := ["s1_attack", "s1_dash"]

var _held := {}
var _latched := {}
var _needs_release := {}

func _ready() -> void:
	process_priority = -1000  # run before everything else each frame
	process_mode = Node.PROCESS_MODE_ALWAYS  # keep reading keys while the game is paused (pause / game over menus)
	for a in ACTIONS:
		_held[a] = false
		_latched[a] = false
		_needs_release[a] = false

func _process(_delta: float) -> void:
	if not get_window().has_focus():
		flush()
		for a in ACTIONS:
			_held[a] = false
		return
	for a in ACTIONS:
		var now: bool = Input.is_action_pressed(a)
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
	var x := int(_held["s1_right"]) - int(_held["s1_left"])
	var y := int(_held["s1_down"]) - int(_held["s1_up"])
	return Vector2(x, y).normalized()

# Call on EVERY screen change. Drops queued presses, and an attack/dash key
# that is still physically held must be released before it counts as fresh.
func flush() -> void:
	for a in ACTIONS:
		_latched[a] = false
	for a in FRESH_ONLY:
		_needs_release[a] = true
