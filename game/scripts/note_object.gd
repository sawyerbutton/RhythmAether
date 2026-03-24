class_name NoteObject
extends Node2D

var note_data: ChartLoader.NoteData
var judged: bool = false
var missed_auto: bool = false

# Hold state
var hold_active: bool = false
var hold_finger_index: int = -1
var hold_progress: float = 0.0

# Animation
var _pulse_time: float = 0.0
var _approach_scale: float = 1.0  # grows slightly as note approaches judgment line

# Color palette — Inverse Opus
const COLOR_PRIMARY := Color(0.91, 0.27, 0.37)       # #E94560 — hot crimson
const COLOR_SECONDARY := Color(0.06, 0.21, 0.38)      # #0F3460 — deep blue
const COLOR_ACCENT := Color(0.33, 0.20, 0.51)         # #533483 — purple
const COLOR_HOLD := Color(0.78, 0.22, 0.32)           # darker crimson
const COLOR_GLOW := Color(0.91, 0.27, 0.37, 0.3)     # soft crimson glow
const COLOR_TRAIL := Color(0.91, 0.27, 0.37, 0.15)   # faint trail

# Sizes
const TAP_SIZE: float = 52.0
const FLICK_SIZE: float = 60.0
const GLOW_RADIUS: float = 36.0

func _process(delta: float) -> void:
	_pulse_time += delta * 4.0
	queue_redraw()

func _draw() -> void:
	if judged and not hold_active:
		return

	match note_data.type:
		"tap":
			_draw_tap()
		"hold":
			_draw_hold()
		"flick":
			_draw_flick()
		"slide":
			_draw_slide()

func _draw_tap() -> void:
	var size = TAP_SIZE * GameManager.note_size_scale
	var half = size / 2.0
	var pulse = 1.0 + sin(_pulse_time) * 0.06

	# Soft outer glow (two layers)
	draw_circle(Vector2.ZERO, GLOW_RADIUS * 1.4 * pulse, Color(COLOR_PRIMARY.r, COLOR_PRIMARY.g, COLOR_PRIMARY.b, 0.08))
	draw_circle(Vector2.ZERO, GLOW_RADIUS * pulse, COLOR_GLOW)

	# Trail going upward — tapered and gradient
	var trail_length = 50.0
	for i in range(5):
		var t = float(i) / 5.0
		var y = -trail_length * t
		var w = half * 0.25 * (1.0 - t)
		var alpha = 0.12 * (1.0 - t)
		draw_line(Vector2(-w, y), Vector2(w, y), Color(COLOR_PRIMARY.r, COLOR_PRIMARY.g, COLOR_PRIMARY.b, alpha), 2.0)

	# Diamond — double layer for depth
	var points = PackedVector2Array([
		Vector2(0, -half * pulse),
		Vector2(half * pulse, 0),
		Vector2(0, half * pulse),
		Vector2(-half * pulse, 0)
	])
	draw_colored_polygon(points, COLOR_PRIMARY)

	# Inner bright core
	var inner = half * 0.45 * pulse
	var inner_points = PackedVector2Array([
		Vector2(0, -inner),
		Vector2(inner, 0),
		Vector2(0, inner),
		Vector2(-inner, 0)
	])
	draw_colored_polygon(inner_points, Color(1.0, 0.55, 0.6, 0.5))

	# Bright white center dot
	draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.9, 0.9, 0.7))

	# Crisp border
	draw_polyline(points + PackedVector2Array([points[0]]), Color(1.0, 0.5, 0.55, 0.85), 2.0, true)

func _draw_hold() -> void:
	var size = TAP_SIZE * GameManager.note_size_scale
	var half = size / 2.0
	var body_length: float = get_meta("hold_visual_length", 100.0)
	var is_active: bool = get_meta("hold_is_active", false)

	# Active hold: bright pulsing glow, inactive: dimmer
	var active_boost = 1.0 if not is_active else (1.5 + sin(_pulse_time * 3.0) * 0.3)
	var body_alpha = 0.3 if not is_active else 0.7
	var glow_alpha = 0.1 if not is_active else 0.35

	# Body glow (wide soft)
	var glow_rect = Rect2(-half * 1.0, -body_length, half * 2.0, body_length)
	draw_rect(glow_rect, Color(COLOR_HOLD.r, COLOR_HOLD.g, COLOR_HOLD.b, glow_alpha))

	# Body core
	var body_rect = Rect2(-half * 0.5, -body_length, half * 1.0, body_length)
	draw_rect(body_rect, Color(COLOR_HOLD.r, COLOR_HOLD.g, COLOR_HOLD.b, body_alpha))

	# Center bright line (brighter when active)
	var line_alpha = 0.3 if not is_active else 0.8
	draw_line(Vector2(0, 0), Vector2(0, -body_length), Color(1.0, 0.6, 0.65, line_alpha), 3.0 if is_active else 1.5)

	# Active: side edge lines
	if is_active:
		draw_line(Vector2(-half * 0.5, 0), Vector2(-half * 0.5, -body_length), Color(1.0, 0.4, 0.5, 0.4), 1.5)
		draw_line(Vector2(half * 0.5, 0), Vector2(half * 0.5, -body_length), Color(1.0, 0.4, 0.5, 0.4), 1.5)

	# Head diamond (larger glow when active)
	var pulse = active_boost + sin(_pulse_time) * 0.05
	var glow_size = GLOW_RADIUS * pulse * (1.3 if is_active else 1.0)
	draw_circle(Vector2.ZERO, glow_size, Color(COLOR_GLOW.r, COLOR_GLOW.g, COLOR_GLOW.b, 0.3 if not is_active else 0.5))
	var points = PackedVector2Array([
		Vector2(0, -half * pulse),
		Vector2(half * pulse, 0),
		Vector2(0, half * pulse),
		Vector2(-half * pulse, 0)
	])
	var head_color = COLOR_HOLD if not is_active else Color(1.0, 0.4, 0.5)
	draw_colored_polygon(points, head_color)
	draw_polyline(points + PackedVector2Array([points[0]]), Color(1.0, 0.5, 0.6, 0.9), 2.5, true)

	# Tail marker — glowing line
	draw_line(
		Vector2(-half * 0.6, -body_length),
		Vector2(half * 0.6, -body_length),
		Color(1.0, 0.5, 0.55, 0.6), 3.0
	)

func _draw_flick() -> void:
	var size = FLICK_SIZE * GameManager.note_size_scale
	var half = size / 2.0
	var pulse = 1.0 + sin(_pulse_time * 1.5) * 0.08

	# Glow
	draw_circle(Vector2.ZERO, GLOW_RADIUS * 1.2 * pulse, Color(COLOR_SECONDARY.r, COLOR_SECONDARY.g, COLOR_SECONDARY.b, 0.25))

	# Arrow
	var points = PackedVector2Array([
		Vector2(0, -half * pulse),
		Vector2(half * pulse, half * 0.3),
		Vector2(half * 0.3, half * 0.1),
		Vector2(half * 0.3, half * pulse),
		Vector2(-half * 0.3, half * pulse),
		Vector2(-half * 0.3, half * 0.1),
		Vector2(-half * pulse, half * 0.3)
	])
	draw_colored_polygon(points, COLOR_SECONDARY)
	draw_polyline(points + PackedVector2Array([points[0]]), Color(0.3, 0.5, 1.0, 0.7), 2.5, true)

func _draw_slide() -> void:
	var radius = 22.0 * GameManager.note_size_scale
	var pulse = 1.0 + sin(_pulse_time) * 0.05

	# Glow
	draw_circle(Vector2.ZERO, radius * 1.5 * pulse, Color(COLOR_ACCENT.r, COLOR_ACCENT.g, COLOR_ACCENT.b, 0.2))
	# Core
	draw_circle(Vector2.ZERO, radius * pulse, COLOR_ACCENT)
	draw_arc(Vector2.ZERO, radius * pulse, 0, TAU, 32, Color(0.6, 0.4, 0.8, 0.7), 2.0)
