extends CharacterBody2D

# ──────────────────────────────────────────────────────────────────────────────
# Player
#
# Input actions (Project Settings → Input Map):
#   move_left, move_right, jump, interact
#
# The node is registered in the "player" group so enemies and interactables
# can find it via get_first_node_in_group("player").
#
# HealthManager.life_lost is connected in code (not editor) because it is a
# functional contract that must fire in every level — wiring it manually per
# scene would be error-prone for contributors.
#
# Editor signal connections required (in the player scene):
#   — none; area/body signals are handled on the interactable side
# ──────────────────────────────────────────────────────────────────────────────

@export_group("Movement")
@export var speed:         float = 120.0
@export var jump_velocity: float = -300.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _nearby_interactable: Node


func _ready() -> void:
	HealthManager.life_lost.connect(_on_life_lost)


# ── Public API ────────────────────────────────────────────────────────────────

## Called by enemies, kill zones, or any instant-death hazard.
func die() -> void:
	call_deferred("_handle_death")


## Register an interactable as the current interaction target.
## Calls show_prompt() on the node if it implements the method.
func set_interactable(node: Node) -> void:
	_nearby_interactable = node
	if node.has_method("show_prompt"):
		node.show_prompt()


## Clear the interaction target. Only clears if `node` is the current target
## so overlapping interactables don't accidentally clear each other.
## Calls hide_prompt() on the node if it implements the method.
func clear_interactable(node: Node) -> void:
	if _nearby_interactable == node:
		if node.has_method("hide_prompt"):
			node.hide_prompt()
		_nearby_interactable = null


# ── HealthManager handler ─────────────────────────────────────────────────────

func _on_life_lost() -> void:
	ScoreManager.reset_score()
	get_tree().reload_current_scene()


# ── Private ───────────────────────────────────────────────────────────────────

func _handle_death() -> void:
	HealthManager.lose_life()


func _interact() -> void:
	if _nearby_interactable:
		_nearby_interactable.interact(self)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var direction: float = Input.get_axis("move_left", "move_right")

	if direction > 0:
		_sprite.flip_h = false
	elif direction < 0:
		_sprite.flip_h = true

	if is_on_floor():
		_sprite.play("run" if direction != 0 else "idle")
	else:
		_sprite.play("jump")

	velocity.x = direction * speed if direction != 0 else move_toward(velocity.x, 0.0, speed)

	move_and_slide()

	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if collision.get_normal().y < -0.7:
			var collider := collision.get_collider()
			if collider and collider.has_method("activate"):
				collider.activate()

	if Input.is_action_just_pressed("interact"):
		_interact()
