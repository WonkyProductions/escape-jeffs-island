extends Node3D

@export var descent_speed: float = 10.0
@export var brightness_variation: float = 0.2  # How much lighter/darker (0.0 to 1.0)

var is_grounded: bool = false

func _ready():
	# Start at y = 10
	position.y = 10.0
	
	# Random Y rotation
	rotation.y = randf_range(0, TAU)
	
	# Apply random brightness variation to all mesh materials
	apply_brightness_variation()
	
	# Enable monitoring on the Area3D
	if has_node("tree_area"):
		$tree_area.monitoring = true

func apply_brightness_variation():
	# Random brightness multiplier (0.8 to 1.2 by default)
	var brightness = randf_range(1.0 - brightness_variation, 1.0 + brightness_variation)
	
	# Find all MeshInstance3D nodes in children
	for child in get_children():
		apply_brightness_to_node(child, brightness)

func apply_brightness_to_node(node: Node, brightness: float):
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		
		# Get the material and create a copy so each tree has unique material
		for i in range(mesh_instance.get_surface_override_material_count()):
			var mat = mesh_instance.get_surface_override_material(i)
			if mat:
				mat = mat.duplicate()
				
				# Adjust albedo color brightness
				if mat is StandardMaterial3D:
					var standard_mat = mat as StandardMaterial3D
					var color = standard_mat.albedo_color
					standard_mat.albedo_color = Color(
						color.r * brightness,
						color.g * brightness,
						color.b * brightness,
						color.a
					)
				
				mesh_instance.set_surface_override_material(i, mat)
	
	# Recursively check children
	for child in node.get_children():
		apply_brightness_to_node(child, brightness)

func _process(delta):
	# If not grounded yet, move down until collision
	if not is_grounded:
		position.y -= descent_speed * delta
		
		# Check for collisions with the tree_area
		if has_node("tree_area") and $tree_area is Area3D:
			var overlapping_bodies = $tree_area.get_overlapping_bodies()
			if overlapping_bodies.size() > 0:
				# Hit something, stop descending
				is_grounded = true
				print("Tree grounded at y = ", position.y)
