extends CharacterBody2D

class_name Player2

const BACK_AREA_OFFSET: float = 18.0

var speed: float = 1500
var jump_force: float = -1000
var gravity: float = 800
var attacking: bool = false
var attack_cooldown: float = 0.0
var opponent: CharacterBody2D = null

var dead: bool = false

func die() -> void:
	if dead: return
	dead = true
	print("player 2 died")
	velocity = Vector2.ZERO
	$AnimatedSprite2D.play("hurt")
	set_physics_process(false)
	await get_tree().create_timer(1.0).timeout
	var gm = get_node_or_null("/root/GameManager")
	if gm: gm.end_game(1)
	queue_free()

func _ready() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		if gm.player2_skin_id != 0:
			apply_skin(gm.player2_skin_id)
		elif gm.player2_skin_color != Color.WHITE:
			$AnimatedSprite2D.modulate = gm.player2_skin_color

	_sync_back_area_position($AnimatedSprite2D.flip_h)

func apply_skin(skin_id: int) -> void:
	var tex_path = "res://assets/player/improved/s.png"
	if skin_id == 1: tex_path = "res://assets/player/improved/s_b.png"
	elif skin_id == 2: tex_path = "res://assets/player/improved/s_p.png"
	elif skin_id == 3: tex_path = "res://assets/player/improved/s_y.png"
	
	var tex = load(tex_path)
	if not tex: return
	
	var new_frames = $AnimatedSprite2D.sprite_frames.duplicate(true)
	for anim_name in new_frames.get_animation_names():
		for i in range(new_frames.get_frame_count(anim_name)):
			var old_tex = new_frames.get_frame_texture(anim_name, i)
			if old_tex is AtlasTexture:
				var new_tex = old_tex.duplicate(true)
				new_tex.atlas = tex
				new_frames.set_frame(anim_name, i, new_tex, new_frames.get_frame_duration(anim_name, i))
	
	$AnimatedSprite2D.sprite_frames = new_frames


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

	move_and_slide()
	update_anim(dir)

func update_anim(dir: float) -> void:
	if dead:
		return
	if attacking:
		return

	if not is_on_floor():
		$AnimatedSprite2D.play("jump")
	elif abs(velocity.x) > 0.1:
		$AnimatedSprite2D.play("run")
	else:
		$AnimatedSprite2D.play("idle")

func attack() -> void:
	attacking = true
	attack_cooldown = 1.0
	$AnimatedSprite2D.play("hit")

	if opponent != null and is_instance_valid(opponent):
		var opponent_backarea: Area2D = opponent.get_node("backarea")
		var hitbox_area: Area2D = $Hitbox
		
		await get_tree().process_frame
		var overlapping_areas: Array = hitbox_area.get_overlapping_areas()
		if opponent_backarea in overlapping_areas:
			opponent.die()

	await get_tree().create_timer(0.6).timeout
	attacking = false

func _sync_back_area_position(facing_left: bool) -> void:
	$backarea.position.x = 0
	if facing_left:
		$backarea/CollisionShape2D.position.x = 18
		$Hitbox/CollisionShape2D.position.x = -15
	else:
		$backarea/CollisionShape2D.position.x = -18
		$Hitbox/CollisionShape2D.position.x = 15

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.name == "backarea" and area.get_parent() != self:
		opponent = area.get_parent()
		print("Player 2: Detected opponent backarea")

func _on_hitbox_area_exited(area: Area2D) -> void:
	if area.name == "backarea" and area.get_parent() != self:
		if opponent == area.get_parent():
			opponent = null
		print("Player 2: Lost opponent backarea")

			
