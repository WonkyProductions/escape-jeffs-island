shader_type canvas_item;

uniform float outline_width : hint_range(0.0, 10.0) = 2.0;
uniform vec4 outline_color = vec4(1.0, 1.0, 1.0, 1.0);

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Sample the texture at the current UV
	vec4 original_color = texture(TEXTURE, UV);

	// Sample neighboring pixels to detect edges
	vec2 pixel_size = 1.0 / TEXTURE_PIXEL_SIZE;
	float outline = 0.0;

	// Check alpha in neighboring pixels
	for(float x = -outline_width; x <= outline_width; x++) {
		for(float y = -outline_width; y <= outline_width; y++) {
			vec2 offset_uv = UV + vec2(x, y) * pixel_size;
			float neighbor_alpha = texture(TEXTURE, offset_uv).a;

			// If original is transparent but neighbor isn't, we're at an edge
			if(original_color.a < 0.5 && neighbor_alpha > 0.5) {
				outline = 1.0;
			}
		}
	}

	// Blend outline with original color
	vec4 final_color = mix(original_color, outline_color, outline * (1.0 - original_color.a));
	COLOR = final_color;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}