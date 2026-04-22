extends CanvasLayer

class_name WinnerMenu

@onready var background_texture: TextureRect = $BackgroundTexture
@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var winner_label: Label = $Panel/VBoxContainer/WinnerLabel
@onready var screenshot_rect: TextureRect = $Panel/VBoxContainer/PhotoFrame/ScreenshotRect
@onready var play_again_button: Button = $Panel/VBoxContainer/PlayAgainButton
@onready var main_menu_button: Button = $Panel/VBoxContainer/MainMenuButton
@onready var quit_button: Button = $Panel/VBoxContainer/QuitButton

var game_manager: GameManager

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	game_manager = GameManager.instance
	panel.visible = false
	if background_texture: background_texture.visible = false
	
	if game_manager:
		game_manager.game_over.connect(_on_game_over)

func _on_game_over(winner: int) -> void:
	# Capture screenshot BEFORE showing UI or pausing
	var img = get_viewport().get_texture().get_image()
	
	var full_tex = ImageTexture.create_from_image(img)
	
	var final_winner: int = winner
	if game_manager != null and game_manager.has_game_ended and game_manager.last_winner != 0:
		final_winner = game_manager.last_winner
		
	var player_node_name = "Player" + str(final_winner)
	var player = get_tree().current_scene.get_node_or_null(player_node_name)
	
	if player:
		var player_screen_pos = player.get_global_transform_with_canvas().origin
		var zoom_size = Vector2(640, 360) # 16:9 ratio, suitable for the photo frame
		
		zoom_size.x = min(zoom_size.x, img.get_size().x)
		zoom_size.y = min(zoom_size.y, img.get_size().y)
		
		var rect = Rect2(player_screen_pos - zoom_size / 2.0, zoom_size)
		
		rect.position.x = clamp(rect.position.x, 0, max(0, img.get_size().x - zoom_size.x))
		rect.position.y = clamp(rect.position.y, 0, max(0, img.get_size().y - zoom_size.y))
		
		img = img.get_region(rect)

	var tex = ImageTexture.create_from_image(img)
	
	await get_tree().process_frame
	
	winner_label.text = "PLAYER %d WINS!" % final_winner
	title_label.text = "GAME OVER!"
	panel.visible = true
	
	if screenshot_rect:
		screenshot_rect.texture = tex
	
	if background_texture:
		# Use full screenshot for background
		background_texture.texture = full_tex
		background_texture.visible = true
		background_texture.modulate = Color(0.3, 0.3, 0.3, 1.0)
		
	get_tree().paused = true
	
	_play_appear_animation()

func _play_appear_animation() -> void:
	# Animate the background
	if background_texture:
		background_texture.modulate.a = 0
		var bg_tween = create_tween()
		bg_tween.tween_property(background_texture, "modulate:a", 1.0, 0.5)

	# Animate the panel (like a scene transition / slide-in with bounce)
	panel.pivot_offset = panel.size / 2.0
	panel.position.y = -800 # Start off-screen top
	panel.rotation = -0.1 # Slight tilt
	panel.scale = Vector2(0.5, 0.5)
	
	var panel_tween = create_tween()
	panel_tween.set_parallel(true)
	panel_tween.set_trans(Tween.TRANS_SPRING)
	panel_tween.set_ease(Tween.EASE_OUT)
	
	var final_pos_y = (get_viewport().get_visible_rect().size.y / 2.0) - (panel.size.y / 2.0)
	panel_tween.tween_property(panel, "position:y", final_pos_y, 0.8)
	panel_tween.tween_property(panel, "rotation", 0.0, 0.8)
	panel_tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.8)
	
	# Animate the photo frame specially
	var photo_frame = $Panel/VBoxContainer/PhotoFrame
	if photo_frame:
		photo_frame.pivot_offset = photo_frame.size / 2.0
		photo_frame.scale = Vector2(3.0, 3.0)
		photo_frame.rotation = 0.5
		var photo_tween = create_tween()
		photo_tween.set_trans(Tween.TRANS_BACK)
		photo_tween.set_ease(Tween.EASE_OUT)
		photo_tween.tween_interval(0.4) # Wait for panel to mostly appear
		photo_tween.tween_property(photo_frame, "scale", Vector2(1.0, 1.0), 0.6)
		photo_tween.parallel().tween_property(photo_frame, "rotation", -0.05, 0.6)

func _on_play_again_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	SceneTransition.change_scene("res://Scenes/main_menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()
