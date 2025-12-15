extends Node2D

@export var fade_in_duration: float = 0.2
@export var linger_duration: float = 1.3
@export var fade_out_duration: float = 0.2
@onready var backup_text = $lose_text.text
var elapsed_time: float = 0.0
var total_duration: float = 0.0
var state: String = "idle"  # "idle", "fade_in", "linger", "fade_out"


func _ready():
	modulate.a = 0.0
	total_duration = fade_in_duration + linger_duration + fade_out_duration

func start():
	state = "fade_in"
	elapsed_time = 0.0
	modulate.a = 0.0


func _process(delta):
	if state == "idle":
		return
	
	elapsed_time += delta
	
	if state == "fade_in":
		if elapsed_time <= fade_in_duration:
			modulate.a = elapsed_time / fade_in_duration
		else:
			modulate.a = 1.0
			state = "linger"
			elapsed_time = 0.0
	
	elif state == "linger":
		if elapsed_time <= linger_duration:
			modulate.a = 1.0
		else:
			state = "fade_out"
			elapsed_time = 0.0
	
	elif state == "fade_out":
		if elapsed_time <= fade_out_duration:
			modulate.a = 1.0 - (elapsed_time / fade_out_duration)
		else:
			modulate.a = 0.0
			state = "idle"
			$lose_text.text = backup_text
