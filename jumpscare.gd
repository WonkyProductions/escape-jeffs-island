extends Sprite2D

@export var shake_duration: float = 2.0
@export var shake_intensity: float = 10.0
@export var shake_speed: float = 90.0

var shake_timer: float = 0.0
var initial_position: Vector2

func _ready():
	show()
	initial_position = position
	shake_timer = shake_duration
	$"../scream".play()
	$"../AnimationPlayer".play("jumpscare")
	await get_tree().create_timer(3).timeout
	get_tree().change_scene_to_file("res://lose.tscn")
	$"..".queue_free()
	
func _process(delta):
	
	if shake_timer > 0:
		shake_timer -= delta
		
		# Calculate shake amount (decreases over time)
		var shake_progress = 1.0 - (shake_timer / shake_duration)
		var current_intensity = shake_intensity * (1.0 - shake_progress)
		
		# Oscillate up and down
		var shake_offset = sin(shake_timer * shake_speed) * current_intensity
		position = initial_position + Vector2(0, shake_offset)
	else:
		# Return to initial position when shake is done
		
		position = initial_position
