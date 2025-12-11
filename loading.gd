extends Node2D

var main_scene: Node
var loading_complete: bool = false

func _ready():
	# Keep loading screen visible
	show()
	
	# Load the main scene asynchronously
	ResourceLoader.load_threaded_request("res://main.tscn")
	
	# Wait for loading to complete
	var status = ResourceLoader.load_threaded_get_status("res://main.tscn")
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
		status = ResourceLoader.load_threaded_get_status("res://main.tscn")
	
	# Get the loaded resource
	main_scene = ResourceLoader.load_threaded_get("res://main.tscn").instantiate()
	add_child(main_scene)
	
	# Keep loading screen visible for 3 more seconds
	await get_tree().create_timer(1.0).timeout
	
	# Now hide and remove the loading screen
	$lose_text.hide()
	$black.hide()

func _process(delta):
	pass
