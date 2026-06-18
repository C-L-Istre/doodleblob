extends Area2D

# ──────────────────────────────────────────────────────────────────────────────
# Coin (pickup)
#
# Calls ScoreManager.add_point() and emits `collected` when picked up, then
# plays the "pickup" animation. The AnimationPlayer should queue_free() the
# node at the end of the "pickup" animation via an Animation Track call.
#
# Must be in the "coins" group for level.gd to count it toward the
# "collect all coins" total -- set this on coin.tscn in the editor
# (Node > Groups) so every instance inherits it.
# ──────────────────────────────────────────────────────────────────────────────

## Emitted on pickup, before ScoreManager.add_point(). level.gd connects to
## this for every coin in the "coins" group to track per-level completion.
signal collected

@onready var _anim: AnimationPlayer = $AnimationPlayer


func _on_body_entered(_body: Node) -> void:
	collected.emit()
	ScoreManager.add_point()
	_anim.play("pickup")
