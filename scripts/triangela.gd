extends CharacterBody2D

@onready var dialog_label: Label = %DialogLabel

func interact(_player: Node) -> void:
	dialog_label.text = "Triangela: Hey..."
	dialog_label.visible = not dialog_label.visible
	dialog_label.z_index = 100

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body._nearby_interactable = self

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body._nearby_interactable == self:
			body._nearby_interactable = null

		dialog_label.visible = false
