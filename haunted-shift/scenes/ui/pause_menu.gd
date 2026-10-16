extends CanvasLayer

# Keyboard-only menu: UP/DOWN = select, Z = confirm. No Buttons, no mouse.

const DIP_ALPHA := 0.55
const DIPS_PER_SECOND := 1.2
const SELECTED_COLOR := Color("#ffd76a")
const NORMAL_COLOR := Color("#8a8a8a")
const OPTION_TEXT := ["RESUME", "EXIT"]

@onready var title: RichTextLabel = $Root/HSContainer/HSVContainer/Label
@onready var options := [
	$Root/HSContainer/HSVContainer/ResumeOption,
	$Root/HSContainer/HSVContainer/ExitOption,
]

var selected := 0
var dip_left := 0.0
var prev_up := false
var prev_down := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # must keep running while the tree is paused
	visible = false

func open() -> void:
	selected = 0
	visible = true
	get_tree().paused = true
	InputManager.flush()  # a held Z/Space must be released first
	prev_up = InputManager.is_held("s1_up")
	prev_down = InputManager.is_held("s1_down")
	_refresh()

func close() -> void:
	visible = false
	get_tree().paused = false
	InputManager.flush()

func _process(delta: float) -> void:
	if not visible:
		return  # never eat Z/Space while the game is running
	_flicker_title(delta)

	InputManager.consume_press("s1_dash")  # Space does nothing here
	var up := InputManager.is_held("s1_up")
	var down := InputManager.is_held("s1_down")
	if up and not prev_up:
		selected = (selected - 1 + options.size()) % options.size()
		_refresh()
	if down and not prev_down:
		selected = (selected + 1) % options.size()
		_refresh()
	prev_up = up
	prev_down = down

	if InputManager.consume_press("s1_attack"):
		if selected == 0:
			close()
		else:
			_exit_to_title()

func _exit_to_title() -> void:
	visible = false
	get_tree().paused = false
	InputManager.flush()
	get_tree().change_scene_to_file("res://scenes/ui/StartMenu.tscn")

func _refresh() -> void:
	for i in options.size():
		var is_sel: bool = i == selected
		options[i].text = ("> %s <" % OPTION_TEXT[i]) if is_sel else OPTION_TEXT[i]
		options[i].modulate = SELECTED_COLOR if is_sel else NORMAL_COLOR

func _flicker_title(delta: float) -> void:
	if dip_left > 0.0:
		dip_left -= delta
		title.modulate.a = DIP_ALPHA
	else:
		title.modulate.a = 1.0
		if randf() < DIPS_PER_SECOND * delta:
			dip_left = randf_range(0.05, 0.12)
