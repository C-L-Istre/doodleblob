extends CanvasLayer

# ──────────────────────────────────────────────────────────────────────────────
# HUD
#
# Displays score and lives. Labels are seeded from autoload state in _ready()
# and kept in sync via signal handlers connected in the scene editor.
#
# Signal connections are made in code (hud.tscn has no editor connections).
# If you add them in the editor instead, remove the connect() calls from _ready().
# ──────────────────────────────────────────────────────────────────────────────

@onready var _score_label: Label = %ScoreLabel
@onready var _lives_label: Label = %LivesLabel


func _ready() -> void:
	ScoreManager.score_changed.connect(_on_score_changed)
	HealthManager.lives_changed.connect(_on_lives_changed)
	_score_label.text = _format_score(ScoreManager.current_score)
	_lives_label.text = _format_lives(HealthManager.lives)


# ── Signal handlers (connected in code above, not in the editor) ──────────────

func _on_score_changed(new_score: int) -> void:
	_score_label.text = _format_score(new_score)


func _on_lives_changed(new_lives: int) -> void:
	_lives_label.text = _format_lives(new_lives)


# ── Helpers ───────────────────────────────────────────────────────────────────

## Override to change the score display format.
func _format_score(score: int) -> String:
	return "Score: %d" % score


## Override to change the lives display format (e.g. heart icons).
func _format_lives(lives: int) -> String:
	return "Lives: %d" % lives
