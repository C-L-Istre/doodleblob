extends Area2D

# ──────────────────────────────────────────────────────────────────────────────
# Coin (pickup)
#
# Calls ScoreManager.add_point() when collected, then plays the "pickup"
# animation. The AnimationPlayer should queue_free() the node at the end of
# the "pickup" animation via an Animation Track call.
# ──────────────────────────────────────────────────────────────────────────────

@onready var _anim: AnimationPlayer = $AnimationPlayer


func _on_body_entered(_body: Node) -> void:
	ScoreManager.add_point()
	_anim.play("pickup")
