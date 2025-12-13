extends Node3D

@export var min_houses: int = 12
@export var max_houses: int = 18
@export var max_cassettes: int = 10
@export var tree_density: int = 100  # Number of trees to spawn
@export var tree_min_scale: float = 0.8
@export var tree_max_scale: float = 1.2
@export var tree_spawn_range: float = 160.0  # Tree spawn area range (-140 to 140)
@export var house_exclusion_radius: float = 40.0  # Don't spawn trees this close to houses
@export var player_spawn_radius: float = 30.0  # Player spawn zone exclusion radius
@export var house_spawn_offset: float = 20.0  # Offset distance for house spawn animation

var spawn_spots: Array = [
	# Bottom row
	Vector3(-150, 0, -150),  Vector3(-75, 0, -150),   Vector3(0, 0, -150),    Vector3(75, 0, -150),   Vector3(150, 0, -150),
	# Second row
	Vector3(-150, 0, -75),   Vector3(-75, 0, -75),    Vector3(0, 0, -75),     Vector3(75, 0, -75),    Vector3(150, 0, -75),
	# Middle row
	Vector3(-150, 0, 0),     Vector3(-75, 0, 0),      Vector3(0, 0, 0),       Vector3(75, 0, 0),      Vector3(150, 0, 0),
	# Fourth row
	Vector3(-150, 0, 75),    Vector3(-75, 0, 75),     Vector3(0, 0, 75),      Vector3(75, 0, 75),     Vector3(150, 0, 75),
	# Top row
	Vector3(-150, 0, 150),   Vector3(-75, 0, 150),    Vector3(0, 0, 150),     Vector3(75, 0, 150),    Vector3(150, 0, 150),
]

var available_spots: Array = []
var used_spots: Array = []
var final_house_positions: Array = []  # Track final positions for tree spawning

func _ready():
	# Copy spawn spots to available
	available_spots = spawn_spots.duplicate()
	
	# Filter out spots too close to player spawn (0, 0, 0)
	available_spots = available_spots.filter(func(spot): 
		var distance_2d = Vector2(spot.x, spot.z).distance_to(Vector2(0, 0))
		return distance_2d >= player_spawn_radius
	)
	
	# Determine how many houses to spawn (random between min and max)
	var houses_to_spawn = randi_range(min_houses, max_houses)
	
	# Shuffle spawn spots and pick random ones
	available_spots.shuffle()
	
	for i in range(houses_to_spawn):
		if i < available_spots.size():
			var spot = available_spots[i]
			spawn_house_at(spot)
			used_spots.append(spot)
			final_house_positions.append(spot)
	
	# Delete the original house model
	if has_node("house_model"):
		$house_model.queue_free()
	
	# Limit cassettes to max_cassettes
	await get_tree().process_frame  # Wait for houses to be added
	limit_cassettes()
	
	# Spawn trees everywhere except near final house positions
	spawn_trees()

func spawn_house_at(position: Vector3):
	# Duplicate the original house model
	var house = $house_model.duplicate()
	
	# Spawn at offset position
	var random_offset = Vector3(
		randf_range(-house_spawn_offset, house_spawn_offset),
		0,
		randf_range(-house_spawn_offset, house_spawn_offset)
	)
	house.position = position + random_offset
	
	# Random rotation (smooth, not snapped)
	house.rotation.y = randf_range(0, TAU)
	
	# Create a tween to move to final position
	var tween = create_tween()
	tween.tween_property(house, "position", position, 0.5)
	
	add_child(house)

func limit_cassettes():
	# Collect all cassettes from all houses
	var all_cassettes: Array = []
	
	for child in get_children():
		if child.has_node("cassette"):
			all_cassettes.append(child.get_node("cassette"))
	
	# Shuffle the array to randomize which cassettes stay
	all_cassettes.shuffle()
	
	# Keep only max_cassettes, delete the rest
	for i in range(all_cassettes.size()):
		if i >= max_cassettes:
			all_cassettes[i].queue_free()
	
	print("Kept ", min(max_cassettes, all_cassettes.size()), " cassettes out of ", all_cassettes.size())

func spawn_trees():
	if not has_node("tree"):
		print("No tree model found!")
		return
	
	var trees_spawned = 0
	var attempts = 0
	var max_attempts = tree_density * 3  # Try up to 3x the density to account for rejections
	
	while trees_spawned < tree_density and attempts < max_attempts:
		attempts += 1
		
		# Random position in the spawn area (start at y=10)
		var random_pos = Vector3(
			randf_range(-tree_spawn_range, tree_spawn_range),
			10.0,  # Start at y=10
			randf_range(-tree_spawn_range, tree_spawn_range)
		)
		
		# Check if too close to player spawn zone
		var distance_to_player = Vector2(random_pos.x, random_pos.z).distance_to(Vector2(0, 0))
		if distance_to_player < player_spawn_radius:
			continue
		
		# Check if too close to any house (use final_house_positions instead of used_spots)
		var too_close = false
		for house_pos in final_house_positions:
			var distance_2d = Vector2(random_pos.x, random_pos.z).distance_to(Vector2(house_pos.x, house_pos.z))
			if distance_2d < house_exclusion_radius:
				too_close = true
				break
		
		# If valid position, spawn tree
		if not too_close:
			var tree = $tree.duplicate()
			tree.position = random_pos
			
			# Random scale variation
			var scale_factor = randf_range(tree_min_scale, tree_max_scale)
			tree.scale = Vector3(scale_factor, scale_factor, scale_factor)
			
			# Random rotation
			tree.rotation.y = randf_range(0, TAU)
			
			add_child(tree)
			trees_spawned += 1
	
	# Delete the original tree model
	$tree.queue_free()
	
	print("Spawned ", trees_spawned, " trees")

func spawn_house():
	if available_spots.size() == 0:
		print("No available spawn spots!")
		return null
	
	# Pick a random available spot
	var random_index = randi() % available_spots.size()
	var spawn_pos = available_spots[random_index]
	
	# Remove the spot from available
	available_spots.remove_at(random_index)
	
	# Duplicate house at that position
	spawn_house_at(spawn_pos)
	print("House spawned at: ", spawn_pos, " (", available_spots.size(), " spots remaining)")
	return spawn_pos

func get_available_spots_count() -> int:
	return available_spots.size()

func reset_spawn_spots():
	available_spots = spawn_spots.duplicate()
	print("Spawn spots reset!")

#this is the house area 
func _on_area_3d_body_entered(body):
	pass # Replace with function body.
