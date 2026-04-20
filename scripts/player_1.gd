extends CharacterBody2D

var speed = 200
var jump_force = -400
var gravity = 900
var attacking = false

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	var dir = Input.get_action_strength("p1_right") - Input.get_action_strength("p1_left")
	velocity.x = dir * speed

	if Input.is_action_just_pressed("p1_jump") and is_on_floor():
		velocity.y = jump_force

	if Input.is_action_just_pressed("p1_attack") and not attacking:
		attack()


	if dir != 0:
		$AnimatedSprite2D.flip_h = dir < 0

	update_anim(dir)

	move_and_slide()


func update_anim(dir):
	if attacking:
		return

	if not is_on_floor():
		$AnimatedSprite2D.play("jump")
	elif dir != 0:
		$AnimatedSprite2D.play("run")
	else:
		$AnimatedSprite2D.play("idle")


func attack():
	attacking = true
	$AnimatedSprite2D.play("hit")
	await get_tree().create_timer(0.3).timeout
	attacking = false
