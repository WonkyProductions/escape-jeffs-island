extends MeshInstance3D

@export var sway_speed: float = 2.0
@export var sway_amount: float = 0.15
@export var sway_direction_x: bool = true
@export var sway_direction_y: bool = false

var time: float = 0.0
var start_uv_offset: Vector3 = Vector3.ZERO

func _ready():
	if material_override:
		start_uv_offset = material_override.uv1_offset

func _process(delta):
	time += delta
	
	if not material_override:
		return
	
	var sway_x = 0.0
	var sway_y = 0.0
	
	if sway_direction_x:
		sway_x = sin(time * sway_speed) * sway_amount
	
	if sway_direction_y:
		sway_y = sin(time * sway_speed * 0.7) * sway_amount
	
	material_override.uv1_offset = start_uv_offset + Vector3(sway_x, sway_y, 0.0)
