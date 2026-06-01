extends CanvasLayer

# ──────────────────────────────────────────────────────────────────────────────────────────
# HUD
#
# Displays in-game UI that persists across the level. Connects to ScoreManager.score_changed
# so the label updates reactively without polling.
#
# ──────────────────────────────────────────────────────────────────────────────────────────

@onready var score_label: Label = %ScoreLabel
@onready var lives_label: Label = %LivesLabel



func _ready() -> void:
	ScoreManager.score_changed.connect(_on_score_changed)
	score_label.text = _format_score(ScoreManager.current_score)
	lives_label.text = "Lives: %d" % HealthManager.lives


func _on_lives_changed(lives: int) -> void:
	lives_label.text = "Lives: %d" % lives


# ── Signal handlers ───────────────────────────────────────────────────────────

func _on_score_changed(new_score: int) -> void:
	score_label.text = _format_score(new_score)


# ── Helpers ───────────────────────────────────────────────────────────────────

## Override this to change the score display format across the whole game.
func _format_score(score: int) -> String:
	return "Score: %d" % score
