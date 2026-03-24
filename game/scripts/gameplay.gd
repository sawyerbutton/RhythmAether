extends Node2D

# Main gameplay controller — "30-second experience slice" version
# Focus: game feel, visual juice, satisfying feedback

# --- Configuration ---
const JUDGMENT_LINE_Y_RATIO: float = 0.85
const TOP_BAR_RATIO: float = 0.08
const NOTE_SPAWN_Y_RATIO: float = 0.10
const LANE_POSITIONS: Array[float] = [0.125, 0.375, 0.625, 0.875]
const AUTO_MISS_THRESHOLD_SEC: float = 0.15

# Colors — Inverse Opus palette
const BG_COLOR := Color(0.102, 0.102, 0.18)           # #1A1A2E
const LINE_COLOR := Color(0.91, 0.27, 0.37)           # #E94560
const LINE_GLOW_COLOR := Color(0.91, 0.27, 0.37, 0.15)

# --- Nodes ---
@onready var audio_player: AudioStreamPlayer = $AudioPlayer
@onready var hitsound_player: AudioStreamPlayer = $HitsoundPlayer
@onready var judgment_line: Line2D = $JudgmentLine
@onready var judgment_glow: Line2D = $JudgmentGlow
@onready var notes_container: Node2D = $NotesContainer
@onready var particles_container: Node2D = $ParticlesContainer
@onready var ui_layer: CanvasLayer = $UILayer
@onready var score_label: Label = $UILayer/ScoreLabel
@onready var combo_label: Label = $UILayer/ComboLabel
@onready var combo_sub_label: Label = $UILayer/ComboSubLabel
@onready var judgment_label: Label = $UILayer/JudgmentLabel
@onready var timing_label: Label = $UILayer/TimingLabel
@onready var bg_overlay: ColorRect = $BackgroundOverlay

# --- State ---
var chart: ChartLoader.ChartData
var score_tracker: Judge.ScoreTracker
var active_notes: Array[NoteObject] = []
var next_note_index: int = 0
var playing: bool = false
var current_time: float = 0.0

var screen_w: float
var screen_h: float
var judgment_line_y: float
var note_spawn_y: float
var pixels_per_second: float

var judgment_display_timer: float = 0.0
const JUDGMENT_DISPLAY_DURATION: float = 0.4

var active_holds: Dictionary = {}
var touch_starts: Dictionary = {}
var _song_duration: float = 60.0
var _audio_started: bool = false

# Screen shake
var _shake_intensity: float = 0.0
var _shake_decay: float = 8.0
var _original_position: Vector2 = Vector2.ZERO

# Judgment line pulse
var _line_pulse: float = 0.0

# Combo animation
var _combo_scale: float = 1.0
var _combo_target_scale: float = 1.0

# Hitsound
var _hitsound_stream: AudioStream = null
var _combo_50_stream: AudioStream = null
var _combo_100_stream: AudioStream = null
var _hold_sustain_stream: AudioStream = null

# Background particles
var _bg_particles: Array = []

# Keyboard lane mapping: D=lane0, F=lane1, J=lane2, K=lane3
var _key_lane_map: Dictionary = {}
func _init_key_map() -> void:
	_key_lane_map[KEY_D] = 0
	_key_lane_map[KEY_F] = 1
	_key_lane_map[KEY_J] = 2
	_key_lane_map[KEY_K] = 3
var _lane_flash: Array[float] = [0.0, 0.0, 0.0, 0.0]
var _key_holds: Dictionary = {}

# Beat pulse for background
var _beat_pulse: float = 0.0
var _last_beat: int = -1

@export var chart_path: String = "res://resources/charts/think_outside_the_box.json"

func _ready() -> void:
	_init_key_map()
	_original_position = position
	_update_screen_dimensions()
	_setup_judgment_line()
	_setup_background_particles()
	_load_hitsound()
	_load_and_start()

func _update_screen_dimensions() -> void:
	screen_w = get_viewport_rect().size.x
	screen_h = get_viewport_rect().size.y
	judgment_line_y = screen_h * JUDGMENT_LINE_Y_RATIO
	note_spawn_y = screen_h * NOTE_SPAWN_Y_RATIO
	var fall_distance = judgment_line_y - note_spawn_y
	var visible_time = 2.0 / GameManager.fall_speed
	pixels_per_second = fall_distance / visible_time

func _setup_judgment_line() -> void:
	# Main line
	judgment_line.clear_points()
	judgment_line.add_point(Vector2(0, judgment_line_y))
	judgment_line.add_point(Vector2(screen_w, judgment_line_y))
	judgment_line.default_color = Color(LINE_COLOR, 0.9)
	judgment_line.width = 3.0

	# Glow behind
	judgment_glow.clear_points()
	judgment_glow.add_point(Vector2(0, judgment_line_y))
	judgment_glow.add_point(Vector2(screen_w, judgment_line_y))
	judgment_glow.default_color = LINE_GLOW_COLOR
	judgment_glow.width = 20.0

func _setup_background_particles() -> void:
	# Create ambient floating particles
	for i in range(30):
		_bg_particles.append({
			"x": randf() * screen_w,
			"y": randf() * screen_h,
			"speed": randf_range(10, 40),
			"size": randf_range(1, 3),
			"alpha": randf_range(0.05, 0.2)
		})

func _load_hitsound() -> void:
	var base = "res://resources/hitsounds/"
	if ResourceLoader.exists(base + "tap_hit.ogg"):
		_hitsound_stream = load(base + "tap_hit.ogg")
	if ResourceLoader.exists(base + "combo_50.ogg"):
		_combo_50_stream = load(base + "combo_50.ogg")
	if ResourceLoader.exists(base + "combo_100.ogg"):
		_combo_100_stream = load(base + "combo_100.ogg")
	if ResourceLoader.exists(base + "hold_sustain.ogg"):
		_hold_sustain_stream = load(base + "hold_sustain.ogg")
	hitsound_player.volume_db = linear_to_db(GameManager.hitsound_volume)

func _load_and_start() -> void:
	chart = ChartLoader.load_chart(chart_path)
	if not chart:
		push_error("Failed to load chart!")
		return

	score_tracker = Judge.ScoreTracker.new()
	score_tracker.init(chart.total_note_count)

	var audio_path = chart_path.get_base_dir().path_join(chart.audio_file).simplify_path()
	var stream = load(audio_path)
	if stream:
		audio_player.stream = stream
		audio_player.volume_db = linear_to_db(GameManager.music_volume)

	next_note_index = 0
	playing = true
	current_time = -1.5

	if chart.notes.size() > 0:
		var last_note = chart.notes[chart.notes.size() - 1]
		var last_time = last_note.time_sec
		if last_note.type == "hold":
			last_time = last_note.end_time_sec
		_song_duration = last_time + 2.0
	_update_ui()

func _process(delta: float) -> void:
	if not playing:
		return

	current_time += delta

	if current_time >= 0.0 and not _audio_started and audio_player.stream:
		audio_player.play()
		_audio_started = true

	if audio_player.playing:
		current_time = audio_player.get_playback_position()

	_spawn_upcoming_notes()
	_update_note_positions()
	_check_auto_miss()
	_update_holds()

	# Screen shake decay
	if _shake_intensity > 0.01:
		_shake_intensity *= exp(-_shake_decay * delta)
		position = _original_position + Vector2(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity)
		)
	else:
		_shake_intensity = 0
		position = _original_position

	# Judgment line pulse decay
	if _line_pulse > 0.01:
		_line_pulse *= exp(-6.0 * delta)
		var pulse_width = 3.0 + _line_pulse * 6.0
		var pulse_alpha = 0.9 + _line_pulse * 0.1
		judgment_line.width = pulse_width
		judgment_line.default_color = Color(LINE_COLOR.r, LINE_COLOR.g, LINE_COLOR.b, pulse_alpha)
		judgment_glow.width = 20.0 + _line_pulse * 30.0
		judgment_glow.default_color = Color(LINE_GLOW_COLOR.r, LINE_GLOW_COLOR.g, LINE_GLOW_COLOR.b, LINE_GLOW_COLOR.a + _line_pulse * 0.3)
	else:
		_line_pulse = 0

	# Combo scale animation
	_combo_scale = lerp(_combo_scale, _combo_target_scale, delta * 10.0)
	if combo_label.visible:
		combo_label.scale = Vector2(_combo_scale, _combo_scale)

	# Judgment display fade
	if judgment_display_timer > 0:
		judgment_display_timer -= delta
		var alpha = clampf(judgment_display_timer / JUDGMENT_DISPLAY_DURATION, 0, 1)
		judgment_label.modulate.a = alpha
		# Float up animation
		judgment_label.offset_top -= delta * 60
		timing_label.modulate.a = alpha
		if judgment_display_timer <= 0:
			judgment_label.visible = false
			timing_label.visible = false

	# Background particles
	_update_bg_particles(delta)

	# Lane flash decay
	for i in range(4):
		if _lane_flash[i] > 0.01:
			_lane_flash[i] *= exp(-10.0 * delta)
		else:
			_lane_flash[i] = 0.0

	# Beat pulse (detect current beat from time)
	if chart and chart.timing_points.size() > 0:
		var bpm = chart.timing_points[0].bpm
		var beat_sec = 60.0 / bpm
		var current_beat = int(current_time / beat_sec)
		if current_beat > _last_beat and current_time > 0:
			_last_beat = current_beat
			_beat_pulse = 1.0
			# Stronger pulse on downbeat (every 4 beats)
			if current_beat % 4 == 0:
				_beat_pulse = 1.5
	if _beat_pulse > 0.01:
		_beat_pulse *= exp(-6.0 * delta)
	else:
		_beat_pulse = 0.0
	# Feed beat pulse to background overlay
	if bg_overlay:
		bg_overlay.color.a = 0.35 - _beat_pulse * 0.12

	# Song end
	var song_length = audio_player.stream.get_length() + 1.0 if audio_player.stream else _song_duration
	if current_time > song_length:
		_on_song_end()

	queue_redraw()

func _draw() -> void:
	# Beat-reactive background vignette/pulse
	if _beat_pulse > 0.05:
		var pulse_alpha = _beat_pulse * 0.06
		draw_rect(Rect2(0, 0, screen_w, screen_h), Color(0.91, 0.27, 0.37, pulse_alpha))

	# Background particles
	for p in _bg_particles:
		var size = p["size"] + _beat_pulse * 1.5
		draw_circle(Vector2(p["x"], p["y"]), size, Color(0.91, 0.27, 0.37, p["alpha"] + _beat_pulse * 0.05))

	# Lane columns — subtle gradient bands
	for i in range(4):
		var x = LANE_POSITIONS[i] * screen_w
		var lane_w = screen_w * 0.12
		var base_alpha = 0.02 + _lane_flash[i] * 0.15
		# Lane background strip
		draw_rect(
			Rect2(x - lane_w / 2, note_spawn_y, lane_w, judgment_line_y - note_spawn_y),
			Color(0.91, 0.27, 0.37, base_alpha)
		)
		# Lane center line
		draw_line(
			Vector2(x, note_spawn_y),
			Vector2(x, judgment_line_y),
			Color(1, 1, 1, 0.04 + _lane_flash[i] * 0.2), 1.0
		)

	# Lane key indicators at bottom
	var key_labels = ["D", "F", "J", "K"]
	for i in range(4):
		var x = LANE_POSITIONS[i] * screen_w
		var y = judgment_line_y + 50
		var flash_alpha = 0.25 + _lane_flash[i] * 0.6
		# Key circle
		draw_circle(Vector2(x, y), 22, Color(0.91, 0.27, 0.37, flash_alpha * 0.3))
		draw_arc(Vector2(x, y), 22, 0, TAU, 24, Color(1, 1, 1, flash_alpha), 1.5)

	# Bottom gradient overlay (fade to black at very bottom)
	for g in range(10):
		var gy = judgment_line_y + 80 + g * 8
		var ga = float(g) / 10.0 * 0.3
		draw_line(Vector2(0, gy), Vector2(screen_w, gy), Color(0.05, 0.05, 0.1, ga), 8.0)

func _update_bg_particles(delta: float) -> void:
	for p in _bg_particles:
		p["y"] -= p["speed"] * delta
		if p["y"] < -10:
			p["y"] = screen_h + 10
			p["x"] = randf() * screen_w

func _spawn_upcoming_notes() -> void:
	if not chart:
		return
	var visible_time = 2.0 / GameManager.fall_speed
	var spawn_time = current_time + visible_time

	while next_note_index < chart.notes.size():
		var note_data = chart.notes[next_note_index]
		if note_data.time_sec > spawn_time:
			break
		_spawn_note(note_data)
		next_note_index += 1

func _spawn_note(note_data: ChartLoader.NoteData) -> void:
	var note_obj = NoteObject.new()
	note_obj.note_data = note_data
	note_obj.position = _calc_note_position(note_data, note_data.time_sec)
	if note_data.type == "hold":
		var duration_sec = note_data.end_time_sec - note_data.time_sec
		note_obj.set_meta("hold_visual_length", duration_sec * pixels_per_second)
	notes_container.add_child(note_obj)
	active_notes.append(note_obj)

func _calc_note_position(note_data: ChartLoader.NoteData, target_time: float) -> Vector2:
	var time_diff = target_time - current_time
	var y_offset = time_diff * pixels_per_second
	return Vector2(note_data.x * screen_w, judgment_line_y - y_offset)

func _update_note_positions() -> void:
	for note_obj in active_notes:
		if note_obj.judged and not note_obj.hold_active:
			continue

		if note_obj.hold_active:
			# Pin active hold to judgment line
			note_obj.position = Vector2(note_obj.note_data.x * screen_w, judgment_line_y)
			var remaining = note_obj.note_data.end_time_sec - current_time
			note_obj.set_meta("hold_visual_length", maxf(0, remaining * pixels_per_second))
			note_obj.set_meta("hold_is_active", true)
		else:
			note_obj.position = _calc_note_position(note_obj.note_data, note_obj.note_data.time_sec)
			if note_obj.note_data.type == "hold":
				note_obj.set_meta("hold_is_active", false)

func _check_auto_miss() -> void:
	var miss_time = current_time - AUTO_MISS_THRESHOLD_SEC
	var to_remove: Array[NoteObject] = []

	for note_obj in active_notes:
		# Don't remove holds that are still active
		if note_obj.hold_active:
			continue
		if note_obj.judged:
			to_remove.append(note_obj)
			continue
		if note_obj.note_data.time_sec < miss_time:
			var result = Judge.JudgmentResult.new()
			result.grade = Judge.Grade.MISS
			result.timing = Judge.Timing.LATE
			result.time_diff = current_time - note_obj.note_data.time_sec
			_apply_judgment(note_obj, result)
			to_remove.append(note_obj)

	for note_obj in to_remove:
		active_notes.erase(note_obj)
		if note_obj.is_inside_tree():
			_remove_note_visual(note_obj)

func _update_holds() -> void:
	for finger_idx in active_holds.keys():
		var note_obj: NoteObject = active_holds[finger_idx]
		if not is_instance_valid(note_obj):
			active_holds.erase(finger_idx)
			continue
		if current_time >= note_obj.note_data.end_time_sec - Judge.HOLD_TAIL_WINDOW:
			_complete_hold(note_obj, finger_idx)

func _complete_hold(note_obj: NoteObject, finger_idx: int) -> void:
	note_obj.judged = true
	note_obj.hold_active = false
	active_holds.erase(finger_idx)
	active_notes.erase(note_obj)
	# Completion effect
	var result = Judge.JudgmentResult.new()
	result.grade = Judge.Grade.PERFECT
	result.timing = Judge.Timing.EXACT
	_trigger_hit_effects(result, note_obj.position)
	_remove_note_visual(note_obj)

func _input(event: InputEvent) -> void:
	if not playing:
		return

	if event is InputEventScreenTouch:
		var touch = event as InputEventScreenTouch
		if touch.pressed:
			touch_starts[touch.index] = {"pos": touch.position, "time": current_time}
			_handle_touch_down(touch.index, touch.position)
		else:
			_handle_touch_up(touch.index, touch.position)
			touch_starts.erase(touch.index)
	elif event is InputEventScreenDrag:
		var drag = event as InputEventScreenDrag
		_handle_drag(drag.index, drag.position, drag.relative)
	elif event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				touch_starts[0] = {"pos": mb.position, "time": current_time}
				_handle_touch_down(0, mb.position)
			else:
				_handle_touch_up(0, mb.position)
				touch_starts.erase(0)

	# Keyboard input: D/F/J/K for 4 lanes
	elif event is InputEventKey:
		var key = event as InputEventKey
		# Try both keycode and physical_keycode
		var matched_lane = -1
		if key.keycode in _key_lane_map:
			matched_lane = _key_lane_map[key.keycode]
		elif key.physical_keycode in _key_lane_map:
			matched_lane = _key_lane_map[key.physical_keycode]

		if matched_lane >= 0:
			var lane_x = LANE_POSITIONS[matched_lane] * screen_w
			var pos = Vector2(lane_x, judgment_line_y)
			if key.pressed and not key.echo:
				_lane_flash[matched_lane] = 1.0
				var finger_id = 100 + matched_lane
				touch_starts[finger_id] = {"pos": pos, "time": current_time}
				_handle_touch_down(finger_id, pos)
			elif not key.pressed:
				var finger_id = 100 + matched_lane
				_handle_touch_up(finger_id, pos)
				touch_starts.erase(finger_id)

func _handle_touch_down(finger: int, pos: Vector2) -> void:
	# For touch/mouse, require near judgment line; for keyboard (finger >= 100), skip Y check
	var is_keyboard = finger >= 100
	if not is_keyboard and absf(pos.y - judgment_line_y) > 80:
		return

	var best_note: NoteObject = null
	var best_dist: float = INF
	var best_time_diff: float = INF

	# For keyboard, determine exact lane and only match notes in that lane
	var lane_tolerance = 80.0  # touch/mouse
	if is_keyboard:
		lane_tolerance = screen_w * 0.15  # wider tolerance for keyboard lane matching

	for note_obj in active_notes:
		if note_obj.judged or note_obj.hold_active:
			continue
		var time_diff = current_time - note_obj.note_data.time_sec - GameManager.audio_offset
		if absf(time_diff) > Judge.GOOD_WINDOW:
			continue
		var note_x = note_obj.note_data.x * screen_w
		var dist = absf(pos.x - note_x)
		if dist > lane_tolerance:
			continue
		if dist < best_dist or (dist == best_dist and absf(time_diff) < absf(best_time_diff)):
			best_note = note_obj
			best_dist = dist
			best_time_diff = time_diff

	if best_note:
		if best_note.note_data.type == "flick":
			best_note.set_meta("pending_flick_finger", finger)
			return

		var result = Judge.judge_tap(best_time_diff)

		if best_note.note_data.type == "hold" and result.grade != Judge.Grade.MISS:
			# Hold: register head judgment but keep note alive
			score_tracker.register_judgment(result)
			_show_judgment(result, best_note.position)
			_update_ui()
			# Visual juice for the head tap
			_trigger_hit_effects(result, best_note.position)
			# Start hold tracking
			best_note.hold_active = true
			best_note.hold_finger_index = finger
			active_holds[finger] = best_note
		else:
			_apply_judgment(best_note, result)
			active_notes.erase(best_note)
			_remove_note_visual(best_note)

func _handle_touch_up(finger: int, pos: Vector2) -> void:
	if active_holds.has(finger):
		var note_obj = active_holds[finger]
		if is_instance_valid(note_obj):
			var remaining = note_obj.note_data.end_time_sec - current_time
			if remaining <= Judge.HOLD_TAIL_WINDOW:
				_complete_hold(note_obj, finger)
			else:
				note_obj.judged = true
				note_obj.hold_active = false
				var result = Judge.JudgmentResult.new()
				result.grade = Judge.Grade.MISS
				result.timing = Judge.Timing.EARLY
				score_tracker.register_judgment(result)
				_show_judgment(result, note_obj.position)
				_update_ui()
				active_notes.erase(note_obj)
				_remove_note_visual(note_obj)
		active_holds.erase(finger)

func _handle_drag(finger: int, pos: Vector2, relative: Vector2) -> void:
	if not touch_starts.has(finger):
		return
	var start_data = touch_starts[finger]
	var drag_vec = pos - start_data["pos"]
	if drag_vec.length() < 40:
		return
	var is_upward = drag_vec.y < 0 and absf(drag_vec.angle() + PI / 2.0) <= PI / 4.0
	if not is_upward:
		return

	for note_obj in active_notes:
		if note_obj.judged or note_obj.note_data.type != "flick":
			continue
		if note_obj.get_meta("pending_flick_finger", -1) != finger:
			continue
		var time_diff = start_data["time"] - note_obj.note_data.time_sec - GameManager.audio_offset
		var result = Judge.judge_tap(time_diff)
		_apply_judgment(note_obj, result)
		active_notes.erase(note_obj)
		_remove_note_visual(note_obj)
		touch_starts.erase(finger)
		break

func _apply_judgment(note_obj: NoteObject, result: Judge.JudgmentResult) -> void:
	note_obj.judged = true
	score_tracker.register_judgment(result)
	_show_judgment(result, note_obj.position)
	_update_ui()
	_trigger_hit_effects(result, note_obj.position)

func _trigger_hit_effects(result: Judge.JudgmentResult, pos: Vector2) -> void:
	match result.grade:
		Judge.Grade.PERFECT:
			_shake_intensity = 6.0
			_line_pulse = 1.0
			_spawn_hit_particles(pos, Judge.grade_to_color(result.grade), 12)
			_play_hitsound()
		Judge.Grade.GREAT:
			_shake_intensity = 3.0
			_line_pulse = 0.5
			_spawn_hit_particles(pos, Judge.grade_to_color(result.grade), 8)
			_play_hitsound()
		Judge.Grade.GOOD:
			_line_pulse = 0.2
			_spawn_hit_particles(pos, Judge.grade_to_color(result.grade), 4)
			_play_hitsound()
		Judge.Grade.MISS:
			pass

	if score_tracker.combo >= 2:
		_combo_target_scale = 1.0
		_combo_scale = 1.3

func _play_hitsound() -> void:
	if _hitsound_stream:
		hitsound_player.stream = _hitsound_stream
		hitsound_player.play()

func _spawn_hit_particles(pos: Vector2, color: Color, count: int) -> void:
	for i in range(count):
		var particle = HitParticle.new()
		particle.position = pos
		particle.color = color
		var angle = randf() * TAU
		var speed = randf_range(200, 500)
		particle.velocity = Vector2(cos(angle), sin(angle)) * speed
		particle.lifetime = randf_range(0.2, 0.5)
		particles_container.add_child(particle)

func _show_judgment(result: Judge.JudgmentResult, pos: Vector2) -> void:
	judgment_label.text = Judge.grade_to_string(result.grade)
	judgment_label.add_theme_color_override("font_color", Judge.grade_to_color(result.grade))
	judgment_label.visible = true
	judgment_label.modulate.a = 1.0
	judgment_label.offset_left = screen_w * 0.1
	judgment_label.offset_right = screen_w * 0.9
	judgment_label.offset_top = judgment_line_y + 10
	judgment_label.offset_bottom = judgment_line_y + 50
	judgment_display_timer = JUDGMENT_DISPLAY_DURATION

	if GameManager.show_early_late and result.grade != Judge.Grade.PERFECT:
		timing_label.text = "Early" if result.timing == Judge.Timing.EARLY else "Late"
		timing_label.visible = true
		timing_label.modulate.a = 1.0
	else:
		timing_label.visible = false

func _update_ui() -> void:
	score_label.text = "%d" % score_tracker.get_total_score()
	if score_tracker.combo >= 3:
		combo_label.text = "%d" % score_tracker.combo
		combo_label.visible = true
		combo_sub_label.visible = true
		if score_tracker.combo == 50 and _combo_50_stream:
			_shake_intensity = 10.0
			_combo_scale = 1.6
			hitsound_player.stream = _combo_50_stream
			hitsound_player.play()
		elif score_tracker.combo in [100, 200, 500] and _combo_100_stream:
			_shake_intensity = 12.0
			_combo_scale = 1.8
			hitsound_player.stream = _combo_100_stream
			hitsound_player.play()
	else:
		combo_label.visible = false
		combo_sub_label.visible = false

func _remove_note_visual(note_obj: NoteObject) -> void:
	if note_obj.is_inside_tree():
		note_obj.queue_free()

func _on_song_end() -> void:
	playing = false
	_show_results()

func _show_results() -> void:
	GameManager.last_result = {
		"score": score_tracker.get_total_score(),
		"rating": score_tracker.get_rating(),
		"max_combo": score_tracker.max_combo,
		"total_notes": score_tracker.total_notes,
		"perfect": score_tracker.perfect_count,
		"great": score_tracker.great_count,
		"good": score_tracker.good_count,
		"miss": score_tracker.miss_count,
		"early": score_tracker.early_count,
		"late": score_tracker.late_count,
	}
	get_tree().change_scene_to_file("res://scenes/result_screen.tscn")
