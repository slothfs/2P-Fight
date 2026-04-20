extends Node

signal game_paused(paused: bool)
signal game_over(winner: int)

var is_paused: bool = false
var player1_skin_color: Color = Color.WHITE
var player2_skin_color: Color = Color.WHITE
var player1_skin_id: int = 0
var player2_skin_id: int = 0
var selected_arena: String = "res://Scenes/game.tscn"
var has_game_ended: bool = false
var last_winner: int = 0

static var instance: Node

func _enter_tree() -> void:
	if instance == null:
		instance = self
	elif instance != self:
		queue_free()
		return

func _ready() -> void:
	if instance != self:
		return
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	if get_parent() != get_tree().root:
		get_tree().root.add_child(self)

func pause_game() -> void:
	if is_paused:
		return

	is_paused = true
	get_tree().paused = true
	game_paused.emit(true)

func resume_game() -> void:
	if not is_paused:
		return

	is_paused = false
	get_tree().paused = false
	game_paused.emit(false)

func reset_game_state() -> void:
	has_game_ended = false
	last_winner = 0
	is_paused = false
	if get_tree().paused:
		get_tree().paused = false

func set_player_skin(player_num: int, color: Color, skin_id: int = 0) -> void:
	if player_num == 1:
		player1_skin_color = color
		player1_skin_id = skin_id
	elif player_num == 2:
		player2_skin_color = color
		player2_skin_id = skin_id

func end_game(winner: int) -> void:
	if has_game_ended:
		return

	has_game_ended = true
	last_winner = winner
	game_over.emit(winner)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed and not event.echo:
		if is_paused:
			resume_game()
		else:
			pause_game()
