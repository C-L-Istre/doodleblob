extends AnimatableBody2D

# ──────────────────────────────────────────────────────────────────────────────
# Boat
#
# Simple patrol boat. Moves horizontally at a fixed speed and reverses
# direction when either RayCast2D detects a wall or ledge.
#
# Expected child nodes:
#   RayCastRight : RayCast2D  — detects walls / ledge on the right
#   RayCastLeft  : RayCast2D  — detects walls / ledge on the left
#   Sprite2D          — flipped to match direction
#
# ──────────────────────────────────────────────────────────────────────────────

const SPEED: float = 60.0

var _direction: float = 1.0
var _active: bool = false
var _players_inside: int = 0

@onready var _ray_right: RayCast2D        = $RayCastRight
@onready var _ray_left:  RayCast2D        = $RayCastLeft
@onready var _sprite:    Sprite2D         = $BoatSprite
@onready var _shader: ShaderMaterial = _sprite.material as ShaderMaterial

func _ready() -> void:
	_set_top_fade(1.0)

func _physics_process(delta: float) -> void:
	if not _active:
		return
	position.x += _direction * SPEED * delta
	
	if _ray_right.is_colliding():
		_direction      = -1.0
		_sprite.flip_h  = true
	elif _ray_left.is_colliding():
		_direction      = 1.0
		_sprite.flip_h  = false

func _on_activation_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_players_inside += 1
		_set_active(true)


func _on_activation_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_players_inside = max(_players_inside - 1, 0)

		if _players_inside == 0:
			_set_active(false)

func _set_active(value: bool) -> void:
	_active = value
	_set_top_fade(0.35 if value else 1.0)

func _set_top_fade(alpha: float) -> void:
	if _shader:
		_shader.set_shader_parameter("fade_alpha", alpha)
