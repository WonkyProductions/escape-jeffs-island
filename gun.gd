extends Area3D

@export var rotation_speed: float = 1.0
@export var snap_up_offset: float = 0.5
@export var descent_speed: float = 10.0
@export var shrink_duration: float = 0.3
var sketchfab_scene: Node3D
var initial_position: Vector3
var current_height: float = 0.0
var is_grounded: bool = false
var ground_height: float = 0.0

func _ready():
	position.x = randi_range(-800, 800)
	position.z = randi_range(-800, 800)
	initial_position = position
	current_height = position.y
	monitoring = true
	
	# Find the Sketchfab scene child - try different approaches
	sketchfab_scene = get_node_or_null("Sketchfab_Scene")
	if sketchfab_scene == null:
		# If not found, try to get the first child
		if get_child_count() > 0:
			sketchfab_scene = get_child(0) as Node3D
	
	if sketchfab_scene == null:
		push_error("Could not find Sketchfab_Scene child node")

func _process(delta):
	# Rotate only Y axis on the Sketchfab scene child if it exists
	if sketchfab_scene != null:
		sketchfab_scene.rotation.y += rotation_speed * delta
	
	# If not grounded yet, descend until hitting something
	if not is_grounded:
		current_height -= descent_speed * delta
		position.y = current_height
		
		var overlapping_bodies = get_overlapping_bodies()
		if overlapping_bodies.size() > 0:
			ground_height = current_height + snap_up_offset
			is_grounded = true
	else:
		# Once grounded, maintain position while child rotates
		position = Vector3(initial_position.x, ground_height, initial_position.z)

func _on_body_entered(body):
	if body.is_in_group("player"):
		$"../gun_collect".play()
		# Shrink Sketchfab_Scene to scale 0 then queue_free
		var tween = create_tween()
		tween.tween_property(sketchfab_scene, "scale", Vector3.ZERO, shrink_duration)
		tween.tween_callback(sketchfab_scene.queue_free)
		
		# Immediately queue_free gunCollider
		$gunCollider.queue_free()
