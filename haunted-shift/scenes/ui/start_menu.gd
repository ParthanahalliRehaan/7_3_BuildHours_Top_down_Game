extends CanvasLayer

# How the title text flickers: short, shallow dips in brightness (no harsh strobing)
const DIP_ALPHA := 0.55
const DIPS_PER_SECOND := 1.2

# How the Start button pulses
const PULSE_SPEED := 3.0
const PULSE_MIN_SCALE := 1.0
const PULSE_MAX_SCALE := 1.12

@onready var title: RichTextLabel = $Root/HSContainer/HSVContainer/Label
@onready var start_button: Button = $Root/HSContainer/HSVContainer/StartButton

var time := 0.0
var dip_left := 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	InputManager.flush()  # a held Z from another screen must be released first

func _process(delta: float) -> void:
	time += delta
	_flicker_title(delta)
	_pulse_button()

	InputManager.consume_press("s1_dash")  # Space does nothing here
	if InputManager.consume_press("s1_attack"):
		start_button.pressed.emit()

func _flicker_title(delta: float) -> void:
	if dip_left > 0.0:
		dip_left -= delta
		title.modulate.a = DIP_ALPHA
	else:
		title.modulate.a = 1.0
		if randf() < DIPS_PER_SECOND * delta:  # start a new quick dip now and then
			dip_left = randf_range(0.05, 0.12)

func _pulse_button() -> void:
	# Scale from the centre of the button, not from its top-left corner
	start_button.pivot_offset = start_button.size / 2.0
	var wave := 0.5 + 0.5 * sin(time * PULSE_SPEED)  # goes 0 -> 1 -> 0
	var s := lerpf(PULSE_MIN_SCALE, PULSE_MAX_SCALE, wave)
	start_button.scale = Vector2(s, s)

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
