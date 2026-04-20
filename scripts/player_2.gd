extends CharacterBody2D

class_name Player2

const BACK_AREA_OFFSET: float = 18.0

var speed: float = 600
var jump_force: float = -600
var gravity: float = 800
var attacking: bool = false
var attack_cooldown: float = 0.0
var opponent: CharacterBody2D = null
var game_manager: GameManager

func die() -> void:
	print("player 2 died")
	if game_manager:
		game_manager.end_game(1)
	queue_free()

func _ready() -> void:
	_ensure_game_manager()
	if game_manager and game_manager.player2_skin_color != Color.WHITE:
		$AnimatedSprite2D.modulate = game_manager.player2_skin_color

	_sync_back_area_position($AnimatedSprite2D.flip_h)


func _physics_process(delta: float) -> void:
	if attack_cooldown > 0:
		attack_cooldown -= delta

	if not is_on_floor():
		velocity.y += gravity * delta

	var dir: float = Input.get_action_strength("p2_right") - Input.get_action_strength("p2_left")
	velocity.x = dir * speed

	if Input.is_action_just_pressed("p2_jump") and is_on_floor():
		velocity.y = jump_force

	if Input.is_action_just_pressed("p2_attack") and not attacking and attack_cooldown <= 0:
		attack()

	if dir != 0:
		var facing_left: bool = dir < 0
		$AnimatedSprite2D.flip_h = facing_left
		_sync_back_area_position(facing_left)

	update_anim(dir)

	move_and_slide()

func update_anim(dir: float) -> void:
	if attacking:
		return

	if not is_on_floor():
		$AnimatedSprite2D.play("jump")
	elif dir != 0:
		$AnimatedSprite2D.play("run")
	else:
		$AnimatedSprite2D.play("idle")

func attack() -> void:
	attacking = true
	attack_cooldown = 2.0
	$AnimatedSprite2D.play("hit")

	if opponent != null and is_instance_valid(opponent):
		var opponent_backarea: Area2D = opponent.get_node("backarea")
		var hitbox_area: Area2D = $Hitbox
		
		await get_tree().process_frame
		var overlapping_areas: Array = hitbox_area.get_overlapping_areas()
		if opponent_backarea in overlapping_areas:
			opponent.die()
			attacking = false
			return

	await get_tree().create_timer(0.3).timeout
	attacking = false

func _sync_back_area_position(facing_left: bool) -> void:
	$backarea.position.x = 0
	if facing_left:
		$backarea/CollisionShape2D.position.x = 18
		$Hitbox/CollisionShape2D.position.x = -15
	else:
		$backarea/CollisionShape2D.position.x = -18
		$Hitbox/CollisionShape2D.position.x = 15

func _ensure_game_manager() -> void:
	if GameManager.instance == null:
		var gm: GameManager = GameManager.new()
		get_tree().root.add_child(gm)
	elif not GameManager.instance.is_inside_tree():
		get_tree().root.add_child(GameManager.instance)

	game_manager = GameManager.instance

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.name == "backarea" and area.get_parent() != self:
		opponent = area.get_parent()
		print("Player 2: Detected opponent backarea")

func _on_hitbox_area_exited(area: Area2D) -> void:
	if area.name == "backarea" and area.get_parent() != self:
		if opponent == area.get_parent():
			opponent = null
		print("Player 2: Lost opponent backarea")

			
