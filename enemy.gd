extends CharacterBody3D

@onready var left_hand: Node3D = $enemy_mesh/enemy_left_hand_mesh
@onready var right_hand: Node3D = $enemy_mesh/enemy_right_hand_mesh2

var sounds = [preload("res://sfx/solo-clap-90129.mp3"), preload("res://sfx/Recording (5).mp3"), preload("res://sfx/Recording (6).mp3"),preload("res://sfx/Recording (7).mp3"),preload("res://sfx/Recording (8).mp3"),preload("res://sfx/Recording (9).mp3")]

const SPEED_MIN = 5.0
const SPEED_MAX = 12.0
const JUMP_VELOCITY = 5.0
const ROTATION_SMOOTHNESS = 0.1
const FILES_MIN: float = 5.0
const FILES_MAX: float = 10.0
const SPEED_MULTIPLIER_MIN: float = 1.5
const SPEED_MULTIPLIER_MAX: float = 1.0

@export var SPEED_DISTANCE_CLOSE: float = 2.0
@export var SPEED_DISTANCE_MIN: float = 5.0
@export var SPEED_DISTANCE_MAX: float = 20.0
@export var HAND_ACTIVATION_DISTANCE: float = 18.0
@export var MAP_BOUND_X_Z: float = 150.0
@export var stun_duration: float = 30.0
@export var death_shrink_duration: float = 0.3

var time: float = 0.0
var hand_blend_factor: float = 0.0
var time_since_jump: float = 0.0
var original_left_pos: Vector3
var original_right_pos: Vector3
var freak_timer: float = 0.0
var freak_sound_interval: float = 5.0
var last_sound_index: int = -1
var last_sound_index_prev: int = -1

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var patrol_timer: float = 0.0
var patrol_interval: float = 20.0
var patrol_target: Vector3 = Vector3.ZERO
var is_patrolling: bool = false
var patrol_arrival_distance: float = 5.0

var is_stunned: bool = false
var stun_timer: float = 0.0
var position_before_stun: Vector3 = Vector3.ZERO
var is_dead: bool = false
var respawn_timer: float = 0.0
var respawn_duration: float = 30.0


func _ready():
	add_to_group("enemy")
	
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
	
	if current_files == 0:
		return 2.0
	
	current_files = clamp(current_files, FILES_MIN, FILES_MAX)
	
	return lerp(SPEED_MULTIPLIER_MIN, SPEED_MULTIPLIER_MAX, 
			   inverse_lerp(FILES_MIN, FILES_MAX, current_files))


func _pick_patrol_target() -> Vector3:
	var angle = randf() * TAU
	var distance = 100.0
	var offset = Vector3(cos(angle) * distance, 0, sin(angle) * distance)
	return global_position + offset


func _process(delta):
	time += delta
	_update_hands(delta)
	
	if is_dead:
		# Handle respawn timer while dead
		respawn_timer -= delta
		var seconds = int(ceil(respawn_timer))
		$"../respawn_text".text = "RESPAWNING IN " + str(seconds)
		$"../respawn_text".visible = true
		
		if respawn_timer <= 0.0:
			is_dead = false
			scale = Vector3.ONE
			global_position = position_before_stun
			$"../respawn_text".visible = false
		return
	
	# Handle stun timer
	if is_stunned:
		stun_timer -= delta
		var seconds = ceil(stun_timer)
		$"../stun_text".text = str(seconds)
		$"../stun_text".visible = true
		
		if stun_timer <= 0.0:
			is_stunned = false
			global_position = position_before_stun
			$"../stun_text".visible = false
	
	# Patrol logic
	if Global.files != 0 and not is_stunned:
		patrol_timer += delta
		if patrol_timer >= patrol_interval and not is_patrolling:
			is_patrolling = true
			patrol_target = _pick_patrol_target()
			patrol_timer = 0.0
	
	# Freak sound logic
	if not is_stunned:
		freak_timer += delta
		if freak_timer >= freak_sound_interval:
			var audio_player = AudioStreamPlayer.new()
			add_child(audio_player)
			
			var sound_index = randi() % sounds.size()
			while (sound_index == last_sound_index or sound_index == last_sound_index_prev) and sounds.size() > 2:
				sound_index = randi() % sounds.size()
			last_sound_index_prev = last_sound_index
			last_sound_index = sound_index
			
			var volume_db = 0.0
			if Global.player_pos:
				var distance = global_position.distance_to(Global.player_pos)
				if distance > 20.0:
					volume_db = -20.0 - (distance - 20.0) * 0.5
				elif distance >= 5.0:
					volume_db = lerp(0.0, -20.0, inverse_lerp(5.0, 20.0, distance))
				else:
					volume_db = 0.0
			
			audio_player.stream = sounds[sound_index]
			audio_player.volume_db = volume_db
			audio_player.pitch_scale = randf_range(0.7, 0.9)
			audio_player.play()
			freak_timer = 0.0


func _physics_process(delta):
	if is_stunned or is_dead:
		return
	
	if not is_on_floor():
		velocity.y -= gravity * delta

	var target_dir = Vector3.ZERO
	var current_speed = SPEED_MIN

	var target_position = Global.player_pos
	if is_patrolling and Global.files != 0:
		target_position = patrol_target
		
		if global_position.distance_to(patrol_target) < patrol_arrival_distance:
			is_patrolling = false
			patrol_timer = 0.0

	if target_position:
		target_dir = (target_position - global_position).normalized()
		target_dir.y = 0
		
		var distance = global_position.distance_to(target_position)
		
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

	time_since_jump += delta
	if is_on_floor() and time_since_jump >= 0.5 and randf() < 0.003:
		velocity.y = JUMP_VELOCITY
		time_since_jump = 0.0

	if target_dir.length_squared() > 0:
		var target_basis = Basis.looking_at(target_dir, Vector3.UP)
		global_transform.basis = global_transform.basis.slerp(target_basis, ROTATION_SMOOTHNESS)

	move_and_slide()


func _update_hands(delta):
	if not Global.player_pos or is_dead:
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


func die():
	$"../grunt".play()
	if is_dead:
		return
	
	is_dead = true
	print("Enemy died!")
	
	# Save position for respawn
	position_before_stun = global_position
	respawn_timer = respawn_duration
	
	# Shrink and disappear
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, death_shrink_duration)
