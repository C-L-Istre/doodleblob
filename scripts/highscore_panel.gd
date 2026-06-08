extends PanelContainer

@onready var highscore_label: Label = %HighscoreLabel

func _ready() -> void:
	highscore_label.text = "High Score: %d" % ScoreManager.high_score
	ScoreManager.high_score_changed.connect(_on_high_score_changed)


func _on_high_score_changed(new_high: int) -> void:
	highscore_label.text = "High Score: %d" % new_high


func set_high_score(score: int) -> void:
	highscore_label.text = "High Score: %d" % score
