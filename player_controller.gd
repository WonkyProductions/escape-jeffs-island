extends CharacterBody3D

@export var walk_speed: float = 5.0
@export var run_speed: float = 10.0
@export var jump_velocity: float = 4.5
@export var friction: float = 0.1
@export var acceleration: float = 0.2
@export var air_acceleration: float = 0.05
@export var mouse_sensitivity: float = 0.01
@export var arrow_key_sensitivity: float = 2.0  # Degrees per frame for arrow keys
@export var max_stamina: float = 100.0
@export var stamina_drain_rate: float = 30.0
@export var stamina_recovery_rate: float = 15.0
@export var camera_bob_amount: float = 0.1
@export var camera_bob_speed: float = 8.0
@export var camera_bob_sprint_multiplier: float = 1.5
@export var stamina_exhaustion_threshold: float = 5.0
@export var stamina_recovery_threshold: float = 15.0
@export var run_shader_intensity: float = 1.0
@export var enable_run_shader: bool = true  # Toggle for run shader effect
@export var enemy_death_scene: PackedScene = null

@onready var camera = %camera
@onready var stamina_label = Label.new()
@onready var stamina_bar = $"../TextureProgressBar"
@onready var shader_canvas: CanvasLayer = get_tree().root.get_node("ShaderCanvas")
var multiplier = 60
var current_speed: float = 0.0
var stamina: float = 100.0
var bob_timer: float = 0.0
var is_running: bool = false
var is_exhausted: bool = false
var camera_initial_pos: Vector3

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera_initial_pos = camera.position
	
	# Ensure shader canvas is on top of all 3D content
	if shader_canvas:
		shader_canvas.layer = 128  # Set to highest layer
	
	# Setup stamina label
	add_child(stamina_label)
	stamina_label.anchor_left = 0.0
	stamina_label.anchor_top = 0.0
	stamina_label.offset_right = 200.0
	stamina_label.offset_bottom = 50.0
	stamina_label.add_theme_font_size_override("font_size", 24)

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Rotate body left/right (Y axis)
		rotation.y -= event.relative.x * mouse_sensitivity
		# Rotate camera up/down only (X axis)
		camera.rotation.x -= event.relative.y * mouse_sensitivity
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func _physics_process(delta):
	# Handle arrow key camera controls
	handle_arrow_key_camera_input(delta)
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	
	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	# Get input direction (WASD)
	var input_dir = Input.get_vector("a", "d", "w", "s")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Update stamina first
	if is_running:
		stamina = max(0, stamina - stamina_drain_rate * delta)
	else:
		stamina = min(max_stamina, stamina + stamina_recovery_rate * delta)
	
	# Stamina exhaustion system
	if stamina <= stamina_exhaustion_threshold:
		is_exhausted = true
	elif stamina >= stamina_recovery_threshold:
		is_exhausted = false
	
	# Toggle run (blocked if exhausted)
	var wants_to_run = Input.is_action_pressed("run") and direction.length() > 0 and not is_exhausted
	is_running = wants_to_run
	
	var target_speed = run_speed if is_running else walk_speed
	
	# Update stamina bar
	stamina_bar.value = stamina
	
	# Fade bar in/out based on state
	var target_alpha = 0.0
	if is_running or stamina < max_stamina:  # Show when running or when not full
		target_alpha = 1.0
	stamina_bar.modulate.a = move_toward(stamina_bar.modulate.a, target_alpha, 2.0 * delta)
	
	# Smooth speed transitions
	var move_accel = acceleration if is_on_floor() else air_acceleration
	if direction:
		current_speed = move_toward(current_speed, target_speed, move_accel)
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		current_speed = move_toward(current_speed, 0, friction)
		velocity.x = move_toward(velocity.x, 0, friction)
		velocity.z = move_toward(velocity.z, 0, friction)
	
	# Camera bob effect - only bob when moving on ground
	update_camera_bob(delta)
	
	# Update shader canvas effect
	update_shader_effect(delta)
	
	# Handle escape key to release mouse
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	move_and_slide()

func handle_arrow_key_camera_input(delta):
	# Convert arrow key sensitivity from degrees to radians
	var sensitivity_rad = deg_to_rad(arrow_key_sensitivity * delta)
	
	# Left/Right arrows rotate body (Y axis)
	if Input.is_action_pressed("ui_right"):
		rotation.y -= sensitivity_rad * multiplier
	if Input.is_action_pressed("ui_left"):
		rotation.y += sensitivity_rad * multiplier
	
	# Up/Down arrows rotate camera (X axis)
	if Input.is_action_pressed("ui_up"):
		camera.rotation.x += sensitivity_rad * multiplier
	if Input.is_action_pressed("ui_down"):
		camera.rotation.x -= sensitivity_rad * multiplier
	
	# Clamp vertical camera rotation
	camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func update_camera_bob(delta):
	# Only bob if moving and on ground
	if current_speed > 0.1 and is_on_floor():
		var bob_multiplier = camera_bob_sprint_multiplier if is_running else 1.0
		bob_timer += delta * camera_bob_speed * bob_multiplier
		
		# Smoother bob with parabolic motion (0 to 1 to 0 cycle)
		var bob_cycle = fmod(bob_timer, 1.0)  # 0-1 over one step
		var bob_y = sin(bob_cycle * PI) * camera_bob_amount * bob_multiplier
		
		camera.position = camera_initial_pos + Vector3(0, bob_y, 0)
	else:
		# Return to initial position when not moving
		bob_timer = 0.0
		camera.position = camera_initial_pos

func update_shader_effect(delta):
	# Check if shader effect is disabled
	if not enable_run_shader:
		return
	
	# Only apply effect if shader canvas exists
	if not shader_canvas:
		return
	
	var shader_material = shader_canvas.get_node("ColorRect").material as ShaderMaterial
	if not shader_material:
		return
	
	# Apply a constant subtle vignette effect in the corners
	var target_intensity = run_shader_intensity if is_running else 0.0
	var current_intensity = shader_material.get_shader_parameter("intensity")
	var new_intensity = move_toward(current_intensity, target_intensity, 3.0 * delta)
	
	shader_material.set_shader_parameter("intensity", new_intensity)

func _process(delta):
	Global.player_pos = position

func _on_hitbox_area_entered(area):
	if area.is_in_group("file"):
		area.queue_free()
		Global.files -= 1
	if area.is_in_group("water"):
		Global.cause = "DROWNED"
		get_tree().change_scene_to_file("res://lose.tscn")
	if area.is_in_group("boat") and Global.files == 0:
		get_tree().change_scene_to_file("res://win.tscn")
func _on_hitbox_body_entered(body):
	if body.is_in_group("enemy"):
		body.queue_free()
		Global.cause = "JEFFREY"
		
		# Instantiate death effect at center of screen
		if enemy_death_scene:
			var effect = enemy_death_scene.instantiate()
			get_tree().root.add_child(effect)
			effect.global_position = Vector2.ZERO
			
			# Use tween to handle timing without blocking
