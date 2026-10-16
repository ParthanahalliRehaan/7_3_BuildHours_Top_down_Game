extends CanvasLayer

const BAR_WIDTH := 120.0
const HEART_ON := Color("#ff4d6d")
const HEART_OFF := Color("#3a2236")
const READY_COLOR := Color("#73f7ff")
const CHARGING_COLOR := Color("#4a6a80")
const LOW_TIME_COLOR := Color("#ff6b6b")
const LOW_TIME := 20.0

@onready var health_segments := [$Seg1, $Seg2, $Seg3]
@onready var score_label: Label = $ScoreLabel
@onready var relic_label: Label = $RelicLabel
@onready var time_label: Label = $TimeLabel
@onready var ward_fill: ColorRect = $WardFill
@onready var dash_fill: ColorRect = $DashFill

# ward_ratio / dash_ratio: 0.0 = just used, 1.0 = ready
func update_hud(health: int, score: int, relics: int, needed: int,
		time_left: float, ward_ratio: float, dash_ratio: float) -> void:
	for i in health_segments.size():
		health_segments[i].color = HEART_ON if i < health else HEART_OFF
	score_label.text = "SCORE %d" % score
	relic_label.text = "RELICS %d/%d" % [relics, needed]
	time_label.text = "TIME %d" % ceili(time_left)
	time_label.modulate = LOW_TIME_COLOR if time_left <= LOW_TIME else Color.WHITE
	_set_cooldown(ward_fill, ward_ratio)
	_set_cooldown(dash_fill, dash_ratio)

func _set_cooldown(fill: ColorRect, ratio: float) -> void:
	ratio = clampf(ratio, 0.0, 1.0)
	fill.size.x = BAR_WIDTH * ratio
	fill.color = READY_COLOR if ratio >= 1.0 else CHARGING_COLOR
