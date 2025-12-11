shader_type canvas_item;

uniform vec4 color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	COLOR = vec4(color.rgb, tex.a);
}