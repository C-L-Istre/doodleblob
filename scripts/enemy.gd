extends Node2D

# ──────────────────────────────────────────────────────────────────────────────
# Enemy
#
# Simple patrol enemy. Moves horizontally at a fixed speed and reverses
# direction when either RayCast2D detects a wall or ledge.
#
# Expected child nodes:
#   RayCastRight : RayCast2D  — detects walls / ledge on the right
#   RayCastLeft  : RayCast2D  — detects walls / ledge on the left
#   AnimatedSprite2D          — flipped to match direction
#
# The attached Area2D (with its own CollisionShape2D) should connect its
# body_entered signal to _on_body_entered to damage the player on contact.
# ──────────────────────────────────────────────────────────────────────────────

const SPEED: float = 60.0

var _direction: float = 1.0

@onready var _ray_right: RayCast2D        = $RayCastRight
@onready var _ray_left:  RayCast2D        = $RayCastLeft
@onready var _sprite:    AnimatedSprite2D = $AnimatedSprite2D


func _on_body_entered(body: Node) -> void:
	if body.has_method("die"):
		body.die()


func _process(delta: float) -> void:
	if _ray_right.is_colliding():
		_direction      = -1.0
		_sprite.flip_h  = true
	elif _ray_left.is_colliding():
		_direction      = 1.0
		_sprite.flip_h  = false

	position.x += _direction * SPEED * delta
