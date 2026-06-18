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
# HealthManager.life_lost is connected in code — it is a functional contract
# that must fire in every level and would be error-prone to wire per scene.
#
# DialogBox is resolved by unique name at _ready() time. Any level scene that
# contains a DialogBox node marked unique_name_in_owner = true will have dialog
# work automatically — no per-level Inspector wiring required.
# ──────────────────────────────────────────────────────────────────────────────

@export_group("Movement")
@export var speed:         float = 120.0
@export var jump_velocity: float = -300.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _nearby_interactable: Node
var _can_move:            bool = true

# Resolved at _ready() via unique name — null if the level has no DialogBox.
var dialog_box: Node


func _ready() -> void:
	dialog_box = get_tree().get_first_node_in_group("dialog_box")

	if dialog_box:
		dialog_box.dialog_started.connect(_on_dialog_started)
		dialog_box.dialog_ended.connect(_on_dialog_ended)

	HealthManager.life_lost.connect(_on_life_lost)


# ── Public API ────────────────────────────────────────────────────────────────

## Called by enemies, kill zones, or any instant-death hazard.
func die() -> void:
	call_deferred("_handle_death")


## Register an interactable as the current interaction target.
## Called by interactable nodes when the player enters their detection area.
func set_interactable(node: Node) -> void:
	_nearby_interactable = node
	if node.has_method("show_prompt"):
		node.show_prompt()


## Clear the interaction target. Only clears if `node` is the current target
## so overlapping interactables don't accidentally clear each other.
func clear_interactable(node: Node) -> void:
	if _nearby_interactable == node:
		if node.has_method("hide_prompt"):
			node.hide_prompt()
		_nearby_interactable = null


## Start a dialog conversation. Called by interactables in their interact().
## Does nothing if no DialogBox is present in the level.
func start_dialog(data: DialogData) -> void:
	if dialog_box:
		dialog_box.start(data)


# ── HealthManager signal handler ──────────────────────────────────────────────

func _on_life_lost() -> void:
	ScoreManager.reset_score()
	get_tree().reload_current_scene()


# ── DialogBox signal handlers ─────────────────────────────────────────────────

func _on_dialog_started() -> void:
	_can_move = false


func _on_dialog_ended() -> void:
	_can_move = true


# ── Private ───────────────────────────────────────────────────────────────────

func _handle_death() -> void:
	HealthManager.lose_life()


func _interact() -> void:
	# If dialog is open, advance it rather than re-triggering the interactable.
	if dialog_box and dialog_box.visible:
		dialog_box.advance()
		return

	if _nearby_interactable:
		_nearby_interactable.interact(self)


func _physics_process(delta: float) -> void:
	if UIManager.is_text_input() or UIManager.is_menu():
		return
	if not is_on_floor():
		velocity += get_gravity() * delta

	if _can_move:
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

	else:
		# Frozen during dialog — bleed off horizontal velocity, keep idle animation.
		velocity.x = move_toward(velocity.x, 0.0, speed)
		if is_on_floor():
			_sprite.play("idle")

	move_and_slide()

	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if collision.get_normal().y < -0.7:
			var collider := collision.get_collider()
			if collider and collider.has_method("activate"):
				collider.activate()

	if Input.is_action_just_pressed("interact"):
		_interact()
