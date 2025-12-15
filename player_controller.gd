extends CharacterBody3D

@export var walk_speed: float = 5.0
@export var run_speed: float = 10.0
@export var crouch_speed: float = 2.5
@export var jump_velocity: float = 4.5
@export var friction: float = 0.1
@export var acceleration: float = 0.2
@export var air_acceleration: float = 0.05
@export var mouse_sensitivity: float = 0.01
@export var arrow_key_sensitivity: float = 2.0
@export var max_stamina: float = 100.0
@export var stamina_drain_rate: float = 30.0
@export var stamina_recovery_rate: float = 15.0
@export var camera_bob_amount: float = 0.1
@export var camera_bob_speed: float = 8.0
@export var camera_bob_sprint_multiplier: float = 1.5
@export var stamina_exhaustion_threshold: float = 5.0
@export var stamina_recovery_threshold: float = 15.0
@export var run_shader_intensity: float = 1.0
@export var enable_run_shader: bool = true
@export var enemy_death_scene: PackedScene = null
@export var crouch_height: float = 0.5  # Scale of collider when crouching (0-1)
@export var crouch_camera_offset: float = 0.6  # How much camera moves down when crouching
@export var crouch_transition_speed: float = 10.0  # Speed of crouch transition
var gun = false
@onready var camera = %camera
@onready var stamina_label = Label.new()
@onready var stamina_bar = $"../TextureProgressBar"
@onready var shader_canvas: CanvasLayer = get_tree().root.get_node("ShaderCanvas")
@onready var player_collider = $player_collider

var multiplier = 60
var current_speed: float = 0.0
var stamina: float = 100.0
var bob_timer: float = 0.0
var is_running: bool = false
var is_exhausted: bool = false
var camera_initial_pos: Vector3
var is_crouching: bool = false
var current_crouch_amount: float = 0.0  # 0 = standing, 1 = fully crouched

var footstep_timer: float = 0.0
var walk_footstep_interval: float = 0.5
var run_footstep_interval: float = 0.3
var was_on_floor: bool = false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera_initial_pos = camera.position
	
	# Ensure shader canvas is on top of all 3D content
	if shader_canvas:
		shader_canvas.layer = 128
	
	# Setup stamina label
	add_child(stamina_label)
	stamina_label.anchor_left = 0.0
	stamina_label.anchor_top = 0.0
	stamina_label.offset_right = 200.0
	stamina_label.offset_bottom = 50.0
	stamina_label.add_theme_font_size_override("font_size", 24)

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * mouse_sensitivity
		camera.rotation.x -= event.relative.y * mouse_sensitivity
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

var times = 0

func _physics_process(delta):
	if Global.files == 0 and times == 0:
		$file_collected/lose_text.text = "GET TO THE BOAT"
		$file_collected.start()
		times += 1
	
	handle_arrow_key_camera_input(delta)
	
	# Handle crouch input
	handle_crouch_input(delta)
	
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
	
	# Toggle run (blocked if exhausted or crouching)
	var wants_to_run = Input.is_action_pressed("run") and direction.length() > 0 and not is_exhausted and not is_crouching
	is_running = wants_to_run
	
	# Determine target speed based on state
	var target_speed = walk_speed
	if is_running:
		target_speed = run_speed
	elif is_crouching:
		target_speed = crouch_speed
	
	# Update stamina bar
	stamina_bar.value = stamina
	
	# Fade bar in/out based on state
	var target_alpha = 0.0
	if is_running or stamina < max_stamina:
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
	
	# Footstep sound logic
	if current_speed > 0.1 and is_on_floor():
		var footstep_interval = run_footstep_interval if is_running else walk_footstep_interval
		footstep_timer += delta
		if footstep_timer >= footstep_interval:
			$footstep.pitch_scale = randf_range(0.9, 1.1)
			$footstep.play()
			footstep_timer = 0.0
	elif current_speed > 0.1 and is_on_floor() and not was_on_floor:
		$footstep.pitch_scale = randf_range(0.9, 1.1)
		$footstep.play()
		footstep_timer = 0.0
	else:
		footstep_timer = 0.0
	
	was_on_floor = is_on_floor()
	
	# Camera bob effect - only bob when moving on ground
	update_camera_bob(delta)
	
	# Update shader canvas effect
	update_shader_effect(delta)
	
	# Handle escape key to release mouse
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	move_and_slide()

func handle_crouch_input(delta):
	# Toggle crouch on keybind press
	if Input.is_action_just_pressed("crouch"):
		is_crouching = !is_crouching
	
	# Smoothly transition crouch amount
	var target_crouch = 1.0 if is_crouching else 0.0
	current_crouch_amount = move_toward(current_crouch_amount, target_crouch, crouch_transition_speed * delta)
	
	# Apply collider scaling
	if player_collider:
		var scale_factor = lerp(1.0, crouch_height, current_crouch_amount)
		player_collider.scale.y = scale_factor
	
	# Apply camera offset
	var camera_offset = crouch_camera_offset * current_crouch_amount
	camera.position.y = camera_initial_pos.y - camera_offset

func handle_arrow_key_camera_input(delta):
	var sensitivity_rad = deg_to_rad(arrow_key_sensitivity * delta)
	
	if Input.is_action_pressed("ui_right"):
		rotation.y -= sensitivity_rad * multiplier
	if Input.is_action_pressed("ui_left"):
		rotation.y += sensitivity_rad * multiplier
	
	if Input.is_action_pressed("ui_up"):
		camera.rotation.x += sensitivity_rad * multiplier
	if Input.is_action_pressed("ui_down"):
		camera.rotation.x -= sensitivity_rad * multiplier
	
	camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func update_camera_bob(delta):
	# Only bob if moving and on ground (don't bob while crouching)
	if current_speed > 0.1 and is_on_floor() and not is_crouching:
		var bob_multiplier = camera_bob_sprint_multiplier if is_running else 1.0
		bob_timer += delta * camera_bob_speed * bob_multiplier
		
		var bob_cycle = fmod(bob_timer, 1.0)
		var bob_y = sin(bob_cycle * PI) * camera_bob_amount * bob_multiplier
		
		camera.position = camera_initial_pos + Vector3(0, bob_y, 0) - Vector3(0, crouch_camera_offset * current_crouch_amount, 0)
	else:
		bob_timer = 0.0
		camera.position = camera_initial_pos - Vector3(0, crouch_camera_offset * current_crouch_amount, 0)

func update_shader_effect(delta):
	if not enable_run_shader:
		return
	
	if not shader_canvas:
		return
	
	var shader_material = shader_canvas.get_node("ColorRect").material as ShaderMaterial
	if not shader_material:
		return
	
	var target_intensity = run_shader_intensity if is_running else 0.0
	var current_intensity = shader_material.get_shader_parameter("intensity")
	var new_intensity = move_toward(current_intensity, target_intensity, 3.0 * delta)
	
	shader_material.set_shader_parameter("intensity", new_intensity)

func _process(delta):
	Global.player_pos = position

func _on_hitbox_area_entered(area):
	if area.is_in_group("file"):
		area.queue_free()
		$cassette.play()
		$file_collected.start()
		Global.files -= 1
	if area.is_in_group("gun"):
		$file_collected/lose_text.text = "GUN COLLECTED"
		$file_collected.start()
		gun = true
		
	if area.is_in_group("water"):
		Global.cause = "DROWNED"
		get_tree().change_scene_to_file("res://lose.tscn")
	if area.is_in_group("boat") and Global.files == 0:
		get_tree().change_scene_to_file("res://win.tscn")

func _on_hitbox_body_entered(body):
	if body.is_in_group("enemy"):
		body.queue_free()
		Global.cause = "JEFFREY"
		
		if enemy_death_scene:
			var effect = enemy_death_scene.instantiate()
			get_tree().root.add_child(effect)
			effect.global_position = Vector2.ZERO
