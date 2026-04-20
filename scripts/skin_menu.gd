extends Control

class_name SkinMenu

@onready var p1_skin_container: HBoxContainer = $VBoxContainer/Player1Skins
@onready var p2_skin_container: HBoxContainer = $VBoxContainer/Player2Skins
@onready var back_button: Button = $VBoxContainer/BackButton
@onready var play_button: Button = $VBoxContainer/PlayButton

var skin_variants: Array[int] = [0, 1, 2, 3] # 0 for normal, 1, 2, 3 for variants

func _ready() -> void:
	_create_skin_buttons(p1_skin_container, 1)
	_create_skin_buttons(p2_skin_container, 2)

	back_button.pressed.connect(_on_back_pressed)
	play_button.pressed.connect(_on_play_pressed)

func _create_skin_buttons(container: HBoxContainer, player_num: int) -> void:
	for variant_id in skin_variants:
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(50, 50)
		
		if variant_id == 0:
			button.text = "Normal"
		else:
			var logo_path = "res://assets/skins/%d/logo.png" % variant_id
			if ResourceLoader.exists(logo_path):
				var tex = load(logo_path)
				var tex_rect = TextureRect.new()
				tex_rect.texture = tex
				tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				tex_rect.set_anchors_preset(PRESET_FULL_RECT)
				button.add_child(tex_rect)
			else:
				button.text = "Skin %d" % variant_id
				
		button.pressed.connect(_on_skin_selected.bind(player_num, variant_id))
		container.add_child(button)

func _on_skin_selected(player_num: int, variant_id: int) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm: gm.set_player_skin(player_num, Color.WHITE, variant_id)
	print("Player ", player_num, " selected skin ", variant_id)

func _on_play_pressed() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.selected_arena != "":
		SceneTransition.change_scene(gm.selected_arena)
	else:
		SceneTransition.change_scene("res://Scenes/game.tscn")

func _on_back_pressed() -> void:
	SceneTransition.change_scene("res://Scenes/main_menu.tscn")
