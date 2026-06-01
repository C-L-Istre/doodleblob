extends CanvasLayer

func _ready() -> void:
	if not PlatformDetection.has_touch():
		queue_free()
