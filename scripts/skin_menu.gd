extends Control

class_name SkinMenu

@onready var p1_skin_container: HBoxContainer = $VBoxContainer/Player1Skins
@onready var p2_skin_container: HBoxContainer = $VBoxContainer/Player2Skins
@onready var back_button: Button = $VBoxContainer/BackButton
@onready var play_button: Button = $VBoxContainer/PlayButton

var skin_variants: Array[int] = [0, 1, 2, 3] # 0 for normal, 1, 2, 3 for variants

func _ready() -> void:
	self.theme = load("res://cartoon_theme.tres")
	for btn in [back_button, play_button]:
		if btn:
			for prop in ["normal", "hover", "pressed", "focus"]:
				btn.remove_theme_stylebox_override(prop)
			for prop in ["font_color", "font_hover_color", "font_pressed_color"]:
				btn.remove_theme_color_override(prop)

	_create_skin_buttons(p1_skin_container, 1)
	_create_skin_buttons(p2_skin_container, 2)

	back_button.pressed.connect(_on_back_pressed)
	play_button.pressed.connect(_on_play_pressed)

func _create_skin_buttons(container: HBoxContainer, player_num: int) -> void:
	var gm = get_node_or_null("/root/GameManager")
	var current_skin = 0
	if gm:
		current_skin = gm.player1_skin_id if player_num == 1 else gm.player2_skin_id

	var white_sb = StyleBoxFlat.new()
	white_sb.bg_color = Color.WHITE
	white_sb.border_width_left = 4
	white_sb.border_width_top = 4
	white_sb.border_width_right = 4
	white_sb.border_width_bottom = 4
	white_sb.border_color = Color.BLACK
	white_sb.corner_radius_top_left = 32
	white_sb.corner_radius_top_right = 32
	white_sb.corner_radius_bottom_left = 32
	white_sb.corner_radius_bottom_right = 32
	white_sb.shadow_color = Color(0, 0, 0, 0.5)
	white_sb.shadow_size = 0
	white_sb.shadow_offset = Vector2(0, 6)
	
	var white_sb_hover = white_sb.duplicate()
	white_sb_hover.bg_color = Color(0.9, 0.9, 0.9)
	white_sb_hover.shadow_offset = Vector2(0, 8)
	
	var white_sb_pressed = white_sb.duplicate()
	white_sb_pressed.bg_color = Color(0.8, 0.8, 0.8)
	white_sb_pressed.shadow_offset = Vector2(0, 2)

	for variant_id in skin_variants:
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(200, 200)
		button.pivot_offset = Vector2(100, 100)
		button.set_meta("variant_id", variant_id)
		
		button.add_theme_stylebox_override("normal", white_sb)
		button.add_theme_stylebox_override("hover", white_sb_hover)
		button.add_theme_stylebox_override("pressed", white_sb_pressed)
		
		var tex_path = "res://assets/player/improved/s.png"
		if variant_id == 1: tex_path = "res://assets/player/improved/s_b.png"
		elif variant_id == 2: tex_path = "res://assets/player/improved/s_p.png"
		elif variant_id == 3: tex_path = "res://assets/player/improved/s_y.png"
		var tex = load(tex_path)
		var tex_rect = TextureRect.new()
		if tex:
			var logo_tex = AtlasTexture.new()
			logo_tex.atlas = tex
			logo_tex.region = Rect2(0, 0, 214, 239)
			tex_rect.texture = logo_tex
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.set_anchors_preset(PRESET_FULL_RECT)
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(tex_rect)
				
		var tick: Label = Label.new()
		tick.text = "✔"
		tick.name = "TickLabel"
		tick.set_anchors_preset(PRESET_FULL_RECT)
		tick.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		tick.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		tick.add_theme_font_size_override("font_size", 40)
		tick.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
		tick.add_theme_color_override("font_outline_color", Color.BLACK)
		tick.add_theme_constant_override("outline_size", 4)
		tick.visible = (variant_id == current_skin)
		button.add_child(tick)
				
		button.pressed.connect(_on_skin_selected.bind(player_num, variant_id, container))
		button.mouse_entered.connect(func():
			var tween: Tween = create_tween()
			tween.tween_property(button, "scale", Vector2(1.15, 1.15), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		)
		button.mouse_exited.connect(func():
			var tween: Tween = create_tween()
			tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		)
		container.add_child(button)

func _on_skin_selected(player_num: int, variant_id: int, container: HBoxContainer = null) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm: gm.set_player_skin(player_num, Color.WHITE, variant_id)
	print("Player ", player_num, " selected skin ", variant_id)
	
	if container:
		for btn in container.get_children():
			if btn is Button:
				var tick = btn.get_node_or_null("TickLabel")
				if tick:
					tick.visible = (btn.get_meta("variant_id") == variant_id)

func _on_play_pressed() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.selected_arena != "":
		SceneTransition.change_scene(gm.selected_arena)
	else:
		SceneTransition.change_scene("res://Scenes/game.tscn")

func _on_back_pressed() -> void:
	SceneTransition.change_scene("res://Scenes/main_menu.tscn")
