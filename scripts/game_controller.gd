extends Node2D

class_name GameController

const MUSIC_VOLUME_DB: float = -10.0
const LAVA_SCRIPT: Script = preload("res://scripts/lava.gd")


var background_music: AudioStreamPlayer
var _music_duck_tween: Tween = null
var pause_menu_scene: PackedScene = preload("res://Scenes/pause_menu.tscn")
var winner_menu_scene: PackedScene = preload("res://Scenes/winner_menu.tscn")

var player1: CharacterBody2D
var player2: CharacterBody2D
var survival_time: float = 0.0
var time_label: Label
var red_overlay: ColorRect
var cam: Camera2D
var game_over: bool = false

func _ready() -> void:
	_ensure_game_manager()
	call_deferred("_ensure_lava_area")
	call_deferred("_setup_abilities_ui")
	
	var gm: GameManager = GameManager.instance
	var use_multiplayer_players: bool = false
	if gm != null and gm.is_multiplayer_session and multiplayer.multiplayer_peer and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		use_multiplayer_players = true
	
	if use_multiplayer_players:
		call_deferred("_setup_multiplayer_players")
	else:
		player1 = get_parent().get_node_or_null("Player1")
		player2 = get_parent().get_node_or_null("Player2")
	
	cam = get_parent().get_node_or_null("Camera2D")
	
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	
	red_overlay = ColorRect.new()
	red_overlay.color = Color(1, 0, 0, 0)
	red_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	red_overlay.position = Vector2.ZERO
	red_overlay.size = get_viewport_rect().size
	red_overlay.visible = false
	canvas.add_child(red_overlay)
	
	time_label = Label.new()
	time_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", 48)
	time_label.add_theme_color_override("font_outline_color", Color(0,0,0,1))
	time_label.add_theme_constant_override("outline_size", 8)
	time_label.text = "00:00"
	canvas.add_child(time_label)

	background_music = AudioStreamPlayer.new()
	if get_tree().current_scene and get_tree().current_scene.scene_file_path == "res://Scenes/game.tscn":
		background_music.stream = preload("res://assets/Sfx/bgmusic1.mp3")
	else:
		background_music.stream = preload("res://assets/Sfx/bgmusic2.mp3")
	background_music.volume_db = MUSIC_VOLUME_DB
	background_music.bus = "Music"
	add_child(background_music)
	background_music.play()
	background_music.finished.connect(background_music.play)
	
	if gm != null:
		gm.reset_game_state()
	_ensure_menu(pause_menu_scene, "PauseMenu")
	_ensure_menu(winner_menu_scene, "WinnerMenu")

func _setup_multiplayer_players() -> void:
	var parent = get_parent()
	var p1 = parent.get_node_or_null("Player1")
	var p2 = parent.get_node_or_null("Player2")
	
	var mp_p1_scene = preload("res://Scenes/multiplayer_player_1.tscn")
	var mp_p2_scene = preload("res://Scenes/multiplayer_player_2.tscn")
	
	var mm = get_tree().root.get_node_or_null("MultiplayerManager")
	var gm = GameManager.instance
	
	var new_p1 = null
	var new_p2 = null
	
	if p1 and mp_p1_scene:
		p1.name = "OldPlayer1"
		new_p1 = mp_p1_scene.instantiate()
		new_p1.name = "Player1"
		new_p1.global_position = p1.global_position
		new_p1.scale = p1.scale
		parent.add_child(new_p1)
		p1.queue_free()
		
		if mm:
			new_p1.owner_id = _get_peer_for_role("P1", mm)
			new_p1.my_role = "P1"
			new_p1._setup_authority()
		if gm and gm.player1_skin_id != 0:
			new_p1.apply_skin(gm.player1_skin_id)
			
	if p2 and mp_p2_scene:
		p2.name = "OldPlayer2"
		new_p2 = mp_p2_scene.instantiate()
		new_p2.name = "Player2"
		new_p2.global_position = p2.global_position
		new_p2.scale = p2.scale
		parent.add_child(new_p2)
		p2.queue_free()
		
		if mm:
			new_p2.owner_id = _get_peer_for_role("P2", mm)
			new_p2.my_role = "P2"
			new_p2._setup_authority()
		if gm and gm.player2_skin_id != 0:
			new_p2.apply_skin(gm.player2_skin_id)
			
	self.player1 = new_p1
	self.player2 = new_p2
	
	if cam:
		cam.player1 = new_p1
		cam.player2 = new_p2

func _get_peer_for_role(role: String, mm) -> int:
	if not mm.player_roles: return 1
	for peer_id in mm.player_roles.keys():
		if mm.player_roles[peer_id] == role:
			return peer_id
	return 1

func duck_music(amount_db: float = 3.5, total_duration: float = 0.3) -> void:
	if background_music == null:
		return
	if _music_duck_tween != null:
		_music_duck_tween.kill()
	var half_duration: float = max(total_duration * 0.5, 0.05)
	_music_duck_tween = create_tween()
	_music_duck_tween.tween_property(background_music, "volume_db", MUSIC_VOLUME_DB - amount_db, half_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_music_duck_tween.tween_property(background_music, "volume_db", MUSIC_VOLUME_DB, half_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _ensure_game_manager() -> void:
	if GameManager.instance == null:
		var gm: GameManager = GameManager.new()
		get_tree().root.add_child(gm)
		return
	
	if not GameManager.instance.is_inside_tree():
		get_tree().root.add_child(GameManager.instance)

func _ensure_menu(packed_scene: PackedScene, node_name: String) -> void:
	if has_node(node_name):
		return
	var menu: Node = packed_scene.instantiate()
	add_child(menu)

func _ensure_lava_area() -> void:
	var parent: Node = get_parent()
	if parent == null:
		return

	var lava_node: Node = parent.get_node_or_null("lava")
	if lava_node == null:
		return

	if lava_node is Area2D:
		_apply_lava_script(lava_node as Area2D)
		return

	var shape_node: CollisionShape2D = lava_node as CollisionShape2D
	if shape_node == null:
		return

	_replace_lava_shape(parent, shape_node)

func _apply_lava_script(area: Area2D) -> void:
	if area.get_script() == LAVA_SCRIPT:
		return
	area.set_script(LAVA_SCRIPT)

func _replace_lava_shape(parent: Node, shape_node: CollisionShape2D) -> void:
	var shape_resource: Shape2D = shape_node.shape
	if shape_resource == null:
		return

	var position: Vector2 = shape_node.position
	var index: int = shape_node.get_index()
	var owner_ref: Node = shape_node.owner
	var valid_owner: Node = parent
	if owner_ref != null and owner_ref.is_inside_tree() and (owner_ref == parent or owner_ref.is_ancestor_of(parent)):
		valid_owner = owner_ref

	shape_node.queue_free()

	var area: Area2D = Area2D.new()
	area.name = "lava"
	area.position = position
	area.owner = valid_owner
	area.set_script(LAVA_SCRIPT)

	var collision_shape: CollisionShape2D = CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	collision_shape.position = Vector2.ZERO
	collision_shape.shape = shape_resource
	collision_shape.owner = valid_owner
	area.add_child(collision_shape)

	parent.add_child(area)
	parent.move_child(area, index)

func _process(delta: float) -> void:
	if not is_instance_valid(player1) or not is_instance_valid(player2):
		return

	if not game_over and (player1.dead or player2.dead):
		game_over = true
		if time_label:
			time_label.hide()
		if red_overlay:
			red_overlay.hide()
		if cam:
			cam.offset = Vector2.ZERO
		return

	if game_over:
		return

	survival_time += delta
	var mins = int(survival_time) / 60
	var secs = int(survival_time) % 60
	if time_label:
		time_label.text = "%02d:%02d" % [mins, secs]

	var speed_multiplier = 1.0 + (survival_time * 0.02)
	player1.speed = 1500 * speed_multiplier
	player2.speed = 1500 * speed_multiplier

	var dist = player1.global_position.distance_to(player2.global_position)
	_update_proximity_effect(dist)
	_update_abilities_ui()

var p1_invis_label: Label
var p1_dash_label: Label
var p2_invis_label: Label
var p2_dash_label: Label
var p1_invis_rect: TextureRect
var p1_dash_rect: TextureRect
var p2_invis_rect: TextureRect
var p2_dash_rect: TextureRect

func _create_ability_row(title: String, logo_tex: Texture2D) -> Array:
	var hbox = HBoxContainer.new()
	var icon = TextureRect.new()
	icon.texture = logo_tex
	icon.custom_minimum_size = Vector2(40, 40)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(icon)
	
	var lbl = Label.new()
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 8)
	lbl.text = title
	hbox.add_child(lbl)
	return [hbox, icon, lbl]
	
func _setup_abilities_ui() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 90
	add_child(canvas)
	
	var default_logo = load("res://assets/Object/Crystal.png")
	if not default_logo:
		default_logo = PlaceholderTexture2D.new()
		default_logo.size = Vector2(32, 32)
		
	var p1_container = VBoxContainer.new()
	p1_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	p1_container.position = Vector2(20, 20)
	canvas.add_child(p1_container)
	
	var p1_inv = _create_ability_row("P1 Invis (E): Ready", default_logo)
	p1_container.add_child(p1_inv[0])
	p1_invis_rect = p1_inv[1]
	p1_invis_label = p1_inv[2]
	
	var p1_dsh = _create_ability_row("P1 Dash (Q): Ready", default_logo)
	p1_container.add_child(p1_dsh[0])
	p1_dash_rect = p1_dsh[1]
	p1_dash_label = p1_dsh[2]
	
	var p2_container = VBoxContainer.new()
	p2_container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	p2_container.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	p2_container.position = Vector2(get_viewport_rect().size.x - 300, 20)
	canvas.add_child(p2_container)
	
	var p2_inv = _create_ability_row("P2 Invis (O): Ready", default_logo)
	p2_container.add_child(p2_inv[0])
	p2_invis_rect = p2_inv[1]
	p2_invis_label = p2_inv[2]
	
	var p2_dsh = _create_ability_row("P2 Dash (U): Ready", default_logo)
	p2_container.add_child(p2_dsh[0])
	p2_dash_rect = p2_dsh[1]
	p2_dash_label = p2_dsh[2]

func _update_abilities_ui() -> void:
	if is_instance_valid(player1) and p1_invis_label and p1_dash_label:
		var i_cd = player1.get("invis_cooldown")
		var d_cd = player1.get("dash_cooldown")
		p1_invis_label.text = "Invis (E): " + (str(ceil(i_cd)) + "s" if i_cd != null and i_cd > 0 else "Ready")
		if i_cd != null and i_cd > 0:
			p1_invis_rect.modulate = Color(0.5, 0.5, 0.5, 0.5)
		else:
			p1_invis_rect.modulate = Color.WHITE
			
		p1_dash_label.text = "Dash (Q): " + (str(ceil(d_cd)) + "s" if d_cd != null and d_cd > 0 else "Ready")
		if d_cd != null and d_cd > 0:
			p1_dash_rect.modulate = Color(0.5, 0.5, 0.5, 0.5)
		else:
			p1_dash_rect.modulate = Color.WHITE
		
	if is_instance_valid(player2) and p2_invis_label and p2_dash_label:
		var i_cd = player2.get("invis_cooldown")
		var d_cd = player2.get("dash_cooldown")
		p2_invis_label.text = "Invis (O): " + (str(ceil(i_cd)) + "s" if i_cd != null and i_cd > 0 else "Ready")
		if i_cd != null and i_cd > 0:
			p2_invis_rect.modulate = Color(0.5, 0.5, 0.5, 0.5)
		else:
			p2_invis_rect.modulate = Color.WHITE
			
		p2_dash_label.text = "Dash (U): " + (str(ceil(d_cd)) + "s" if d_cd != null and d_cd > 0 else "Ready")
		if d_cd != null and d_cd > 0:
			p2_dash_rect.modulate = Color(0.5, 0.5, 0.5, 0.5)
		else:
			p2_dash_rect.modulate = Color.WHITE

func _update_proximity_effect(distance: float) -> void:
	var view_size = get_viewport_rect().size
	if red_overlay.size != view_size:
		red_overlay.size = view_size
	red_overlay.position = Vector2.ZERO

	var trigger_distance = 900.0
	if distance < trigger_distance:
		var intensity = clamp(1.0 - (distance / trigger_distance), 0.0, 1.0)
		var blink_speed = 6.0 + intensity * 14.0
		var blink_alpha = sin(survival_time * blink_speed) * 0.5 + 0.5
		var alpha = intensity * 0.6 * blink_alpha
		red_overlay.visible = alpha > 0.01
		red_overlay.color = Color(1, 0, 0, alpha)
		if cam:
			cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * intensity * 40.0
	else:
		red_overlay.visible = false
		red_overlay.color = Color(1, 0, 0, 0)
		if cam:
			cam.offset = Vector2.ZERO
