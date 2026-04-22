extends CharacterBody2D

class_name MultiplayerPlayer

var speed: float = 1500
var jump_force: float = -2000
var gravity: float = 4000
var attacking: bool = false
var attack_cooldown: float = 0.0
var opponent: CharacterBody2D = null

var dead: bool = false

var footstep_sfx: AudioStreamPlayer
var hit_sfx: AudioStreamPlayer
var loss_sfx: AudioStreamPlayer
var jump_sfx: AudioStreamPlayer

var owner_id = 1
var my_role = "P1"

var invis_duration: float = 0.0
var invis_cooldown: float = 0.0
var dash_duration: float = 0.0
var dash_cooldown: float = 0.0
var is_invisible: bool = false
var is_dashing: bool = false
var shadow_timer: float = 0.0

func _set_pass_through(enable: bool) -> void:
	if not is_inside_tree(): return
	for child in get_parent().get_children():
		if child is CharacterBody2D and child != self:
			if enable:
				add_collision_exception_with(child)
			else:
				remove_collision_exception_with(child)

func _create_dash_shadow() -> void:
	var shadow = AnimatedSprite2D.new()
	shadow.sprite_frames = $AnimatedSprite2D.sprite_frames
	shadow.animation = $AnimatedSprite2D.animation
	shadow.frame = $AnimatedSprite2D.frame
	shadow.global_position = $AnimatedSprite2D.global_position
	shadow.flip_h = $AnimatedSprite2D.flip_h
	shadow.scale = $AnimatedSprite2D.scale
	shadow.modulate = $AnimatedSprite2D.modulate
	shadow.modulate.a = 0.5
	get_parent().add_child(shadow)
	
	var tween = create_tween()
	tween.tween_property(shadow, "modulate:a", 0.0, 0.3)
	tween.tween_callback(shadow.queue_free)

func _setup_authority():
	set_multiplayer_authority(owner_id)
	$PlayerIndicator.text = my_role + "\n▼"

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

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	
	footstep_sfx = AudioStreamPlayer.new()
	footstep_sfx.stream = preload("res://assets/Sfx/footstep.mp3")
	footstep_sfx.bus = "SFX"
	add_child(footstep_sfx)
	
	hit_sfx = AudioStreamPlayer.new()
	hit_sfx.stream = preload("res://assets/Sfx/hitting_fixed.wav")
	hit_sfx.volume_db = -2.0
	hit_sfx.bus = "SFX"
	add_child(hit_sfx)
	
	loss_sfx = AudioStreamPlayer.new()
	loss_sfx.stream = preload("res://assets/Sfx/lossing_fixed.wav")
	loss_sfx.volume_db = -1.5
	loss_sfx.bus = "SFX"
	add_child(loss_sfx)
	
	jump_sfx = AudioStreamPlayer.new()
	jump_sfx.stream = preload("res://assets/Sfx/new jump.mp3")
	jump_sfx.volume_db = -1.5
	jump_sfx.bus = "SFX"
	add_child(jump_sfx)

	_sync_back_area_position($AnimatedSprite2D.flip_h)

func _physics_process(delta: float) -> void:
	if dead: return
	
	if attack_cooldown > 0:
		attack_cooldown -= delta
	if invis_cooldown > 0:
		invis_cooldown -= delta
	if dash_cooldown > 0:
		dash_cooldown -= delta

	if invis_duration > 0:
		invis_duration -= delta
		if invis_duration <= 0:
			is_invisible = false
			$AnimatedSprite2D.modulate.a = 1.0
			if has_node("PlayerIndicator"): get_node("PlayerIndicator").visible = true
			if not is_dashing: _set_pass_through(false)

	if is_dashing:
		shadow_timer -= delta
		if shadow_timer <= 0:
			shadow_timer = 0.05
			_create_dash_shadow()

	if dash_duration > 0:
		dash_duration -= delta
		if dash_duration <= 0:
			is_dashing = false
			var back = get_node_or_null("backarea")
			if back: back.set_deferred("monitoring", true)
			var hitbox = get_node_or_null("Hitbox")
			if hitbox: hitbox.set_deferred("monitoring", true)
			if not is_invisible: _set_pass_through(false)

	if not is_on_floor():
		velocity.y += gravity * delta

	var dir: float = 0.0
	if is_multiplayer_authority():
		dir = Input.get_action_strength("p1_right") - Input.get_action_strength("p1_left")
		
		if Input.is_action_just_pressed("p1_invisible") and invis_cooldown <= 0:
			rpc("trigger_invisible")
			
		if Input.is_action_just_pressed("p1_dash") and dash_cooldown <= 0:
			rpc("trigger_dash")

		if Input.is_action_just_pressed("p1_jump") and is_on_floor():
			velocity.y = jump_force
			jump_sfx.stop()
			jump_sfx.play()
		if Input.is_action_just_pressed("p1_attack") and not attacking and attack_cooldown <= 0:
			attack()
				
		var current_speed = speed * 4.0 if is_dashing else speed
		if is_dashing and dir == 0:
			velocity.x = -current_speed if $AnimatedSprite2D.flip_h else current_speed
		else:
			velocity.x = dir * current_speed
		
		rpc("sync_movement", position, velocity, attacking, $AnimatedSprite2D.flip_h)
	
	if abs(velocity.x) > 10.0 and not is_dashing:
		var facing_left: bool = velocity.x < 0
		if $AnimatedSprite2D.flip_h != facing_left:
			$AnimatedSprite2D.flip_h = facing_left
			_sync_back_area_position(facing_left)

	move_and_slide()
	update_anim(dir)

@rpc("any_peer", "call_local", "reliable")
func trigger_invisible():
	invis_cooldown = 10.0
	invis_duration = 1.0
	is_invisible = true
	$AnimatedSprite2D.modulate.a = 0.2
	if has_node("PlayerIndicator"): get_node("PlayerIndicator").visible = false
	_set_pass_through(true)

@rpc("any_peer", "call_local", "reliable")
func trigger_dash():
	dash_cooldown = 5.0
	dash_duration = 0.2
	is_dashing = true
	var back = get_node_or_null("backarea")
	if back: back.set_deferred("monitoring", false)
	var hitbox = get_node_or_null("Hitbox")
	if hitbox: hitbox.set_deferred("monitoring", false)
	if jump_sfx:
		jump_sfx.stop()
		jump_sfx.play()
	_set_pass_through(true)

@rpc("any_peer", "unreliable", "call_local")
func sync_movement(pos: Vector2, vel: Vector2, is_attacking: bool, flip: bool):
	if not is_multiplayer_authority():
		position = pos
		velocity = vel
		attacking = is_attacking
		$AnimatedSprite2D.flip_h = flip
		_sync_back_area_position(flip)

func update_anim(_dir: float) -> void:
	if dead or attacking: return

	if abs(velocity.x) > 0.1:
		_play_animation("run")
		if is_on_floor():
			if not footstep_sfx.playing: footstep_sfx.play()
		else:
			footstep_sfx.stop()
	elif not is_on_floor():
		_play_animation("jump")
		footstep_sfx.stop()
	else:
		_play_animation("idle")
		footstep_sfx.stop()

func _play_animation(anim_name: String) -> void:
	var sprite: AnimatedSprite2D = $AnimatedSprite2D
	if sprite.animation != anim_name or not sprite.is_playing():
		sprite.play(anim_name)

func attack() -> void:
	attacking = true
	attack_cooldown = 1.0
	$AnimatedSprite2D.play("hit")
	hit_sfx.stop()
	hit_sfx.play()

	if opponent != null and is_instance_valid(opponent):
		var opponent_backarea: Area2D = opponent.get_node_or_null("backarea")
		var hitbox_area: Area2D = get_node_or_null("Hitbox")
		if hitbox_area and opponent_backarea:
			var overlapping_areas: Array = hitbox_area.get_overlapping_areas()
			if opponent_backarea in overlapping_areas:
				if is_multiplayer_authority():
					opponent.rpc("die")

	await get_tree().create_timer(0.6).timeout
	attacking = false

@rpc("any_peer", "call_local", "reliable")
func die() -> void:
	if dead: return
	dead = true
	loss_sfx.play()
	footstep_sfx.stop()
	velocity = Vector2.ZERO
	$AnimatedSprite2D.play("hurt")
	
	await get_tree().create_timer(1.0).timeout
	var gm = get_node_or_null("/root/GameManager")
	if gm != null:
		var winner = 2 if my_role == "P1" else 1
		gm.end_game(winner)

func _sync_back_area_position(facing_left: bool) -> void:
	if not has_node("backarea") or not has_node("Hitbox"): return
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

func _on_hitbox_area_exited(area: Area2D) -> void:
	if area.name == "backarea" and area.get_parent() != self:
		if opponent == area.get_parent():
			opponent = null
