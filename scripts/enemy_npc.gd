class_name EnemyNPC
extends CharacterBody2D

# ──────────────────────────────────────────────────────────────────────────────
# EnemyNPC
#
# A patrolling enemy that can also be interacted with for dialog.
#
# Two Area2D children define the two zones:
#   DamageArea     — small, matches the visible sprite. Player contact → die().
#   InteractArea — larger outer ring. Player enters → prompt appears.
#                  Player presses interact → dialog opens, patrol pauses.
#
# Scene setup (connect signals in the editor):
#   DamageArea.body_entered     → _on_damage_area_body_entered
#   InteractArea.body_entered → _on_interact_area_body_entered
#   InteractArea.body_exited  → _on_interact_area_body_exited
#   %PromptLabel : Label      — world-space prompt above NPC
#   $RayCastRight : RayCast2D — wall / ledge detection on the right
#   $RayCastLeft  : RayCast2D — wall / ledge detection on the left
#   $AnimatedSprite2D
# ──────────────────────────────────────────────────────────────────────────────

@export_group("Patrol")
## Movement speed in pixels per second.
@export var speed: float = 60.0

@export_group("Dialog")
## Conversation data. Set in the Inspector or assign a saved .tres resource.
@export var dialog_data: DialogData
## Label shown above the NPC when the player is in range.
@export var prompt_text: String = "Press [F] to Talk"

@onready var _ray_right:    RayCast2D        = $RayCastRight
@onready var _ray_left:     RayCast2D        = $RayCastLeft
@onready var _sprite:       AnimatedSprite2D = $AnimatedSprite2D
@onready var _prompt_label: Label            = %PromptLabel

var _direction: float = 1.0
## Set true while dialog is open so the enemy stops patrolling.
var _in_dialog: bool  = false


func _ready() -> void:
	_prompt_label.text = prompt_text
	_prompt_label.visible = false


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Stop while talking
	if _in_dialog:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		move_and_slide()
		return

	# Turn around
	if _ray_right.is_colliding():
		_direction = -1.0
		_sprite.flip_h = true
	elif _ray_left.is_colliding():
		_direction = 1.0
		_sprite.flip_h = false

	velocity.x = _direction * speed
	move_and_slide()


func show_prompt() -> void:
	_prompt_label.visible = true


func hide_prompt() -> void:
	_prompt_label.visible = false


func interact(player: Node) -> void:
	if not dialog_data:
		return

	_in_dialog = true

	var db: Node = player.dialog_box
	if db:
		db.dialog_ended.connect(
			func() -> void:
				_in_dialog = false,
			CONNECT_ONE_SHOT
		)

	player.start_dialog(dialog_data)


func _on_interact_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.set_interactable(self)


func _on_interact_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.clear_interactable(self)


func _on_damage_area_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.die()
