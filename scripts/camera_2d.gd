extends Camera2D

@export var player1: Node2D
@export var player2: Node2D

@export var smooth_speed := 5.0

func _process(delta):
	if !player1 or !player2:
		return
	
	var center = (player1.global_position + player2.global_position) / 2
	global_position = global_position.lerp(center, smooth_speed * delta)
