extends CanvasLayer

class_name PauseMenu

@onready var color_rect: ColorRect = $ColorRect
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
	if color_rect: color_rect.visible = false
	
	resume_button.pressed.connect(_on_resume_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	var settings_btn = Button.new()
	settings_btn.text = "Settings"
	
	settings_btn.custom_minimum_size = Vector2(0, 70)
	settings_btn.add_theme_color_override("font_color", Color(0.000002, 0, 0.666229, 1))
	settings_btn.add_theme_font_size_override("font_size", 28)

	var sb_normal = StyleBoxFlat.new()
	sb_normal.bg_color = Color(1, 1, 1, 1)
	sb_normal.border_width_left = 2
	sb_normal.border_width_top = 2
	sb_normal.border_width_right = 2
	sb_normal.border_width_bottom = 2
	sb_normal.border_color = Color(0, 0, 0, 1)
	sb_normal.corner_radius_top_left = 10
	sb_normal.corner_radius_top_right = 10
	sb_normal.corner_radius_bottom_right = 10
	sb_normal.corner_radius_bottom_left = 10
	settings_btn.add_theme_stylebox_override("normal", sb_normal)

	var sb_hover = StyleBoxFlat.new()
	sb_hover.bg_color = Color(0.165625, 0.000008, 0.705698, 1)
	sb_hover.border_width_left = 2
	sb_hover.border_width_top = 2
	sb_hover.border_width_right = 2
	sb_hover.border_width_bottom = 2
	sb_hover.border_color = Color(0, 0, 0, 1)
	sb_hover.corner_radius_top_left = 10
	sb_hover.corner_radius_top_right = 10
	sb_hover.corner_radius_bottom_right = 10
	sb_hover.corner_radius_bottom_left = 10
	settings_btn.add_theme_stylebox_override("hover", sb_hover)

	$Panel/VBoxContainer.add_child(settings_btn)
	$Panel/VBoxContainer.move_child(settings_btn, 3)
	settings_btn.pressed.connect(_on_settings_pressed)
	
	var sm = preload("res://Scenes/settings_menu.tscn").instantiate()
	sm.hide()
	sm.name = "SettingsMenu"
	add_child(sm)
	
	if game_manager:
		game_manager.game_paused.connect(_on_game_paused)

func _on_game_paused(paused: bool) -> void:
	panel.visible = paused
	if color_rect: color_rect.visible = paused
	get_tree().paused = paused
	if not paused and has_node("SettingsMenu"):
		$SettingsMenu.hide()

func _on_settings_pressed() -> void:
	$SettingsMenu.show()

func _on_resume_pressed() -> void:
	if game_manager:
		game_manager.resume_game()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	SceneTransition.change_scene("res://Scenes/main_menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()
