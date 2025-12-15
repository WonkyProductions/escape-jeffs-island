extends Node3D

@onready var raycast: RayCast3D = $raycast
@onready var camera = %camera
@onready var muzzle_flash = $muzzle_flash

@export var out_of_ammo_duration: float = 0.5
@export var raycast_check_frames: int = 10

var rounds: int = 3
var raycast_frames: int = 0
var raycast_enabled: bool = false
var original_position: Vector3
var original_rotation: Vector3
var is_recoiling: bool = false
var recoil_timer: float = 0.0
var recoil_duration: float = 0.075
var is_shaking: bool = false
var shake_timer: float = 0.0
var shake_duration: float = 0.1
var shake_intensity: float = 0.1
var muzzle_flash_timer: float = 0.0
var muzzle_flash_duration: float = 0.05
var is_out_of_ammo: bool = false

func _ready():
	raycast.enabled = false
	original_position = position
	original_rotation = rotation
	if not $"../..".gun:
		hide()

func _process(delta):
	# Show/hide based on gun condition
	if $"../..".gun and not is_out_of_ammo:
		show()
	else:
		hide()
	
	# Handle muzzle flash
	if muzzle_flash_timer > 0.0:
		muzzle_flash_timer -= delta
		if muzzle_flash_timer <= 0.0:
			muzzle_flash.hide()
	
	# Handle camera shake
	if is_shaking:
		shake_timer += delta
		if shake_timer >= shake_duration:
			is_shaking = false
			camera.position = Vector3.ZERO
			shake_timer = 0.0
		else:
			var progress = shake_timer / shake_duration
			var eased_progress = 1.0 - pow(progress, 2.0)
			var fade_intensity = shake_intensity * eased_progress
			camera.position = Vector3(
				randf_range(-fade_intensity, fade_intensity),
				randf_range(-fade_intensity, fade_intensity),
				randf_range(-fade_intensity, fade_intensity)
			)
	
	# Handle recoil
	if is_recoiling:
		recoil_timer += delta
		var progress = clamp(recoil_timer / (recoil_duration * 2), 0.0, 1.0)
		var eased_progress = progress if progress < 0.5 else 1.0 - (progress - 0.5) * 2.0
		
		position = original_position.lerp(original_position + Vector3(0, 0, 0.3), eased_progress)
		rotation = original_rotation.lerp(original_rotation + Vector3(0.2, 0, 0), eased_progress)
		
		if recoil_timer >= recoil_duration * 2:
			is_recoiling = false
			position = original_position
			rotation = original_rotation
			recoil_timer = 0.0
	
	# Check raycast collision while enabled
	if raycast_enabled:
		raycast_frames += 1
		raycast.force_raycast_update()
		
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider:
				print("HIT! Colliding with: ", collider)
				
				# Check if collider's parent is named "enemy"
				var parent = collider.get_parent()
				if parent and parent.name == "enemy":
					print("Enemy parent found! Calling die()")
					parent.die()
					raycast.enabled = false
					raycast_enabled = false
					raycast_frames = 0
				# Also check if collider itself is in enemy group
				elif collider.is_in_group("enemy"):
					print("Enemy collider found! Calling die()")
					collider.die()
					raycast.enabled = false
					raycast_enabled = false
					raycast_frames = 0
		
		# Disable after set number of frames
		if raycast_frames >= raycast_check_frames:
			raycast.enabled = false
			raycast_enabled = false
			raycast_frames = 0
	
	# Handle click input
	if Input.is_action_just_pressed("shoot") and $"../..".gun and not is_out_of_ammo:
		if rounds > 0:
			rounds -= 1
			_fire()
		
		# Check if out of ammo
		if rounds == 0:
			print("Out of ammo!")
			is_out_of_ammo = true
			_play_out_of_ammo_animation()

func _fire():
	$"../../gunshot".play()
	raycast.enabled = true
	raycast_enabled = true
	raycast_frames = 0
	is_recoiling = true
	recoil_timer = 0.0
	is_shaking = true
	shake_timer = 0.0
	muzzle_flash_timer = muzzle_flash_duration
	$muzzle_flash.show()
	print("FIRE! Rounds remaining: ", rounds)

func _play_out_of_ammo_animation():
	var tween = create_tween()
	tween.tween_property(self, "position", original_position + Vector3(0, -0.1, 0), out_of_ammo_duration / 3)
	tween.tween_callback(hide)
	tween.tween_callback(func():
		position = original_position + Vector3(0, -0.1, 0)
	)
	tween.tween_property(self, "position", original_position, out_of_ammo_duration / 3)
	tween.tween_callback(func():
		$"../..".gun = false
	)
