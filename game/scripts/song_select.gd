extends Control

# Song selection screen
# Scans charts directory and lets the player pick a song

@onready var song_list: VBoxContainer = $ScrollContainer/SongList
@onready var bg: TextureRect = $Background

var _charts: Array[Dictionary] = []  # [{path, title, artist, difficulty, level}]
var _selected_index: int = 0
var _time: float = 0.0

func _ready() -> void:
	_scan_charts()
	_build_list()
	if _charts.size() > 0:
		_select(0)

func _scan_charts() -> void:
	var dir = DirAccess.open("res://resources/charts/")
	if not dir:
		push_error("Cannot open charts directory")
		return
	dir.list_dir_begin()
	var file = dir.get_next()
	while file != "":
		if file.ends_with(".json") and file != "racf_schema.json":
			var path = "res://resources/charts/" + file
			var chart_data = _read_chart_meta(path)
			if chart_data:
				_charts.append(chart_data)
		file = dir.get_next()
	# Sort by title
	_charts.sort_custom(func(a, b): return a["title"] < b["title"])

func _read_chart_meta(path: String) -> Dictionary:
	var f = FileAccess.open(path, FileAccess.READ)
	if not f:
		return {}
	var json = JSON.new()
	if json.parse(f.get_as_text()) != OK:
		return {}
	var data = json.data
	var meta = data.get("metadata", {})
	var diff = meta.get("difficulty", {})
	return {
		"path": path,
		"title": meta.get("title", "Unknown"),
		"artist": meta.get("artist", "Unknown"),
		"difficulty": diff.get("label", "Normal"),
		"level": diff.get("level", 5),
	}

func _build_list() -> void:
	# Clear existing
	for child in song_list.get_children():
		child.queue_free()

	for i in range(_charts.size()):
		var chart = _charts[i]
		var item = _create_song_item(i, chart)
		song_list.add_child(item)

func _create_song_item(index: int, chart: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.22, 0.6)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	panel.set_meta("index", index)

	var vbox = VBoxContainer.new()

	var title_label = Label.new()
	title_label.text = chart["title"]
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.95))
	vbox.add_child(title_label)

	var info_label = Label.new()
	info_label.text = "%s  |  %s Lv.%d" % [chart["artist"], chart["difficulty"], chart["level"]]
	info_label.add_theme_font_size_override("font_size", 14)
	info_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65, 0.8))
	vbox.add_child(info_label)

	panel.add_child(vbox)
	return panel

func _select(index: int) -> void:
	_selected_index = clampi(index, 0, _charts.size() - 1)
	# Update visual selection
	for i in range(song_list.get_child_count()):
		var panel = song_list.get_child(i) as PanelContainer
		if not panel:
			continue
		var style = panel.get_theme_stylebox("panel") as StyleBoxFlat
		if i == _selected_index:
			style.bg_color = Color(0.91, 0.27, 0.37, 0.35)
			style.border_color = Color(0.91, 0.27, 0.37, 0.7)
			style.border_width_left = 3
			style.border_width_right = 3
			style.border_width_top = 3
			style.border_width_bottom = 3
		else:
			style.bg_color = Color(0.15, 0.15, 0.22, 0.6)
			style.border_width_left = 0
			style.border_width_right = 0
			style.border_width_top = 0
			style.border_width_bottom = 0

func _process(delta: float) -> void:
	_time += delta

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_UP, KEY_W:
				_select(_selected_index - 1)
			KEY_DOWN, KEY_S:
				_select(_selected_index + 1)
			KEY_ENTER, KEY_SPACE:
				_start_song()
			KEY_ESCAPE, KEY_Q:
				get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
	elif event is InputEventMouseButton and event.pressed:
		# Check which song was clicked
		for i in range(song_list.get_child_count()):
			var panel = song_list.get_child(i) as PanelContainer
			if panel and panel.get_global_rect().has_point(event.position):
				if _selected_index == i:
					_start_song()
				else:
					_select(i)
				break

func _start_song() -> void:
	if _selected_index < 0 or _selected_index >= _charts.size():
		return
	var chart = _charts[_selected_index]
	GameManager.selected_chart_path = chart["path"]
	get_tree().change_scene_to_file("res://scenes/gameplay.tscn")
