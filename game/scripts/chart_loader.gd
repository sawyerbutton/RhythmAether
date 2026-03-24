class_name ChartLoader
extends RefCounted

# Parses RACF JSON into usable data structures

class TimingPoint:
	var beat: float
	var bpm: float
	var time_sig_num: int = 4
	var time_sig_den: int = 4

class NoteData:
	var type: String  # "tap", "hold", "flick", "slide"
	var beat: float
	var x: float
	var end_beat: float = -1  # hold only
	var nodes: Array = []  # slide only: [{beat, x}, ...]
	var time_sec: float = 0.0  # computed
	var end_time_sec: float = 0.0  # computed for hold

class ChartData:
	var version: String
	var title: String
	var artist: String
	var charter: String
	var audio_file: String
	var video_file: String = ""
	var difficulty_label: String
	var difficulty_level: int
	var timing_points: Array[TimingPoint] = []
	var offset: float = 0.0
	var notes: Array[NoteData] = []
	var total_note_count: int = 0

static func load_chart(path: String) -> ChartData:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Failed to open chart file: %s" % path)
		return null

	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	if err != OK:
		push_error("Failed to parse chart JSON: %s" % json.get_error_message())
		return null

	var data = json.data
	return _parse_chart(data)

static func _parse_chart(data: Dictionary) -> ChartData:
	var chart = ChartData.new()
	chart.version = data.get("version", "1.0.0")
	chart.offset = data.get("offset", 0.0)

	# Metadata
	var meta = data.get("metadata", {})
	chart.title = meta.get("title", "Unknown")
	chart.artist = meta.get("artist", "Unknown")
	chart.charter = meta.get("charter", "")
	chart.audio_file = meta.get("audioFile", "")
	chart.video_file = meta.get("videoFile", "")
	var diff = meta.get("difficulty", {})
	chart.difficulty_label = diff.get("label", "Normal")
	chart.difficulty_level = diff.get("level", 5)

	# Timing points
	for tp_data in data.get("timing", []):
		var tp = TimingPoint.new()
		tp.beat = tp_data.get("beat", 0.0)
		tp.bpm = tp_data.get("bpm", 120.0)
		var ts = tp_data.get("timeSignature", {})
		tp.time_sig_num = ts.get("numerator", 4)
		tp.time_sig_den = ts.get("denominator", 4)
		chart.timing_points.append(tp)

	# Sort timing points by beat
	chart.timing_points.sort_custom(func(a, b): return a.beat < b.beat)

	# Notes
	for note_data in data.get("notes", []):
		var note = NoteData.new()
		note.type = note_data.get("type", "tap")
		note.beat = note_data.get("beat", 0.0)
		note.x = note_data.get("x", 0.5)

		if note.type == "hold":
			note.end_beat = note_data.get("endBeat", note.beat + 1.0)

		if note.type == "slide":
			for node in note_data.get("nodes", []):
				note.nodes.append({
					"beat": node.get("beat", 0.0),
					"x": node.get("x", 0.5)
				})

		# Compute time in seconds from beat
		note.time_sec = beat_to_time(note.beat, chart.timing_points, chart.offset)
		if note.type == "hold":
			note.end_time_sec = beat_to_time(note.end_beat, chart.timing_points, chart.offset)

		chart.notes.append(note)

	# Sort notes by time
	chart.notes.sort_custom(func(a, b): return a.time_sec < b.time_sec)
	chart.total_note_count = chart.notes.size()

	return chart

static func beat_to_time(beat: float, timing_points: Array[TimingPoint], offset: float) -> float:
	if timing_points.is_empty():
		return beat * 0.5 + offset  # fallback: 120 BPM

	var time: float = 0.0
	var current_beat: float = 0.0
	var current_bpm: float = timing_points[0].bpm

	for i in range(timing_points.size()):
		var tp = timing_points[i]
		if tp.beat > beat:
			break
		# Accumulate time from previous segment
		if tp.beat > current_beat:
			time += (tp.beat - current_beat) * 60.0 / current_bpm
			current_beat = tp.beat
		current_bpm = tp.bpm

	# Remaining beats at current BPM
	time += (beat - current_beat) * 60.0 / current_bpm
	return time + offset
