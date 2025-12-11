extends ColorRect

var rotation_x: float = 0.0
var rotation_y: float = 0.0
var rotation_speed: float = 2.0
var original_scale: Vector2 = Vector2.ZERO
var thickness: float = 0.002

func _ready():
	original_scale = scale

func _process(delta):
	rotation_y += rotation_speed * delta
	rotation_x += rotation_speed * 0.5 * delta
	
	# Clamp to prevent excessive values
	rotation_x = fmod(rotation_x, TAU)
	rotation_y = fmod(rotation_y, TAU)
	
	# Apply 3D-like transformation
	_apply_3d_rotation_effect()
	
	# Draw thickness edges
	queue_redraw()

func _apply_3d_rotation_effect():
	# Scale based on rotation around X axis (perspective)
	var scale_y = cos(rotation_x)
	scale.y = original_scale.y * abs(scale_y)
	
	# Flip when rotated past 90 degrees
	if cos(rotation_y) < 0:
		scale.x = -original_scale.x
	else:
		scale.x = original_scale.x
	
	# Apply custom transform for skew effect
	var skew_amount = sin(rotation_y) * 0.5
	var transform_matrix = Transform2D()
	transform_matrix.x = Vector2(scale.x, 0)
	transform_matrix.y = Vector2(skew_amount * scale.y, scale.y)
	transform = transform_matrix
	
	# Adjust opacity based on angle for depth effect
	modulate.a = 0.5 + abs(cos(rotation_x)) * 0.5

func _draw():
	# Draw thickness edges to give 3D appearance
	var rect_size = size
	var edge_offset = thickness * 5000  # Scale up for visibility
	var edge_color = Color.BLACK
	edge_color.a = 0.3
	
	# Front edge shadow (bottom-right)
	draw_line(Vector2(0, rect_size.y), Vector2(edge_offset, rect_size.y - edge_offset), edge_color, 2.0)
	draw_line(Vector2(rect_size.x, 0), Vector2(rect_size.x - edge_offset, edge_offset), edge_color, 2.0)
	
	# Back edge highlight based on rotation
	if sin(rotation_y) > 0:
		draw_line(Vector2(0, 0), Vector2(edge_offset, edge_offset), Color.WHITE, 1.5)
