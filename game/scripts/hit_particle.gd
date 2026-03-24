class_name HitParticle
extends Node2D

var velocity: Vector2 = Vector2.ZERO
var color: Color = Color.WHITE
var lifetime: float = 0.4
var _age: float = 0.0
var _size: float = 4.0

func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return

	# Move with deceleration
	position += velocity * delta
	velocity *= exp(-5.0 * delta)

	queue_redraw()

func _draw() -> void:
	var t = _age / lifetime
	var alpha = 1.0 - t * t  # quadratic fade
	var size = _size * (1.0 + t * 0.5)  # slight grow

	# Glow
	draw_circle(Vector2.ZERO, size * 2.0, Color(color.r, color.g, color.b, alpha * 0.2))
	# Core
	draw_circle(Vector2.ZERO, size, Color(color.r, color.g, color.b, alpha))
	# Bright center
	draw_circle(Vector2.ZERO, size * 0.4, Color(1, 1, 1, alpha * 0.6))
