extends Node2D

class_name GameController

const MUSIC_VOLUME_DB: float = -10.0

var background_music: AudioStreamPlayer
var _music_duck_tween: Tween = null
var pause_menu_scene: PackedScene = preload("res://Scenes/pause_menu.tscn")
var winner_menu_scene: PackedScene = preload("res://Scenes/winner_menu.tscn")

func _ready() -> void:
	_ensure_game_manager()
	
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
	
	var gm: GameManager = GameManager.instance
	if gm != null:
		gm.reset_game_state()
	_ensure_menu(pause_menu_scene, "PauseMenu")
	_ensure_menu(winner_menu_scene, "WinnerMenu")

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
