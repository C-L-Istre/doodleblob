shader_type canvas_item;

uniform float fade_alpha : hint_range(0.0, 1.0) = 1.0;
uniform float split_y : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec4 color = texture(TEXTURE, UV);

	if (UV.y < split_y) {
		color.a *= fade_alpha;
	}

	COLOR = color;
}