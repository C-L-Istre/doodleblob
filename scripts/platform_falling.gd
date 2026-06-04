extends AnimatableBody2D

# ──────────────────────────────────────────────────────────────────────────────
# FallingPlatform
#
# Starts falling after FALL_DELAY seconds when activate() is called.
# activate() is triggered by the player's collision detection in player.gd
# whenever the player lands on a body that has an activate() method.
#
# The platform queue_frees itself once it falls far enough off screen.
# ──────────────────────────────────────────────────────────────────────────────

@export var fall_delay:    float = 0.5
@export var gravity:       float = 980.0
@export var despawn_depth: float = 2000.0

var _triggered:     bool  = false
var _falling:       bool  = false
var _fall_velocity: float = 0.0


## Called by the player on landing. Begins the fall countdown.
func activate() -> void:
	if _triggered:
		return
	_triggered = true
	_begin_fall_countdown()


func _begin_fall_countdown() -> void:
	await get_tree().create_timer(fall_delay).timeout
	_falling = true


func _physics_process(delta: float) -> void:
	if not _falling:
		return

	_fall_velocity += gravity * delta
	position.y     += _fall_velocity * delta

	if position.y > despawn_depth:
		queue_free()
