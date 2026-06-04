extends Area2D

# ──────────────────────────────────────────────────────────────────────────────
# KillZone
#
# Area2D that calls die() on any PhysicsBody that enters it.
# Use for pits, spikes, and any other instant-death hazard.
#
# Any body that implements die() will be killed — no group check is needed.
# This keeps the kill zone generic: players, enemies, and destructible objects
# all respond correctly as long as they implement the die() method.
# ──────────────────────────────────────────────────────────────────────────────

func _on_body_entered(body: Node) -> void:
	if body.has_method("die"):
		body.die()
