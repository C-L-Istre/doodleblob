extends Node

# ──────────────────────────────────────────────────────────────────────────────
# HealthManager  (autoload)
#
# Tracks lives and drives scene transitions on death. Emit signals drive the
# HUD and player script rather than polling `.lives` directly.
#
# Typical flow:
#   player.die() → HealthManager.lose_life()
#     ├─ lives remain → life_lost emitted → player resets score, reloads scene
#     └─ no lives left → game_over scene loaded directly
#
# Call reset_game() at the start of a new game (main_menu._on_play_pressed).
# Do NOT reset between levels — lives carry forward.
# ──────────────────────────────────────────────────────────────────────────────

signal lives_changed(lives: int)
signal life_lost()

const STARTING_LIVES:    int    = 3
const GAME_OVER_SCENE:   String = "res://scenes/ui/game_over.tscn"

var lives: int = STARTING_LIVES


# ── Public API ────────────────────────────────────────────────────────────────

## Full reset — call at the start of a new game, not between levels.
func reset_game() -> void:
	lives = STARTING_LIVES
	lives_changed.emit(lives)


## Instant life loss. Emits life_lost if lives remain, or loads the game over
## scene directly. Use from player.die() only — not from health damage logic.
func lose_life() -> void:
	lives -= 1
	lives_changed.emit(lives)

	if lives <= 0:
		call_deferred("_go_to_game_over")
	else:
		life_lost.emit()


## Award extra lives (power-up, milestone reward, etc.).
func gain_life(amount: int = 1) -> void:
	lives += amount
	lives_changed.emit(lives)


# ── Private ───────────────────────────────────────────────────────────────────

func _go_to_game_over() -> void:
	get_tree().change_scene_to_file(GAME_OVER_SCENE)
