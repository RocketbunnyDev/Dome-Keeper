shader_type canvas_item;

void fragment() {
	// https://en.wikipedia.org/wiki/Blend_modes
	
	vec4 fg = texture(TEXTURE, UV);
	vec4 bg = texture(SCREEN_TEXTURE, SCREEN_UV);

	COLOR.rgb = bg.rgb / (vec3(1.0)-fg.rgb);
}