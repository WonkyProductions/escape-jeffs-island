extends Area3D

@export var sway_speed: float = 2.0  # How fast the water sways
@export var sway_amount: float = 0.15  # How far the water sways (UV offset range)
@export var sway_direction_x: bool = true  # Sway in X direction
@export var sway_direction_y: bool = false  # Sway in Y direction

var time: float = 0.0
var mesh_instances: Array = []

func _ready():
	# Collect all MeshInstance3D children
	mesh_instances = [
		$MeshInstance3D,
		$MeshInstance3D2,
		$MeshInstance3D3,
		$MeshInstance3D4,
		$MeshInstance3D5
	]

func _process(delta):
	time += delta
	
	# Calculate sway using sine wave for smooth back-and-forth motion
	var sway_x = 0.0
	var sway_y = 0.0
	
	if sway_direction_x:
		sway_x = sin(time * sway_speed) * sway_amount
	
	if sway_direction_y:
		sway_y = sin(time * sway_speed * 0.7) * sway_amount  # Different frequency for Y
	
	# Apply sway to all mesh instances
	for mesh in mesh_instances:
		if mesh and mesh.material_override:
			mesh.material_override.uv1_offset = Vector3(sway_x, sway_y, 0.0)
