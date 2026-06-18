extends PanelContainer

# ──────────────────────────────────────────────────────────────────────────────
# HighscorePanel
#
# Displays the local leaderboard as multi-line text via the existing
# %HighscoreLabel: "1. Name — Score" per entry, one per line. Initialises from
# ScoreManager in _ready() and stays in sync via leaderboard_changed -- no
# external calls needed. Signal connection is made in code because
# ScoreManager is an autoload that doesn't appear in the editor's connection
# dialog.
#
# %HighscoreLabel needs Autowrap enabled and enough vertical room for
# MAX_ENTRIES (10) lines -- adjust custom_minimum_size in the editor if
# entries get clipped.
# ──────────────────────────────────────────────────────────────────────────────

@onready var highscore_label: Label = %HighscoreLabel


func _ready() -> void:
	_refresh()
	ScoreManager.leaderboard_changed.connect(_refresh)


func _refresh() -> void:
	if ScoreManager.leaderboard.is_empty():
		highscore_label.text = "No scores yet — be the first!"
		return

	var lines: PackedStringArray = []
	for i in ScoreManager.leaderboard.size():
		var entry: Dictionary = ScoreManager.leaderboard[i]
		lines.append("%d. %s — %d" % [i + 1, entry["name"], entry["score"]])
	highscore_label.text = "\n".join(lines)
