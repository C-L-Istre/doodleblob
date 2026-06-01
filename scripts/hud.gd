extends CanvasLayer

# ──────────────────────────────────────────────────────────────────────────────
# HUD
#
# Displays in-game UI that persists across the level. Connects to
# ScoreManager.score_changed so the label updates reactively without polling.
#
# Expected scene structure:
#   HUD (CanvasLayer)
#   └── ... %ScoreLabel (Label)
# ──────────────────────────────────────────────────────────────────────────────

@onready var _score_label: Label = %ScoreLabel


func _ready() -> void:
	ScoreManager.score_changed.connect(_on_score_changed)
	_score_label.text = _format_score(ScoreManager.current_score)


# ── Signal handlers ───────────────────────────────────────────────────────────

func _on_score_changed(new_score: int) -> void:
	_score_label.text = _format_score(new_score)


# ── Helpers ───────────────────────────────────────────────────────────────────

## Override this to change the score display format across the whole game.
func _format_score(score: int) -> String:
	return "Score: %d" % score
