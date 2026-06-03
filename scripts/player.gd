extends CharacterBody2D

# ──────────────────────────────────────────────────────────────────────────────
# Player
#
# CharacterBody2D with gravity, left/right movement, jump, animated sprite
# flipping, and a die() method that reloads the current scene.
#
# Input actions used (configure in Project Settings → Input Map):
#   move_left, move_right, jump
#
# The node is registered in the "player" global group so other nodes (enemies,
# level exits) can find it via get_first_node_in_group("player").
# ──────────────────────────────────────────────────────────────────────────────

const SPEED:         float = 120.0
const JUMP_VELOCITY: float = -300.0

@onready var _sprite:    AnimatedSprite2D = $AnimatedSprite2D

var _nearby_interactable: Node

# ── Public API ────────────────────────────────────────────────────────────────

## Called by enemies, kill zones, or any hazard that can kill the player.
## Saves the current score as a high score candidate before resetting,
## then reloads the current scene via call_deferred to avoid physics callback issues.
func die() -> void:
	ScoreManager.reset_score()
	call_deferred("_handle_death")
	
func _handle_death() -> void:
	HealthManager.lose_life()

	if HealthManager.lives > 0:
		get_tree().reload_current_scene()

func _interact() -> void:
	print(_nearby_interactable)
	print(_nearby_interactable.get_class())

	if _nearby_interactable:
		_nearby_interactable.interact(self)

# ── Private ───────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Horizontal input
	var direction: float = Input.get_axis("move_left", "move_right")

	# Flip sprite to face movement direction
	if direction > 0:
		_sprite.flip_h = false
	elif direction < 0:
		_sprite.flip_h = true

	# Animations
	if is_on_floor():
		_sprite.play("run" if direction != 0 else "idle")
	else:
		_sprite.play("jump")

	# Movement
	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	move_and_slide()

	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)

		if collision.get_normal().y < -0.7:
			var collider := collision.get_collider()

			if collider and collider.has_method("activate"):
				collider.activate()

	if Input.is_action_just_pressed("interact"):
		_interact()
