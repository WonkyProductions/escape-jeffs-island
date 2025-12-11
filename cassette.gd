extends Area3D

@export var rotation_speed: float = 1.0
@export var bob_amount: float = 0.2
@export var bob_speed: float = 2.0
@export var snap_up_offset: float = 0.5  # Exported value for how much to snap up
@export var descent_speed: float = 10.0

var initial_position: Vector3
var time: float = 0.0
var current_height: float = 0.0
var is_grounded: bool = false
var ground_height: float = 0.0

func _ready():
	initial_position = position
	current_height = position.y
	# Enable monitoring to detect overlaps
	monitoring = true
	

func _process(delta):
	time += delta
	
	# Rotate continuously in all directions
	rotation.x += rotation_speed * delta
	rotation.y += rotation_speed * delta * 0.7
	rotation.z += rotation_speed * delta * 0.5
	
	# If not grounded yet, descend until hitting something
	if not is_grounded:
		current_height -= descent_speed * delta
		position.y = current_height
		
		# Check for collisions with overlapping bodies
		var overlapping_bodies = get_overlapping_bodies()
		if overlapping_bodies.size() > 0:
			# Found ground, snap up by the exported offset
			ground_height = current_height + snap_up_offset
			is_grounded = true
	else:
		# Once grounded, bob up and down slightly while rotating
		var bob_offset = sin(time * bob_speed) * bob_amount
		position = Vector3(initial_position.x, ground_height + bob_offset, initial_position.z)
