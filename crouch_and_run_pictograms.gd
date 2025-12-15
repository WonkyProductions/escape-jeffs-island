extends Sprite2D

var backup = position
var backup_rotation: float = 0.0
var shake_timer: float = 0.0
var shake_interval: float = 0.05  # Adjust this to control speed (lower = faster, higher = slower)

func _ready():
	backup_rotation = rotation
	modulate.a = 0
func _process(delta):
	shake_timer += delta
	
	if shake_timer >= shake_interval:
		position = backup + Vector2(randf_range(-.5, .5), randf_range(-.5, .5))
		rotation = backup_rotation + randf_range(-0.02, 0.02)
		shake_timer = 0.0
	
	if $"..".is_crouching:
		show()
		frame = 0
	elif $"..".is_running:
		show()
		frame = 1
	else:
		hide()
