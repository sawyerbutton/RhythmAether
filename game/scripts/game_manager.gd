extends Node

# Global game state and settings

# Audio offset calibrated by the player (seconds)
var audio_offset: float = 0.0

# Note fall speed multiplier (1.0x - 6.0x)
var fall_speed: float = 2.5

# Volume settings
var hitsound_volume: float = 0.6
var music_volume: float = 1.0

# Display settings
var show_early_late: bool = false
var vibration_enabled: bool = true
var background_brightness: float = 0.7
var note_size_scale: float = 1.0

# Selected chart (set by song select screen)
var selected_chart_path: String = "res://resources/charts/think_outside_the_box.json"

# Result data (passed between gameplay and result screen)
var last_result: Dictionary = {}
