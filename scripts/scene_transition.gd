extends CanvasLayer

var color_rect: ColorRect
var is_transitioning: bool = false

func _ready() -> void:
	layer = 100
	color_rect = ColorRect.new()
	color_rect.color = Color(0, 0, 0, 1)
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.modulate.a = 0
	color_rect.visible = false
	add_child(color_rect)

func change_scene(path: String) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	
	var tree = get_tree()
	var current = tree.current_scene
	var screen_size = get_viewport().get_visible_rect().size
	
	color_rect.visible = true
	color_rect.size = screen_size
	color_rect.position = Vector2(screen_size.x, 0)
	color_rect.modulate.a = 0.0
	
	var tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(color_rect, "position", Vector2.ZERO, 0.4)
	tween.tween_property(color_rect, "modulate:a", 1.0, 0.4)
	
	if current:
		if current is Control:
			current.pivot_offset = screen_size / 2.0
			tween.tween_property(current, "scale", Vector2(0.9, 0.9), 0.4)
			tween.tween_property(current, "position", Vector2(-screen_size.x * 0.1, current.position.y), 0.4)
		elif "scale" in current:
			tween.tween_property(current, "scale", Vector2(0.9, 0.9), 0.4)
			if "position" in current:
				tween.tween_property(current, "position", Vector2(-screen_size.x * 0.1, screen_size.y * 0.05), 0.4)
				
	await tween.finished
	
	tree.change_scene_to_file(path)
	await tree.process_frame
	await tree.process_frame
	
	var new_scene = tree.current_scene
	
	if new_scene:
		if new_scene is Control:
			new_scene.pivot_offset = screen_size / 2.0
			new_scene.scale = Vector2(1.1, 1.1)
			new_scene.position = Vector2(screen_size.x * 0.1, new_scene.position.y)
		elif "scale" in new_scene:
			new_scene.scale = Vector2(1.1, 1.1)
			if "position" in new_scene:
				new_scene.position = Vector2(screen_size.x * 0.1, -screen_size.y * 0.05)
				
	var tween2 = create_tween().set_parallel(true)
	tween2.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	tween2.tween_property(color_rect, "position", Vector2(-screen_size.x, 0), 0.4)
	tween2.tween_property(color_rect, "modulate:a", 0.0, 0.4)
	
	if new_scene:
		if new_scene is Control:
			tween2.tween_property(new_scene, "scale", Vector2.ONE, 0.4)
			tween2.tween_property(new_scene, "position", Vector2.ZERO, 0.4)
		elif "scale" in new_scene:
			tween2.tween_property(new_scene, "scale", Vector2.ONE, 0.4)
			if "position" in new_scene:
				tween2.tween_property(new_scene, "position", Vector2.ZERO, 0.4)
				
	await tween2.finished
	color_rect.visible = false
	is_transitioning = false
