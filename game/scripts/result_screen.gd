extends Control

@onready var rating_label: Label = $RatingLabel
@onready var score_label: Label = $ScoreLabel
@onready var combo_label: Label = $ComboLabel
@onready var perfect_label: Label = $StatsContainer/PerfectLabel
@onready var great_label: Label = $StatsContainer/GreatLabel
@onready var good_label: Label = $StatsContainer/GoodLabel
@onready var miss_label: Label = $StatsContainer/MissLabel
@onready var early_late_label: Label = $EarlyLateLabel
@onready var retry_label: Label = $RetryLabel
@onready var fanfare_player: AudioStreamPlayer = $FanfarePlayer

var _fade_in: float = 0.0
var _time: float = 0.0
var _score_anim: float = 0.0
var _target_score: int = 0

func _ready() -> void:
	modulate.a = 0.0
	# Get results from GameManager
	var r = GameManager.last_result
	if r.is_empty():
		return

	_target_score = r.get("score", 0)
	rating_label.text = r.get("rating", "F")
	combo_label.text = "Max Combo: %d / %d" % [r.get("max_combo", 0), r.get("total_notes", 0)]

	var total = max(r.get("total_notes", 1), 1)
	perfect_label.text = "Perfect  %d  (%.1f%%)" % [r.get("perfect", 0), 100.0 * r.get("perfect", 0) / total]
	great_label.text = "Great  %d  (%.1f%%)" % [r.get("great", 0), 100.0 * r.get("great", 0) / total]
	good_label.text = "Good  %d  (%.1f%%)" % [r.get("good", 0), 100.0 * r.get("good", 0) / total]
	miss_label.text = "Miss  %d  (%.1f%%)" % [r.get("miss", 0), 100.0 * r.get("miss", 0) / total]
	early_late_label.text = "Early: %d    Late: %d" % [r.get("early", 0), r.get("late", 0)]

	# Color rating
	match r.get("rating", "F"):
		"Phi":
			rating_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		"V", "V+S":
			rating_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		"S":
			rating_label.add_theme_color_override("font_color", Color(0.8, 0.85, 1.0))
		"A":
			rating_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		"F":
			rating_label.add_theme_color_override("font_color", Color(0.6, 0.3, 0.3))

	# Play fanfare
	var fanfare_path = "res://resources/hitsounds/result_fanfare.ogg"
	if ResourceLoader.exists(fanfare_path):
		fanfare_player.stream = load(fanfare_path)
		fanfare_player.play()

func _process(delta: float) -> void:
	_time += delta

	if _fade_in < 1.0:
		_fade_in = minf(_fade_in + delta * 2.0, 1.0)
		modulate.a = _fade_in

	# Animate score counting up
	if _score_anim < 1.0:
		_score_anim = minf(_score_anim + delta * 1.5, 1.0)
		var displayed = int(_target_score * _score_anim)
		score_label.text = "%d" % displayed

	# Retry blink
	retry_label.modulate.a = 0.4 + sin(_time * 2.0) * 0.3

func _input(event: InputEvent) -> void:
	if _fade_in < 0.5:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R or event.keycode == KEY_ENTER:
			get_tree().change_scene_to_file("res://scenes/gameplay.tscn")
		elif event.keycode == KEY_ESCAPE or event.keycode == KEY_Q:
			get_tree().change_scene_to_file("res://scenes/song_select.tscn")
	elif event is InputEventMouseButton and event.pressed:
		get_tree().change_scene_to_file("res://scenes/song_select.tscn")
