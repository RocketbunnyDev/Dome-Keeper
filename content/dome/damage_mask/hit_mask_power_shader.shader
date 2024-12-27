/*
This shader improves the growth rate of the cracks. It adjusts the curve of the gradient in the texture,
extremer curve means longer growth time.
*/
shader_type canvas_item;
render_mode blend_add;

uniform float power : hint_range(1, 10) = 1.f;

void fragment() {
	// Pixellate UV
	vec2 grid_uv = UV / TEXTURE_PIXEL_SIZE;
	grid_uv = floor(grid_uv);
	grid_uv *= TEXTURE_PIXEL_SIZE;

	COLOR = texture(TEXTURE, grid_uv);
	COLOR.a = pow(COLOR.a, power);
}