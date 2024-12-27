shader_type canvas_item;
render_mode blend_mix;

uniform vec2 base_scale = vec2(1.0, 1.0);

uniform sampler2D palette;

uniform vec4 ground_color : hint_color;
const float start_r = 0.5 / 32.0;
const float start_b = 0.5 / 12.0;
uniform float grad_length = 100.0;
uniform float u_grad_offset = -12.0;

uniform sampler2D mask_map;
uniform sampler2D cave_map;
uniform sampler2D light_map;
uniform sampler2D bg_alpha_map;
uniform sampler2D mask_noise_map;
uniform sampler2D mask_noise_big_map;
uniform sampler2D small_stone_map;
uniform sampler2D biome_color_map;

uniform sampler2D background_rocks;
uniform float rock_cave_mask_factor = 1.0;

uniform float noise_power;
uniform float noise_power_big;
uniform float line_scale;
uniform float edge_pos = 0.7;
uniform float top_shadow_displace = 0.7;
uniform float shadow_edge = 0.7;
uniform float alpha_edge_pos = 0.7;
uniform float background_darkening = 0.8;
uniform float cave_blur_factor = .75;

uniform sampler2D cave_noise_map_l;
uniform sampler2D cave_noise_map_holes;
uniform sampler2D cave_noise_map_s;
uniform float cave_noise_balance_l = 0.5;
uniform float cave_noise_balance_s = 0.5;
uniform float cave_noise_balance_h = 0.5;
uniform float cave_noise_power = 0.5;
uniform float cave_noise_step = 0.5;
uniform float cave_hole_factor = 0.5;
uniform float cave_step_1 = 0.5;
uniform float cave_step_2 = 0.5;
uniform float small_highlight_factor = 0.5;
uniform vec4 main_color : hint_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform vec4 edge_color : hint_color = vec4(1.0, 0.0, 0.0, 1.0);

float make_outline(vec2 s, sampler2D mm, vec2 uv) {
	float outline = texture(mm, uv + vec2(-s.x, 0)).r;
	outline += texture(mm, uv + vec2(s.x, 0)).r;
	outline += texture(mm, uv + vec2(0, s.y)).r;
	outline += texture(mm, uv + vec2(0, -s.y)).r;
	outline += texture(mm, uv + vec2(-s.x, s.y)).r;
	outline += texture(mm, uv + vec2(s.x, s.y)).r;
	outline += texture(mm, uv + vec2(-s.x, -s.y)).r;
	outline += texture(mm, uv + vec2(s.x, -s.y)).r;
	return outline;
}

void fragment() {
	vec2 SCALED_UV = UV*base_scale;
	
	float mask_noise = texture(mask_noise_map, SCALED_UV).r-0.5;
	vec2 displaced_uv = mix(UV, UV+mask_noise, noise_power);
	float mask = abs(texture(mask_map, displaced_uv).r - 1.0);
	
	// Fog Noise
	float mask_noise_big = texture(mask_noise_big_map, SCALED_UV).r-0.5;
	vec2 displaced_bigger_uv = mix(UV, UV+mask_noise_big, noise_power_big);
	vec4 stone_color = texture(biome_color_map, displaced_bigger_uv)*background_darkening;
	vec4 dark_stone_color = stone_color*0.85;
	
	// Calculate the cave hole mask
	float cave_noise_s = mix(0.0, texture(cave_noise_map_s, SCALED_UV).r, cave_noise_balance_s)-0.5;
	vec2 cave_map_uv_s = mix(SCALED_UV, SCALED_UV + cave_noise_s, cave_noise_power);
	float cave_noise_l = mix(0.0, texture(cave_noise_map_l, cave_map_uv_s).r, cave_noise_balance_l)-cave_noise_balance_l*0.5;
	vec2 cave_map_uv_l = mix(UV, UV + cave_noise_l, cave_noise_power);
	float cave_noise_holes = mix(texture(cave_noise_map_holes, cave_map_uv_l+0.5).g, 0.0, cave_noise_balance_h);
	vec3 cave_map_blur = (textureLod(cave_map, cave_map_uv_l, cave_blur_factor) + texture(cave_map, cave_map_uv_l)).rgb*0.5;
	float no_cave_zone = (cave_map_blur.g + cave_map_blur.r + cave_map_blur.b*0.3)*0.6;
	
	// Basic decorative background caves are created.
	float rock_cave_mask = texture(background_rocks, UV).r * rock_cave_mask_factor;
	float base_cave = (cave_noise_holes * cave_hole_factor) + no_cave_zone - (rock_cave_mask * cave_noise_holes);
	float cave_mask = abs(1.0 - step(cave_noise_step, base_cave));
	float cave_mask_inner = abs(1.0 - step(cave_step_1, base_cave));
	float cave_mask_outline = abs(1.0 - step(cave_step_2, base_cave));
	
	// Additional caves (like teleporter, mushroom and what have you) get added to the base background caves
	// To integrate them better into the background.
	vec4 alpha_noised_px = texture(bg_alpha_map, displaced_bigger_uv);
	cave_mask = min(1.0, cave_mask + step(0.02, alpha_noised_px.r));
	cave_mask_inner = min(1.0, cave_mask_inner + step(0.4, alpha_noised_px.r));
	cave_mask_outline = min(1.0, cave_mask_outline + step(0.01, alpha_noised_px.r));
	
	float cave_just_outline = cave_mask_outline-cave_mask;
	
	vec2 line_size = TEXTURE_PIXEL_SIZE * line_scale;
	float outline = make_outline(line_size, mask_map, displaced_uv);
	outline = step(edge_pos, clamp(outline, 0.0, 10.0)/10.0);
	
	vec2 displaced_uv_soft = mix(UV, UV+mask_noise, noise_power*0.1);
	vec2 top_displace = vec2(0, top_shadow_displace * line_size.y);
	float top_shadow = step(texture(mask_map, displaced_uv_soft+top_displace).r, shadow_edge);
	
	vec4 light_px = texture(light_map, UV);
	float lit_shadow = mix(top_shadow, 0.0, light_px.a);
	
	float small_stone_highlights = step(small_highlight_factor, texture(small_stone_map, SCALED_UV*2.0).r);
	
	vec3 small_stone_color = mix(stone_color.rgb, light_px.rgb, max(light_px.a-0.9, 0.0));
	COLOR.rgb = mix(mix(mix(dark_stone_color.rgb, stone_color.rgb, outline), small_stone_color, small_stone_highlights), dark_stone_color.rgb, cave_mask);
	COLOR.rgb = mix(COLOR.rgb, dark_stone_color.rgb, lit_shadow);
	COLOR.rgb = mix(COLOR.rgb, dark_stone_color.rgb, cave_mask);
	COLOR.rgb = mix(COLOR.rgb, dark_stone_color.rgb*0.8, cave_mask_inner);
	COLOR.rgb = mix(COLOR.rgb, mix(dark_stone_color.rgb, light_px.rgb, max(light_px.a-0.9, 0.0)), cave_just_outline);
	
	// The alpha map created from the additional background elements (mushroom caves etc.)
	float alpha_px = texture(bg_alpha_map, UV).r;
	COLOR.a = max(abs(1.0-step(texture(mask_map, UV).r, alpha_edge_pos)) - step(0.99, alpha_px), 0.0);
	
	float g_offset = TEXTURE_PIXEL_SIZE.y*u_grad_offset;
	float g_length = TEXTURE_PIXEL_SIZE.y*grad_length;
	vec4 bg_color = texture(palette, vec2(start_r + ground_color.r, start_b + ground_color.b));
	vec3 grad_color = bg_color.rgb * (1.0 - smoothstep(0.0, 1.5, ((UV.y+g_offset)/g_length) ));
	
	COLOR.rgb += grad_color*1.5;
}
