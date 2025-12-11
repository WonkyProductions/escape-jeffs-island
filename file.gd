extends Sprite2D

var max = 0
var active_files = []
var collected_files = []

func _ready():
	max = Global.files
	_update_visibility()

func _update_active_list():
	active_files = []
	for i in range(Global.files, 0, -1):
		active_files.append(i)
	
	# Track files that were collected (not in active list anymore)
	for i in range(1, max + 1):
		if i not in active_files and i not in collected_files:
			collected_files.append(i)

func _update_visibility():
	_update_active_list()
	var file_number = int(name)
	
	if file_number in active_files:
		# Currently in active list - transparent
		show()
		modulate.a = 0.5
	elif file_number in collected_files:
		# Was collected (was in list at some point) - solid
		show()
		modulate.a = 1
	else:
		# Never been in the list - hidden
		hide()

func _process(delta):
	_update_visibility()
