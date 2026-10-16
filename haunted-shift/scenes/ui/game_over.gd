extends CanvasLayer

# Keyboard-only menu: UP/DOWN = select, Z = confirm. No Buttons, no mouse.

const INPUT_DELAY := 1.0  # Z is ignored this long so a held/mashed Z can't skip the screen
const WIN_COLOR := Color("#63f2a6")
const LOSE_COLOR := Color("#ff6b6b")
const SELECTED_COLOR := Color("#ffd76a")
const NORMAL_COLOR := Color("#8a8a8a")
const OPTION_TEXT := ["AGAIN", "EXIT"]

@onready var title: RichTextLabel = $Root/HSContainer/HSVContainer/Label
@onready var score_label: Label = $Root/HSContainer/HSVContainer/Score
@onready var options := [
	$Root/HSContainer/HSVContainer/PlayAgainOption,
	$Root/HSContainer/HSVContainer/ExitOption,
]

var selected := 0
var delay_left := 0.0
var prev_up := false
var prev_down := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

func show_result(message: String, won: bool, final_score: int) -> void:
	title.text = "[wave amp=20 freq=4][torch speed=6 width=3 len=%d]%s[/torch][/wave]" % [message.length(), message]
	title.modulate = WIN_COLOR if won else LOSE_COLOR
	score_label.text = "SCORE %d" % final_score
	selected = 0
	delay_left = INPUT_DELAY
	visible = true
	get_tree().paused = true  # freeze the ghost, the timer and the player
	InputManager.flush()
	prev_up = InputManager.is_held("s1_up")
	prev_down = InputManager.is_held("s1_down")
	_refresh()

func _process(delta: float) -> void:
	if not visible:
		return
	delay_left = maxf(0.0, delay_left - delta)
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

	var pressed := InputManager.consume_press("s1_attack")
	if pressed and delay_left <= 0.0:
		get_tree().paused = false
		InputManager.flush()
		if selected == 0:
			get_tree().reload_current_scene()
		else:
			get_tree().change_scene_to_file("res://scenes/ui/StartMenu.tscn")

func _refresh() -> void:
	for i in options.size():
		var is_sel: bool = i == selected
		options[i].text = ("> %s <" % OPTION_TEXT[i]) if is_sel else OPTION_TEXT[i]
		options[i].modulate = SELECTED_COLOR if is_sel else NORMAL_COLOR
