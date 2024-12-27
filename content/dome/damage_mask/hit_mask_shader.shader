shader_type canvas_item;

uniform float damage : hint_range(0, 1) = 0;
// The viewport texture that contains all enemy hits
uniform sampler2D impact_mask;
// A gradient texture that defines the growth direction of the cracks
uniform sampler2D cracks_mask;
// The noise texture makes sure the cracks don't grow too uniformly without the hassle of making very detailed gradient cracks masks
uniform sampler2D noise_texture;

uniform sampler2D palette;
const float start_r = 0.5 / float(32);
const float start_b = 0.5 / float(12);

void fragment() {
	// Pixellate UV
	vec2 grid_uv = UV / TEXTURE_PIXEL_SIZE;
	grid_uv = floor(grid_uv);
	grid_uv *= TEXTURE_PIXEL_SIZE;

	float cm = step(1.f - damage, texture(cracks_mask, grid_uv).r * texture(noise_texture, grid_uv).r);
	float im = step(0.4f, texture(impact_mask, grid_uv).r);
	vec4 input = texture(TEXTURE, grid_uv);
	vec4 output = texture(palette, vec2(start_r + input.r, start_b+input.b));
	output.a = input.a;
	
	COLOR = mix(vec4(0.f), output, clamp(cm+im, 0, 1));
}