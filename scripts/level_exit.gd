extends Area2D

@export_file("*.tscn") var next_level_path: String

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		call_deferred("change_level")


func change_level() -> void:
	get_tree().change_scene_to_file(next_level_path)
