extends Node2D

# ──────────────────────────────────────────────────────────────────────────────
# Enemy
#
# Patrol enemy. Reverses direction at walls and ledges.
#
# Expected child nodes:
#   RayCastRight     : RayCast2D        — wall / ledge detection on the right
#   RayCastLeft      : RayCast2D        — wall / ledge detection on the left
#   AnimatedSprite2D                    — flipped to match direction
#   Area2D with CollisionShape2D        — body_entered connected in editor
#                                         to _on_body_entered
# ──────────────────────────────────────────────────────────────────────────────

@export var speed: float = 60.0

var _direction: float = 1.0

@onready var _ray_right: RayCast2D        = $RayCastRight
@onready var _ray_left:  RayCast2D        = $RayCastLeft
@onready var _sprite:    AnimatedSprite2D = $AnimatedSprite2D


# ── Area2D body_entered (connect in editor) ───────────────────────────────────

func _on_body_entered(body: Node) -> void:
	if body.has_method("die"):
		body.die()


func _process(delta: float) -> void:
	if _ray_right.is_colliding():
		_direction     = -1.0
		_sprite.flip_h = true
	elif _ray_left.is_colliding():
		_direction     = 1.0
		_sprite.flip_h = false

	position.x += _direction * speed * delta
