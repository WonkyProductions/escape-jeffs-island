extends CharacterBody3D

@onready var left_hand: Node3D = $enemy_mesh/enemy_left_hand_mesh
@onready var right_hand: Node3D = $enemy_mesh/enemy_right_hand_mesh2

# Movement
const SPEED_MIN = 5.0
const SPEED_MAX = 12.0
const JUMP_VELOCITY = 5.0
const ROTATION_SMOOTHNESS = 0.1

# Difficulty scaling
const FILES_MIN: float = 5.0
const FILES_MAX: float = 10.0
const SPEED_MULTIPLIER_MIN: float = 1.5
const SPEED_MULTIPLIER_MAX: float = 1.0

@export var SPEED_DISTANCE_CLOSE: float = 2.0
@export var SPEED_DISTANCE_MIN: float = 5.0
@export var SPEED_DISTANCE_MAX: float = 20.0
@export var HAND_ACTIVATION_DISTANCE: float = 18.0
@export var MAP_BOUND_X_Z: float = 150.0

var time: float = 0.0
var hand_blend_factor: float = 0.0
var time_since_jump: float = 0.0
var original_left_pos: Vector3
var original_right_pos: Vector3

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready():
	if left_hand:
		original_left_pos = left_hand.position
		_prepare_hand_material(left_hand)
		_set_hand_alpha(left_hand, 0.0)

	if right_hand:
		original_right_pos = right_hand.position
		_prepare_hand_material(right_hand)
		_set_hand_alpha(right_hand, 0.0)

	_spawn_random()


func _spawn_random():
	var spawn_x = [-MAP_BOUND_X_Z, MAP_BOUND_X_Z][randi() % 2]
	var spawn_z = [-MAP_BOUND_X_Z, MAP_BOUND_X_Z][randi() % 2]
	global_position = Vector3(spawn_x, 10.0, spawn_z)


func _prepare_hand_material(hand: Node3D):
	if hand and hand.get_child_count() > 0:
		var mesh_instance = hand.get_child(0)
		if mesh_instance is MeshInstance3D:
			for i in range(mesh_instance.get_surface_override_material_count()):
				var material = mesh_instance.get_surface_override_material(i)
				if material:
					var unique_mat = material.duplicate()
					if unique_mat is StandardMaterial3D:
						unique_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					mesh_instance.set_surface_override_material(i, unique_mat)


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
	
	# Twice as fast if no files
	if current_files == 0:
		return 2.0
	
	current_files = clamp(current_files, FILES_MIN, FILES_MAX)
	
	return lerp(SPEED_MULTIPLIER_MIN, SPEED_MULTIPLIER_MAX, 
			   inverse_lerp(FILES_MIN, FILES_MAX, current_files))


func _process(delta):
	time += delta
	_update_hands(delta)


func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	var target_dir = Vector3.ZERO
	var current_speed = SPEED_MIN

	if Global.player_pos:
		target_dir = (Global.player_pos - global_position).normalized()
		target_dir.y = 0
		
		var distance = global_position.distance_to(Global.player_pos)
		
		if distance >= SPEED_DISTANCE_MIN:
			var factor = inverse_lerp(SPEED_DISTANCE_MIN, SPEED_DISTANCE_MAX, distance)
			current_speed = lerp(SPEED_MIN, SPEED_MAX, clamp(factor, 0.0, 1.0))
		elif distance > SPEED_DISTANCE_CLOSE:
			var factor = inverse_lerp(SPEED_DISTANCE_CLOSE, SPEED_DISTANCE_MIN, distance)
			current_speed = lerp(5.0, SPEED_MIN, factor)
		else:
			current_speed = 5.0

	current_speed *= _get_speed_multiplier()

	velocity.x = target_dir.x * current_speed
	velocity.z = target_dir.z * current_speed

	# Jump occasionally
	time_since_jump += delta
	if is_on_floor() and time_since_jump >= 0.5 and randf() < 0.003:
		velocity.y = JUMP_VELOCITY
		time_since_jump = 0.0

	# Rotate toward player
	if target_dir.length_squared() > 0:
		var target_basis = Basis.looking_at(target_dir, Vector3.UP)
		global_transform.basis = global_transform.basis.slerp(target_basis, ROTATION_SMOOTHNESS)

	move_and_slide()


func _update_hands(delta):
	if not Global.player_pos:
		return

	var distance_sq = global_position.distance_squared_to(Global.player_pos)
	var threshold_sq = HAND_ACTIVATION_DISTANCE * HAND_ACTIVATION_DISTANCE
	var target_blend = 1.0 if distance_sq < threshold_sq else 0.0
	
	hand_blend_factor = lerp(hand_blend_factor, target_blend, delta * 10.0)

	if left_hand:
		_set_hand_alpha(left_hand, hand_blend_factor)
		left_hand.visible = hand_blend_factor > 0.001
		left_hand.position.x = original_left_pos.x + sin(time * 10.0) * 0.1 * hand_blend_factor
		left_hand.position.y = original_left_pos.y + cos(time * 5.0) * 0.05 * hand_blend_factor

	if right_hand:
		_set_hand_alpha(right_hand, hand_blend_factor)
		right_hand.visible = hand_blend_factor > 0.001
		right_hand.position.z = original_right_pos.z + cos(time * 12.0) * 0.1 * hand_blend_factor


func _on_area_3d_area_entered(area):
	if area.is_in_group("water"):
		_spawn_random()
