shader_type canvas_item;
render_mode blend_add;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec3 color_fix = clamp(color.rgb/color.a, 0., 10.);
	COLOR = vec4(color_fix,color.a);
}