extends AnimatableBody2D

# ──────────────────────────────────────────────────────────────────────────────
# Falling Platform
#
# Falls shortly after the one way collision detects a player
#
# ──────────────────────────────────────────────────────────────────────────────

const GRAVITY := 980.0
const FALL_DELAY := 0.5

var _triggered := false
var _falling := false
var _velocity_y := 0.0


func activate() -> void:
	if _triggered:
		return

	_triggered = true
	call_deferred("_fall")


func _fall() -> void:
	await get_tree().create_timer(FALL_DELAY).timeout
	_falling = true


func _physics_process(delta: float) -> void:
	if not _falling:
		return

	_velocity_y += GRAVITY * delta
	position.y += _velocity_y * delta
