extends MeshInstance3D

@export var bump_strength: float = 5.0
@export var noise_scale: float = 0.002
@export var large_scale_strength: float = 12.0
@export var edge_falloff: float = 100.0
@export var grass_texture: Texture2D
@export var sand_texture: Texture2D
@export var sand_edge_distance: float = 80.0
@export var vignette_intensity: float = 0.6
@export var splotch_speed: float = 1.5
@export var splotch_size: float = 0.3
@export var enable_fatigue_vignette: bool = true  # Toggle for fatigue vignette effect

var noise: FastNoiseLite
var large_noise: FastNoiseLite
var player: CharacterBody3D
var material: ShaderMaterial
var current_vignette: float = 0.0

func _ready():
	setup_noise()
	subdivide_terrain()
	apply_terrain_effects()
	add_collider()
	player = get_node("../player")

func _process(delta):
	if not player or not material:
		return
	
	# Only update vignette if enabled
	if enable_fatigue_vignette:
		var stamina_ratio = player.stamina / player.max_stamina
		var exhaustion = (1.0 - stamina_ratio) * 1.8
		current_vignette = lerp(current_vignette, exhaustion, 2.0 * delta)
	else:
		current_vignette = lerp(current_vignette, 0.0, 2.0 * delta)
	
	material.set_shader_parameter("dynamic_vignette", current_vignette)

func setup_noise():
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = noise_scale
	noise.fractal_octaves = 8
	noise.fractal_gain = 0.8
	noise.seed = randi()
	
	large_noise = FastNoiseLite.new()
	large_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	large_noise.frequency = noise_scale * 0.1
	large_noise.fractal_octaves = 4
	large_noise.fractal_gain = 0.6
	large_noise.seed = randi()

func subdivide_terrain():
	for i in range(7):
		subdivide_mesh()

func subdivide_mesh():
	var arrays = mesh.surface_get_arrays(0)
	var verts = arrays[Mesh.ARRAY_VERTEX]
	var indices = arrays[Mesh.ARRAY_INDEX]
	
	var new_verts = PackedVector3Array()
	var new_indices = PackedInt32Array()
	var vert_map = {}
	
	for i in range(0, indices.size(), 3):
		var v0 = verts[indices[i]]
		var v1 = verts[indices[i + 1]]
		var v2 = verts[indices[i + 2]]
		
		var i0 = add_unique_vert(v0, new_verts, vert_map)
		var i1 = add_unique_vert(v1, new_verts, vert_map)
		var i2 = add_unique_vert(v2, new_verts, vert_map)
		var i01 = add_unique_vert((v0 + v1) / 2.0, new_verts, vert_map)
		var i12 = add_unique_vert((v1 + v2) / 2.0, new_verts, vert_map)
		var i20 = add_unique_vert((v2 + v0) / 2.0, new_verts, vert_map)
		
		new_indices.append_array([i0, i01, i20, i01, i1, i12, i20, i12, i2, i01, i12, i20])
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for v in new_verts:
		st.add_vertex(v)
	for idx in new_indices:
		st.add_index(idx)
	st.generate_normals()
	mesh = st.commit()

func add_unique_vert(v: Vector3, new_verts: PackedVector3Array, vert_map: Dictionary) -> int:
	var key = str(v)
	if key not in vert_map:
		vert_map[key] = new_verts.size()
		new_verts.append(v)
	return vert_map[key]

func apply_terrain_effects():
	apply_height_variation()
	apply_surface_coloring()
	create_shader()

func apply_height_variation():
	var arrays = mesh.surface_get_arrays(0)
	var verts = arrays[Mesh.ARRAY_VERTEX]
	
	var max_dist = 0.0
	for v in verts:
		max_dist = max(max_dist, sqrt(v.x * v.x + v.z * v.z))
	
	var new_verts = PackedVector3Array()
	for v in verts:
		var height = noise.get_noise_2d(v.x * 10.0, v.z * 10.0) * bump_strength
		height += large_noise.get_noise_2d(v.x, v.z) * large_scale_strength
		
		var falloff = pow(max(0, 1.0 - sqrt(v.x * v.x + v.z * v.z) / max_dist), 2.5)
		new_verts.append(Vector3(v.x, v.y + height * falloff, v.z))
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for v in new_verts:
		st.add_vertex(v)
	var indices = arrays[Mesh.ARRAY_INDEX]
	if indices:
		for idx in indices:
			st.add_index(idx)
	st.generate_normals()
	mesh = st.commit()

func apply_surface_coloring():
	var arrays = mesh.surface_get_arrays(0)
	var verts = arrays[Mesh.ARRAY_VERTEX]
	var indices = arrays[Mesh.ARRAY_INDEX]
	var uvs = PackedVector2Array()
	
	for v in verts:
		uvs.append(Vector2(v.x, v.z) * 0.12)
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	"res://loading.tscn"
	
	for i in range(verts.size()):
		var v = verts[i]
		var dist = sqrt(v.x * v.x + v.z * v.z)
		var jagged_dist = sand_edge_distance + noise.get_noise_2d(v.x * 5.0, v.z * 5.0) * 20.0
		var blend = smoothstep(jagged_dist + 30.0, jagged_dist - 30.0, dist)
		
		var patch_noise = noise.get_noise_2d(v.x * 2.0, v.z * 2.0)
		patch_noise = (patch_noise + 1.0) / 2.0
		if patch_noise > 0.6:
			blend = min(1.0, blend + 0.3)
		
		var darkness = noise.get_noise_2d(v.x * 15.0, v.z * 15.0)
		darkness = (darkness + 1.0) / 2.0
		
		var color_var = noise.get_noise_2d(v.x * 25.0, v.z * 25.0)
		color_var = (color_var + 1.0) / 2.0
		
		st.set_uv(uvs[i])
		st.set_color(Color(darkness, blend, color_var, 1.0))
		st.add_vertex(v)
	
	for idx in indices:
		st.add_index(idx)
	
	st.generate_normals()
	mesh = st.commit()

func create_shader():
	var shader_code = """
shader_type spatial;
render_mode cull_back;

uniform sampler2D grass_tex : hint_default_white;
uniform sampler2D sand_tex : hint_default_white;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.6;
uniform float dynamic_vignette : hint_range(0.0, 1.0) = 0.0;
uniform float splotch_speed : hint_range(0.1, 5.0) = 1.5;
uniform float splotch_size : hint_range(0.1, 1.0) = 0.3;

float noise_3d(vec3 p) {
	return fract(sin(dot(p, vec3(12.9898, 78.233, 45.164))) * 43758.5453);
}

float smoothnoise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	
	float n0 = noise_3d(i);
	float n1 = noise_3d(i + vec3(1.0, 0.0, 0.0));
	float nx0 = mix(n0, n1, f.x);
	
	n0 = noise_3d(i + vec3(0.0, 1.0, 0.0));
	n1 = noise_3d(i + vec3(1.0, 1.0, 0.0));
	float nx1 = mix(n0, n1, f.x);
	
	return mix(nx0, nx1, f.y);
}

void fragment() {
	vec3 grass = texture(grass_tex, UV).rgb;
	vec3 sand = texture(sand_tex, UV).rgb;
	
	float blend = COLOR.g;
	vec3 base_color = mix(sand, grass, blend);
	
	float darkness = COLOR.r;
	float dark_patch = mix(0.6, 1.0, darkness);
	
	float sand_darken = mix(0.8, 1.0, blend);
	float color_variation = COLOR.b;
	float color_shift = mix(0.85, 1.15, color_variation);
	
	vec3 final_color = base_color * dark_patch * sand_darken * color_shift;
	
	// Screen-space fatigue effect
	vec2 vignette_uv = SCREEN_UV - 0.5;
	float dist_from_center = length(vignette_uv);
	
	// Multiple layers of noise for organic fatigue effect
	float fatigue_noise1 = smoothnoise(vec3(vignette_uv * 2.0, TIME * splotch_speed * 0.5));
	float fatigue_noise2 = smoothnoise(vec3(vignette_uv * 5.0, TIME * splotch_speed * 1.3));
	float fatigue_noise3 = smoothnoise(vec3(vignette_uv * 10.0, TIME * splotch_speed * 2.1));
	
	// Combine noises for organic, jittery feeling
	float combined_noise = fatigue_noise1 * 0.5 + fatigue_noise2 * 0.3 + fatigue_noise3 * 0.2;
	combined_noise = mix(0.2, 1.2, combined_noise);
	
	// Edge falloff with smooth distortion
	float edge_dist = dist_from_center * 2.0;
	float vignette_base = 1.0 - edge_dist;
	
	// Apply smooth fatigue-driven edge with subtle variation
	float fatigue_edge = vignette_base * combined_noise;
	fatigue_edge += (smoothnoise(vec3(vignette_uv * 15.0, TIME * splotch_speed)) - 0.5) * splotch_size * 0.15 * dynamic_vignette;
	
	// Soft smoothstep for smooth falloff instead of hard max
	float vignette = smoothstep(-0.2, 0.6, fatigue_edge);
	vignette = mix(1.0, vignette, vignette_intensity + dynamic_vignette * 1.5);
	
	// Add subtle grain to darkened areas that changes smoothly
	float grain = smoothnoise(vec3(FRAGCOORD.xy * 0.5, TIME * 5.0)) * 0.05;
	vignette += grain * (vignette_intensity + dynamic_vignette);
	
	final_color *= vignette;
	
	ALBEDO = final_color;
}
"""
	
	var shader = Shader.new()
	shader.code = shader_code
	
	material = ShaderMaterial.new()
	material.shader = shader
	if grass_texture:
		material.set_shader_parameter("grass_tex", grass_texture)
	if sand_texture:
		material.set_shader_parameter("sand_tex", sand_texture)
	material.set_shader_parameter("vignette_intensity", vignette_intensity)
	material.set_shader_parameter("splotch_speed", splotch_speed)
	material.set_shader_parameter("splotch_size", splotch_size)
	set_surface_override_material(0, material)

func add_collider():
	var static_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = mesh.create_trimesh_shape()
	static_body.add_child(collision_shape)
	add_child(static_body)
