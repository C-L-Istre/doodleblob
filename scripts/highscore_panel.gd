extends PanelContainer

# ──────────────────────────────────────────────────────────────────────────────
# HighscorePanel
#
# Displays the all-time high score. Initialises from ScoreManager in _ready()
# and stays in sync via the high_score_changed signal — no external calls
# needed. Signal connection is made in code because ScoreManager is an autoload
# that doesn't appear in the editor's connection dialog.
# ──────────────────────────────────────────────────────────────────────────────

@onready var highscore_label: Label = %HighscoreLabel


func _ready() -> void:
	highscore_label.text = "High Score: %d" % ScoreManager.high_score
	ScoreManager.high_score_changed.connect(_on_high_score_changed)


func _on_high_score_changed(new_high: int) -> void:
	highscore_label.text = "High Score: %d" % new_high
