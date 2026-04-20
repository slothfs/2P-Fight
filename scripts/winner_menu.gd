extends CanvasLayer

class_name WinnerMenu

@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var winner_label: Label = $Panel/VBoxContainer/WinnerLabel
@onready var play_again_button: Button = $Panel/VBoxContainer/PlayAgainButton
@onready var main_menu_button: Button = $Panel/VBoxContainer/MainMenuButton
@onready var quit_button: Button = $Panel/VBoxContainer/QuitButton

var game_manager: GameManager

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	game_manager = GameManager.instance
	panel.visible = false
	
	
	if game_manager:
		game_manager.game_over.connect(_on_game_over)

func _on_game_over(winner: int) -> void:
	await get_tree().process_frame
	var final_winner: int = winner
	if game_manager != null and game_manager.has_game_ended and game_manager.last_winner != 0:
		final_winner = game_manager.last_winner
	winner_label.text = "PLAYER %d WINS!" % final_winner
	title_label.text = "GAME OVER!"
	panel.visible = true
	get_tree().paused = true

func _on_play_again_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	SceneTransition.change_scene("res://Scenes/main_menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()
