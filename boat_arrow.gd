extends Sprite2D

var target_pos_3d = Vector3(-65.094, 0, 203.898)
var bar_width = 300.0
var bar_height = 40.0
var tolerance = 0.15
var is_in_zone = false
var normalized_pos = 0.5

func _ready():
	pass

func _process(delta):
	var camera = get_viewport().get_camera_3d()
	if camera == null:
		return
	
	var target_screen_pos = camera.unproject_position(target_pos_3d)
	var bar_center = global_position
	
	var horizontal_offset = target_screen_pos.x - bar_center.x
	
	# Check if target is behind the camera (facing opposite way)
	var camera_forward = -camera.global_transform.basis.z
	var direction_to_target = (target_pos_3d - camera.global_position).normalized()
	var is_behind = camera_forward.dot(direction_to_target) < 0
	
	normalized_pos = clamp(horizontal_offset / bar_width + 0.5, 0.0, 1.0)
	
	is_in_zone = abs(normalized_pos - 0.5) < tolerance and not is_behind
	
	queue_redraw()

func _draw():
	if Global.files != 0:
		return
	
	# Draw background bar
	var bar_rect = Rect2(-bar_width / 2, -bar_height / 2, bar_width, bar_height)
	draw_rect(bar_rect, Color.DARK_GRAY)
	draw_rect(bar_rect, Color.GRAY, false, 2.0)
	
	# Check if facing opposite way for center dot color
	var camera = get_viewport().get_camera_3d()
	var center_dot_color = Color.RED
	if camera:
		var camera_forward = -camera.global_transform.basis.z
		var direction_to_target = (target_pos_3d - camera.global_position).normalized()
		if camera_forward.dot(direction_to_target) >= 0:
			center_dot_color = Color.GREEN
	
	# Draw center zone (green)
	var zone_width = bar_width * tolerance
	var zone_rect = Rect2(-zone_width / 2, -bar_height / 2, zone_width, bar_height)
	draw_rect(zone_rect, Color.GREEN, true, 0.0)
	
	# Draw center dot
	draw_circle(Vector2(0, 0), 8, center_dot_color)
	
	# Draw indicator
	var indicator_x = (normalized_pos - 0.5) * bar_width
	var indicator_color = Color.GREEN if is_in_zone else Color.RED
	var indicator_rect = Rect2(indicator_x - 15, -bar_height / 2, 30, bar_height)
	draw_rect(indicator_rect, indicator_color)
