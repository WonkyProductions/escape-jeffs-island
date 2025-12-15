extends CharacterBody2D

@onready var player = $""
var original_scale = scale
func _ready():
	# Start facing front
	$AnimatedSprite2D.play("idleAnim")
 
func _process(delta):
	if player.global_position.x > global_position.x:
		scale.x = original_scale.x
	else:
		scale.x = original_scale.x * -1
