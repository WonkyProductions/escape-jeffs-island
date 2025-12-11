extends Camera3D

var bob_amount = 0.1
var bob_speed = 1.0
var time_elapsed = 0.0
var start_position = Vector3.ZERO

func _ready():
	start_position = position

func _process(delta):
	time_elapsed += delta
	var bob_offset = sin(time_elapsed * bob_speed) * bob_amount
	position.y = start_position.y + bob_offset
