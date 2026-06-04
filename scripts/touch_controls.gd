extends CanvasLayer

# ──────────────────────────────────────────────────────────────────────────────
# TouchControls
#
# On-screen controls overlay for touch devices. Removed from the scene tree on non-touch platforms.
# ──────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	if not PlatformDetection.has_touch():
		queue_free()
