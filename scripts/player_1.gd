extends CharacterBody2D

class_name Player1

const BACK_AREA_OFFSET: float = 18.0

var speed: float = 600
var jump_force: float = -600
var gravity: float = 800
var attacking: bool = false
var attack_cooldown: float = 0.0
var opponent: CharacterBody2D = null

func die() -> void:
	print("player 1 died")
	var gm = get_node_or_null("/root/GameManager")
	if gm: gm.end_game(2)
	queue_free()

func _ready() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		if gm.player1_skin_id != 0:
			apply_skin(gm.player1_skin_id)
		elif gm.player1_skin_color != Color.WHITE:
			$AnimatedSprite2D.modulate = gm.player1_skin_color

	_sync_back_area_position($AnimatedSprite2D.flip_h)

func apply_skin(skin_id: int) -> void:
	var new_frames = $AnimatedSprite2D.sprite_frames.duplicate(true)
	
	# We need to deep duplicate the AtlasTextures as well
	for anim_name in new_frames.get_animation_names():
		for i in range(new_frames.get_frame_count(anim_name)):
			var old_tex = new_frames.get_frame_texture(anim_name, i)
			if old_tex is AtlasTexture:
				var new_tex = old_tex.duplicate(true)
				new_frames.set_frame(anim_name, i, new_tex, new_frames.get_frame_duration(anim_name, i))

	# Load skin textures
	var idle_tex = load("res://assets/skins/%d/idle.png" % skin_id)
	var jump_tex = load("res://assets/skins/%d/jump.png" % skin_id)
	var run_tex = load("res://assets/skins/%d/running.png" % skin_id)
	# Fallback or reuse for hitting if not available
	var hit_tex_path = "res://assets/skins/%d/hitting.png" % skin_id
	var hit_tex = null
	if ResourceLoader.exists(hit_tex_path):
		hit_tex = load(hit_tex_path)

	# Replace atlas textures
	_replace_anim_atlas(new_frames, "idle", idle_tex)
	_replace_anim_atlas(new_frames, "jump", jump_tex)
	_replace_anim_atlas(new_frames, "run", run_tex)
	if hit_tex:
		_replace_anim_atlas(new_frames, "hit", hit_tex)

	$AnimatedSprite2D.sprite_frames = new_frames

func _replace_anim_atlas(frames: SpriteFrames, anim_name: StringName, new_atlas: Texture2D) -> void:
	if not frames.has_animation(anim_name) or new_atlas == null: return
	for i in range(frames.get_frame_count(anim_name)):
		var tex = frames.get_frame_texture(anim_name, i)
		if tex is AtlasTexture:
			tex.atlas = new_atlas


func _physics_process(delta: float) -> void:
	if attack_cooldown > 0:
		attack_cooldown -= delta

	if not is_on_floor():
		velocity.y += gravity * delta

	var dir: float = Input.get_action_strength("p1_right") - Input.get_action_strength("p1_left")
	velocity.x = dir * speed

	if Input.is_action_just_pressed("p1_jump") and is_on_floor():
		velocity.y = jump_force

	if Input.is_action_just_pressed("p1_attack") and not attacking and attack_cooldown <= 0:
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

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.name == "backarea" and area.get_parent() != self:
		opponent = area.get_parent()
		print("Player 1: Detected opponent backarea")

func _on_hitbox_area_exited(area: Area2D) -> void:
	if area.name == "backarea" and area.get_parent() != self:
		if opponent == area.get_parent():
			opponent = null
		print("Player 1: Lost opponent backarea")
