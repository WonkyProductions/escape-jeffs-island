extends CharacterBody3D

# --- HANDS ---
@onready var left_hand: Node3D = $enemy_mesh/enemy_left_hand_mesh
@onready var right_hand: Node3D = $enemy_mesh/enemy_right_hand_mesh2

# --- Exported Variables ---
const SPEED_CLOSEST = 5.0
const SPEED_MIN = 5.0
const SPEED_MAX = 12.0
const JUMP_VELOCITY = 5.0
const ROTATION_SMOOTHNESS = 0.1
const JUMP_CHANCE_TIME = 0.5

# Difficulty scaling
const FILES_MIN: float = 5.0
const FILES_MAX: float = 10.0
const SPEED_MULTIPLIER_MIN: float = 1.5
const SPEED_MULTIPLIER_MAX: float = 1.0

@export var SPEED_DISTANCE_CLOSE: float = 2.0
@export var SPEED_DISTANCE_MIN: float = 5.0
@export var SPEED_DISTANCE_MAX: float = 20.0

const MAP_BOUND_X_Z: float = 150.0
const SPAWN_HEIGHT: float = 10.0

@export var HAND_ACTIVATION_DISTANCE: float = 18.0
@export var ROTATION_WOBBLE_AMOUNT: float = 0.2
@export var STRAFE_WOBBLE_AMOUNT: float = 0.1
@export var HAND_TRANSITION_SPEED: float = 10.0

# Chase timeout
@export var CHASE_TIMEOUT_DURATION: float = 15.0
@export var CHASE_DISTANCE_THRESHOLD: float = 15.0

# Stuck detection
@export var STUCK_CHECK_INTERVAL: float = 1.0
@export var STUCK_DISTANCE_TOLERANCE: float = 3.0
@export var STUCK_DURATION: float = 5.0

# Escape behavior
@export var ESCAPE_DISTANCE_MIN: float = 75.0
@export var ESCAPE_DISTANCE_MAX: float = 150.0
@export var ESCAPE_SPEED: float = 6.0
@export var INITIAL_SPEED_DURATION: float = 2.0
@export var INITIAL_SPEED: float = 20.0

# Max distance before retreating
@export var MAX_ESCAPE_DISTANCE: float = 120.0

# --- Internal Variables ---
var time_since_last_jump_check: float = 0.0
var direction_to_move: Vector3 = Vector3.ZERO
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var original_left_pos: Vector3 = Vector3.ZERO
var original_right_pos: Vector3 = Vector3.ZERO
var original_left_scale: Vector3 = Vector3.ONE
var original_right_scale: Vector3 = Vector3.ONE

var time: float = 0.0
var hand_blend_factor: float = 0.0

const HAND_START_OFFSET_Y = -0.5

# Chase timeout variables
var chase_timer: float = 0.0
var is_chasing_closely: bool = false
var escape_target: Vector3 = Vector3.ZERO
var is_escaping: bool = false

# Stuck detection variables
var last_stuck_check_pos: Vector3 = Vector3.ZERO
var stuck_timer: float = 0.0
var stuck_check_timer: float = 0.0

# Game start timer
var game_start_timer: float = 0.0


func _prepare_hand_material(hand: Node3D):
	if hand and hand.get_child_count() > 0:
		var mesh_instance = hand.get_child(0)
		if mesh_instance is MeshInstance3D:
			for i in range(mesh_instance.get_surface_override_material_count()):
				var material = mesh_instance.get_surface_override_material(i)
				if material:
					var unique_material = material.duplicate()
					if unique_material is StandardMaterial3D:
						unique_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					mesh_instance.set_surface_override_material(i, unique_material)

func _set_hand_alpha(hand: Node3D, alpha: float):
	if hand and hand.get_child_count() > 0:
		var mesh_instance = hand.get_child(0)
		if mesh_instance is MeshInstance3D:
			for i in range(mesh_instance.get_surface_override_material_count()):
				var material = mesh_instance.get_surface_override_material(i)
				if material and material is StandardMaterial3D:
					var albedo = material.albedo_color
					albedo.a = alpha 
					material.albedo_color = albedo

func _get_speed_multiplier() -> float:
	if not Global.has_meta("files"):
		return SPEED_MULTIPLIER_MAX
	
	var current_files = float(Global.files)
	current_files = clamp(current_files, FILES_MIN, FILES_MAX)
	
	var multiplier = lerp(SPEED_MULTIPLIER_MIN, SPEED_MULTIPLIER_MAX, 
						   inverse_lerp(FILES_MIN, FILES_MAX, current_files))
	
	return multiplier

# --- READY FUNCTION ---

func _ready():
	if left_hand:
		original_left_pos = left_hand.position
		original_left_scale = left_hand.scale
		
		_prepare_hand_material(left_hand)
		left_hand.scale = original_left_scale 
		_set_hand_alpha(left_hand, 0.0)
		left_hand.visible = true

	if right_hand:
		original_right_pos = right_hand.position
		original_right_scale = right_hand.scale
		
		_prepare_hand_material(right_hand)
		right_hand.scale = original_right_scale 
		_set_hand_alpha(right_hand, 0.0)
		right_hand.visible = true

	_spawn_in_random_corner()
	last_stuck_check_pos = global_position


func _spawn_in_random_corner():
	var x_options = [-MAP_BOUND_X_Z, MAP_BOUND_X_Z]
	var z_options = [-MAP_BOUND_X_Z, MAP_BOUND_X_Z]
	
	var spawn_x = x_options[randi() % 2]
	var spawn_z = z_options[randi() % 2]
	
	global_position = Vector3(spawn_x, SPAWN_HEIGHT, spawn_z)
	last_stuck_check_pos = global_position
	stuck_timer = 0.0
	is_escaping = false
	chase_timer = 0.0
	print("Enemy spawned at: ", global_position)


func _pick_escape_point():
	# Pick a random direction away from the player
	var away_direction = randf_range(0, TAU)
	var escape_distance = randf_range(ESCAPE_DISTANCE_MIN, ESCAPE_DISTANCE_MAX)
	escape_target = global_position + Vector3(cos(away_direction), 0, sin(away_direction)) * escape_distance
	
	# Clamp to map bounds
	escape_target.x = clamp(escape_target.x, -MAP_BOUND_X_Z, MAP_BOUND_X_Z)
	escape_target.z = clamp(escape_target.z, -MAP_BOUND_X_Z, MAP_BOUND_X_Z)
	escape_target.y = 0
	
	is_escaping = true
	chase_timer = 0.0
	print("Enemy picked escape point at: ", escape_target)


func _process(delta):
	time += delta
	game_start_timer += delta
	_handle_hands(delta)


func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	_handle_stuck_detection(delta)
	_handle_chase_timeout(delta)
	_handle_rotation(delta)
	_handle_jump(delta)
	var current_speed: float = SPEED_MIN
	var target_direction = Vector3.ZERO
	
	if is_escaping:
		# Run to escape point
		target_direction = (escape_target - global_transform.origin).normalized()
		target_direction.y = 0
		current_speed = ESCAPE_SPEED
		
		# Check if reached escape target
		if global_position.distance_to(escape_target) < 5.0:
			is_escaping = false
			print("Enemy reached escape point, resuming chase")
	elif Global.player_pos:
		# Chase player normally
		target_direction = (Global.player_pos - global_transform.origin).normalized()
		target_direction.y = 0
		
		var distance_to_player = global_transform.origin.distance_to(Global.player_pos)
		
		# Use initial speed for first 3 seconds
		if game_start_timer < INITIAL_SPEED_DURATION:
			current_speed = INITIAL_SPEED
		elif distance_to_player >= SPEED_DISTANCE_MIN:
			var factor_far = inverse_lerp(SPEED_DISTANCE_MIN, SPEED_DISTANCE_MAX, distance_to_player)
			factor_far = clamp(factor_far, 0.0, 1.0)
			current_speed = lerp(SPEED_MIN, SPEED_MAX, factor_far)
			
		elif distance_to_player > SPEED_DISTANCE_CLOSE:
			var factor_close = inverse_lerp(SPEED_DISTANCE_CLOSE, SPEED_DISTANCE_MIN, distance_to_player)
			current_speed = lerp(SPEED_CLOSEST, SPEED_MIN, factor_close)
			
		else:
			current_speed = SPEED_CLOSEST
	
	var speed_multiplier = _get_speed_multiplier()
	current_speed *= speed_multiplier
	
	velocity.x = target_direction.x * current_speed
	velocity.z = target_direction.z * current_speed
	
	if target_direction.length_squared() < 0.1:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	move_and_slide()


## --- AI Core Functions ---

func _handle_stuck_detection(delta):
	stuck_check_timer += delta
	
	if stuck_check_timer >= STUCK_CHECK_INTERVAL:
		stuck_check_timer = 0.0
		
		var distance_moved = global_position.distance_to(last_stuck_check_pos)
		
		if distance_moved < STUCK_DISTANCE_TOLERANCE:
			stuck_timer += STUCK_CHECK_INTERVAL
			if stuck_timer >= STUCK_DURATION:
				print("Enemy stuck, respawning")
				_spawn_in_random_corner()
				stuck_timer = 0.0
		else:
			stuck_timer = 0.0
		
		last_stuck_check_pos = global_position


func _handle_chase_timeout(delta):
	if not Global.player_pos or is_escaping:
		chase_timer = 0.0
		return
	
	var distance_to_player = global_transform.origin.distance_to(Global.player_pos)
	
	if distance_to_player < CHASE_DISTANCE_THRESHOLD:
		chase_timer += delta
		if chase_timer >= CHASE_TIMEOUT_DURATION:
			_pick_escape_point()
	else:
		chase_timer = 0.0


func _handle_rotation(delta):
	var target_direction = Vector3.ZERO
	
	if is_escaping:
		target_direction = (escape_target - global_transform.origin)
	elif Global.player_pos:
		target_direction = (Global.player_pos - global_transform.origin)
	
	target_direction.y = 0
	
	if target_direction.length_squared() > 0:
		var wobble_offset = sin(time * 0.8) * ROTATION_WOBBLE_AMOUNT
		var wobbled_direction = target_direction.rotated(Vector3.UP, wobble_offset)
		
		var target_basis = Basis.looking_at(wobbled_direction, Vector3.UP)
		
		global_transform.basis = global_transform.basis.slerp(target_basis, ROTATION_SMOOTHNESS)


func _handle_jump(delta):
	time_since_last_jump_check += delta
	
	if is_on_floor() and time_since_last_jump_check >= JUMP_CHANCE_TIME:
		time_since_last_jump_check = 0.0
		
		var distance_to_player = global_transform.origin.distance_to(Global.player_pos) if Global.player_pos else 0
		var needs_to_move = distance_to_player > 5.0

		if randf() < 0.1 and needs_to_move:
			velocity.y = JUMP_VELOCITY
			print("AI Jumps!")

## --- HAND LOGIC ---

func _handle_hands(delta):
	if not Global.player_pos:
		return

	var enemy_xz = global_transform.origin
	var player_xz = Global.player_pos
	enemy_xz.y = 0
	player_xz.y = 0
	
	var distance_sq = enemy_xz.distance_squared_to(player_xz)
	var threshold_sq = HAND_ACTIVATION_DISTANCE * HAND_ACTIVATION_DISTANCE

	var target_blend = 1.0 if distance_sq < threshold_sq else 0.0
	hand_blend_factor = lerp(hand_blend_factor, target_blend, delta * HAND_TRANSITION_SPEED)

	if left_hand and right_hand:
		_set_hand_alpha(left_hand, hand_blend_factor)
		_set_hand_alpha(right_hand, hand_blend_factor)
		
		const HIDE_THRESHOLD = 0.001
		if hand_blend_factor < HIDE_THRESHOLD:
			left_hand.visible = false
			right_hand.visible = false
		else:
			left_hand.visible = true
			right_hand.visible = true

	if left_hand and right_hand:
		var current_offset_y = lerp(HAND_START_OFFSET_Y, 0.0, hand_blend_factor)
		var wiggle_amount = 0.1 * hand_blend_factor
		var wiggle_speed = 10.0
		
		left_hand.position.x = original_left_pos.x + sin(time * wiggle_speed) * wiggle_amount
		left_hand.position.y = original_left_pos.y + current_offset_y + cos(time * wiggle_speed * 0.5) * wiggle_amount * 0.5
		left_hand.position.z = original_left_pos.z

		right_hand.position.x = original_right_pos.x
		right_hand.position.y = original_right_pos.y + current_offset_y + sin(time * wiggle_speed * 0.7) * wiggle_amount * 0.5
		right_hand.position.z = original_right_pos.z + cos(time * wiggle_speed * 1.2) * wiggle_amount


func _on_area_3d_area_entered(area):
	if area.is_in_group("water"):
		print("Enemy touched water, respawning")
		_spawn_in_random_corner()
		return
