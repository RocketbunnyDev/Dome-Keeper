shader_type canvas_item;

uniform sampler2D noise_texture;
uniform sampler2D fade_mask;
uniform float speed = 0.1;
uniform float border1 = 0.9;
uniform float border2 = 0.6;
uniform float mask_factor = 0.6;
uniform vec2 coord;

void fragment() {
	// Pixellate UV
	vec2 grid_uv = UV / TEXTURE_PIXEL_SIZE;
	grid_uv = floor(grid_uv);
	grid_uv *= TEXTURE_PIXEL_SIZE;
	
	// Build noise
	float scroll = TIME * speed;
	vec2 lookup_uv = grid_uv + coord * (1.0 / 36.0); // Use global coordinate to make each one unique
	float noise_1 = texture(noise_texture, vec2(lookup_uv.x + scroll, lookup_uv.y)).r;
	float noise_2 = texture(noise_texture, vec2(lookup_uv.x - scroll, lookup_uv.y + 0.25)).r;
	float noise = (noise_1+noise_2)*0.5;
	
	// Output
	vec4 tex = texture(TEXTURE, grid_uv);
	vec4 mask = texture(fade_mask, grid_uv);
	COLOR.rgb = tex.rgb;
	COLOR.a = clamp(1.0 - mask.r*0.7 - mask.r*noise*2.0, 0.0, 1.0); // outer border
//	COLOR.rgb *= UV.x*0.5 + (0.5-UV.x*0.5)*step(mask.r, noise - border2); // inner border
	COLOR.a = min(COLOR.a, 1.0);
}