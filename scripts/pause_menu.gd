extends CanvasLayer

class_name PauseMenu

@onready var panel: Panel = $Panel
@onready var resume_button: Button = $Panel/VBoxContainer/ResumeButton
@onready var main_menu_button: Button = $Panel/VBoxContainer/MainMenuButton
@onready var quit_button: Button = $Panel/VBoxContainer/QuitButton

var game_manager: GameManager

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	game_manager = GameManager.instance
	panel.visible = false
	
	resume_button.pressed.connect(_on_resume_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	if game_manager:
		game_manager.game_paused.connect(_on_game_paused)

func _on_game_paused(paused: bool) -> void:
	panel.visible = paused
	get_tree().paused = paused

func _on_resume_pressed() -> void:
	if game_manager:
		game_manager.resume_game()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	SceneTransition.change_scene("res://Scenes/main_menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()
