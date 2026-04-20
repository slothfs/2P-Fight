extends Control

class_name MainMenu

@onready var vbox_container: VBoxContainer = $VBoxContainer
@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

@onready var arena_chooser: VBoxContainer = $ArenaChooser
@onready var arena1_button: Button = $ArenaChooser/Arena1Button
@onready var arena2_button: Button = $ArenaChooser/Arena2Button
@onready var back_button: Button = $ArenaChooser/BackButton

var vbox_center: Vector2
var arena_chooser_right: Vector2

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	arena1_button.pressed.connect(_on_arena1_pressed)
	arena2_button.pressed.connect(_on_arena2_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Store positions for animations
	vbox_center = vbox_container.position
	arena_chooser_right = arena_chooser.position

func _on_play_pressed() -> void:
	# Slide out main menu and slide in arena chooser
	var tween: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(vbox_container, "position:x", vbox_center.x - 1000.0, 0.5)
	tween.tween_property(arena_chooser, "position:x", vbox_center.x, 0.5)

func _on_back_pressed() -> void:
	# Revert animation
	var tween: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(vbox_container, "position:x", vbox_center.x, 0.5)
	tween.tween_property(arena_chooser, "position:x", arena_chooser_right.x, 0.5)

func _on_arena1_pressed() -> void:
	get_tree().paused = false
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm: gm.selected_arena = "res://Scenes/game.tscn"
	SceneTransition.change_scene("res://Scenes/skin_menu.tscn")

func _on_arena2_pressed() -> void:
	get_tree().paused = false
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm: gm.selected_arena = "res://Scenes/game2.tscn"
	SceneTransition.change_scene("res://Scenes/skin_menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
