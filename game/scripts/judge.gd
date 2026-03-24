class_name Judge
extends RefCounted

# Judgment windows (seconds)
const PERFECT_WINDOW: float = 0.045
const GREAT_WINDOW: float = 0.090
const GOOD_WINDOW: float = 0.130

# Hold tail is more lenient
const HOLD_TAIL_WINDOW: float = 0.100

# Score weights
const PRECISION_SCORE_MAX: float = 900000.0
const COMBO_SCORE_MAX: float = 100000.0

# Hold score distribution
const HOLD_HEAD_WEIGHT: float = 0.5
const HOLD_TAIL_WEIGHT: float = 0.3
const HOLD_SUSTAIN_WEIGHT: float = 0.2

enum Grade { PERFECT, GREAT, GOOD, MISS }
enum Timing { EARLY, LATE, EXACT }

class JudgmentResult:
	var grade: Grade = Grade.MISS
	var timing: Timing = Timing.EXACT
	var time_diff: float = 0.0  # signed: negative = early, positive = late

static func judge_tap(time_diff: float) -> JudgmentResult:
	var result = JudgmentResult.new()
	result.time_diff = time_diff
	var abs_diff = absf(time_diff)

	if abs_diff <= PERFECT_WINDOW:
		result.grade = Grade.PERFECT
		result.timing = Timing.EXACT
	elif abs_diff <= GREAT_WINDOW:
		result.grade = Grade.GREAT
		result.timing = Timing.EARLY if time_diff < 0 else Timing.LATE
	elif abs_diff <= GOOD_WINDOW:
		result.grade = Grade.GOOD
		result.timing = Timing.EARLY if time_diff < 0 else Timing.LATE
	else:
		result.grade = Grade.MISS
		result.timing = Timing.EARLY if time_diff < 0 else Timing.LATE

	return result

static func get_score_ratio(grade: Grade) -> float:
	match grade:
		Grade.PERFECT: return 1.0
		Grade.GREAT: return 0.7
		Grade.GOOD: return 0.3
		Grade.MISS: return 0.0
	return 0.0

static func grade_breaks_combo(grade: Grade) -> bool:
	return grade == Grade.MISS

static func grade_to_string(grade: Grade) -> String:
	match grade:
		Grade.PERFECT: return "Perfect"
		Grade.GREAT: return "Great"
		Grade.GOOD: return "Good"
		Grade.MISS: return "Miss"
	return ""

static func grade_to_color(grade: Grade) -> Color:
	match grade:
		Grade.PERFECT: return Color(1.0, 0.84, 0.0)  # Gold
		Grade.GREAT: return Color(1.0, 1.0, 1.0)      # White
		Grade.GOOD: return Color(0.6, 0.6, 0.6)       # Gray
		Grade.MISS: return Color(1.0, 0.2, 0.2)       # Red
	return Color.WHITE


class ScoreTracker:
	var total_notes: int = 0
	var combo: int = 0
	var max_combo: int = 0
	var perfect_count: int = 0
	var great_count: int = 0
	var good_count: int = 0
	var miss_count: int = 0
	var early_count: int = 0
	var late_count: int = 0
	var precision_score: float = 0.0

	func init(note_count: int) -> void:
		total_notes = note_count

	func register_judgment(result: JudgmentResult) -> void:
		match result.grade:
			Grade.PERFECT: perfect_count += 1
			Grade.GREAT: great_count += 1
			Grade.GOOD: good_count += 1
			Grade.MISS: miss_count += 1

		if result.timing == Timing.EARLY and result.grade != Grade.PERFECT:
			early_count += 1
		elif result.timing == Timing.LATE and result.grade != Grade.PERFECT:
			late_count += 1

		# Combo
		if Judge.grade_breaks_combo(result.grade):
			combo = 0
		else:
			combo += 1
			if combo > max_combo:
				max_combo = combo

		# Precision score
		if total_notes > 0:
			precision_score += Judge.get_score_ratio(result.grade) * PRECISION_SCORE_MAX / total_notes

	func get_total_score() -> int:
		var combo_score = 0.0
		if total_notes > 0:
			combo_score = float(max_combo) / float(total_notes) * COMBO_SCORE_MAX
		return roundi(precision_score + combo_score)

	func get_rating() -> String:
		var score = get_total_score()
		var is_all_perfect = (perfect_count == total_notes)
		var is_full_combo = (miss_count == 0)

		if is_all_perfect:
			return "Phi"
		elif is_full_combo and score >= 950000:
			return "V+S"
		elif is_full_combo:
			return "V"
		elif score >= 950000:
			return "S"
		elif score >= 900000:
			return "A"
		elif score >= 800000:
			return "B"
		elif score >= 700000:
			return "C"
		else:
			return "F"
