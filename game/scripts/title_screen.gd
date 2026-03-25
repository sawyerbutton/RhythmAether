extends Control

@onready var title_label: Label = $TitleLabel
@onready var subtitle_label: Label = $SubtitleLabel
@onready var start_label: Label = $StartLabel
@onready var bg: TextureRect = $Background

var _time: float = 0.0
var _fade_in: float = 0.0
var _start_blink: float = 0.0

func _ready() -> void:
	modulate.a = 0.0
	_fade_in = 0.0

func _process(delta: float) -> void:
	_time += delta

	# Fade in
	if _fade_in < 1.0:
		_fade_in = minf(_fade_in + delta * 1.5, 1.0)
		modulate.a = _fade_in

	# "Press any key" blink
	_start_blink += delta * 2.0
	start_label.modulate.a = 0.4 + sin(_start_blink) * 0.4

	# Title subtle float
	title_label.position.y = 180 + sin(_time * 0.8) * 4.0

func _input(event: InputEvent) -> void:
	if _fade_in < 0.8:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_start_game()
	elif event is InputEventMouseButton and event.pressed:
		_start_game()
	elif event is InputEventScreenTouch and event.pressed:
		_start_game()

func _start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/song_select.tscn")
