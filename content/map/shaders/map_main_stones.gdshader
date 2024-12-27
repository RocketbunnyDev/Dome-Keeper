shader_type canvas_item;
render_mode blend_mix;

uniform vec2 base_scale = vec2(1.0, 1.0);

uniform sampler2D palette;

uniform vec4 ground_color : hint_color;
const float start_r = 0.5 / 32.0;
const float start_b = 0.5 / 12.0;
uniform float grad_length = 100.0;
uniform float u_grad_offset = -12.0;

uniform sampler2D crack_impact;
uniform sampler2D mask_map;
uniform sampler2D light_map;
uniform sampler2D rock_falloff_map;
uniform sampler2D damage_map;
uniform sampler2D damage_mask_map;
uniform sampler2D cracks_tiled_map;
uniform sampler2D biome_color_map;
uniform sampler2D mask_noise_map;
uniform sampler2D mask_noise_factor_map;
uniform sampler2D mask_noise_big_map;

uniform float edge_straightness_factor = 0.5;
uniform float noise_power;
uniform float noise_power_big;

// Main Edge outline (light catcher)
uniform float outline_scale;
uniform float outline_pos = 0.221;
uniform float outline_edge_pos = 0.7;

// Inner Edge (stone color)
uniform float edgecol_scale;
uniform float edgecol_hardness_factor;
uniform float edgecol_edge_pos = 0.7;

// Fog Edge
uniform float shadow_pos = 0.7;
uniform float shadow_pos_small = 0.7;
uniform float falloff_mix_factor = 0.5;
uniform float falloff_mix_factor_2 = 0.5;

uniform vec4 lightblocker_col : hint_color;

uniform float temp_damage_step_c = 0.5;
uniform float temp_damage_step_s = 0.5;
uniform float temp_damage_step_a = 0.5;
uniform float temp_damage_mult_a = 0.5;


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
	// Base noise (small noise) that is used for the inner edge of the tunnel
	float mask_noise = texture(mask_noise_map, SCALED_UV).r-0.5;
	float edge_straightness = step(pow(texture(mask_noise_factor_map, UV).r, 2.0), edge_straightness_factor);
	vec2 displaced_uv = mix(UV, UV+mask_noise, noise_power * edge_straightness);
	
	// Light Catcher outline
	vec2 line_size = TEXTURE_PIXEL_SIZE * outline_scale;
	float outline = step(outline_edge_pos, make_outline(line_size, mask_map, displaced_uv));
	
	// Stone Color outline
	float hardness_edge_size = texture(mask_noise_factor_map, UV).g * edgecol_hardness_factor;//max(pow(texture(mask_noise_factor_map, UV).g, 2.0), 0.0) * edgecol_hardness_factor;
	vec2 edge_size = TEXTURE_PIXEL_SIZE * (edgecol_scale + hardness_edge_size);
	float edge_line = step(edgecol_edge_pos, make_outline(edge_size, mask_map, displaced_uv));
	
	// Main big noise
	float mask_noise_big = texture(mask_noise_big_map, SCALED_UV).r-0.5;
	vec2 displaced_bigger_uv = mix(UV, UV+mask_noise_big, noise_power_big);
	
	// Stone color based on the Maps biome color setting using the big noise for the transition
	vec3 stone_color = texture(biome_color_map, displaced_bigger_uv).rgb;
	float hardness_map = texture(mask_noise_factor_map, displaced_bigger_uv).g;
	
	// This falloff is used for the shadow fadeout and rock shape falloff.
	float falloff_map = texture(rock_falloff_map, displaced_bigger_uv).r;
	float falloff_map_x2 = texture(rock_falloff_map, displaced_bigger_uv + (TEXTURE_PIXEL_SIZE*12.0)).g;
	float adapted_falloff_mix_factor = mix(falloff_mix_factor, falloff_mix_factor_2, hardness_map);
	float mixed_falloff = mix(falloff_map, falloff_map_x2, adapted_falloff_mix_factor);
//	mixed_falloff = clamp(mixed_falloff-abs(1.0-min(hardness_map*shadow_hardness_multiplier, 1.0)), 0.0, 1.0);
	
	// The color of the Lightedge
	vec4 light_px = texture(light_map, UV);
	vec3 light_color = mix(stone_color*1.3, light_px.rgb, light_px.a);
	
	// Creating a float that is used to set the alpha for the stones
	float stone_paint = 0.0;
	vec3 color = texture(TEXTURE, UV).rgb;
	stone_paint += mix(color.b, 0.0, step(mixed_falloff, 0.01));
	stone_paint += mix(color.g, 0.0, step(mixed_falloff, 0.3));
	stone_paint += mix(color.r, 0.0, step(mixed_falloff, 0.6));
	stone_paint = min(stone_paint, 1.0);
	
	// Tunnel cutout is used to remove the alpha where the tunnel is dug
	float mask = abs(texture(mask_map, displaced_uv).r - 1.0);
	float tunnel_cutout = step(outline_pos, mask);
	
	// Generate the "shadow" fadeout of the stones.
	float shadow = step(shadow_pos, mixed_falloff);
	float shadow_small = step(shadow_pos_small, mixed_falloff);
	
	float alpha = clamp((stone_paint + outline + edge_line) * tunnel_cutout, 0.0, 1.0) * shadow;
	
	// Colors are combined, the lit edge and the main stone color (from biome)
	vec3 stone_color_combined = mix(stone_color.rgb*0.5, stone_color.rgb, shadow_small);
	vec3 final_color = mix(stone_color_combined, light_color, outline);
	
	// Putting together the damage map
	vec2 px = TEXTURE_PIXEL_SIZE * vec2(12.0);
	float da = texture(damage_mask_map, UV).a;
	float dc = texture(damage_map, UV).b;
	float dx = texture(damage_map, UV + vec2(px.x, 0.0)).r;
	float dy = texture(damage_map, UV + vec2(0.0, px.y)).g;
	float damage_value = clamp(step(temp_damage_step_c, dc) + step(temp_damage_step_s, dx+dy) - temp_damage_step_a, 0.0, 1.0);
	
	// this could be pre-calculated to save some shader calc time.
	vec2 tex_uv = vec2(textureSize(cracks_tiled_map, 0)) / vec2(textureSize(TEXTURE, 0));
	damage_value = mix(0.0, damage_value, texture(cracks_tiled_map, UV/tex_uv).a);
	
	vec3 stone_color_inv = mix(mix(stone_color.rgb, stone_color*1.3, shadow_small), stone_color.rgb*0.5, outline+edge_line);
	stone_color_inv = mix(stone_color_inv, vec3(1.0), texture(crack_impact, UV).r);
	
	float visible_area = min(alpha + (damage_value * tunnel_cutout * shadow), 1.0);
	COLOR.rgb = mix(vec3(0.0), mix(final_color, stone_color_inv, damage_value), visible_area);
	COLOR.a = tunnel_cutout;
	
	float g_offset = TEXTURE_PIXEL_SIZE.y*u_grad_offset;
	float g_length = TEXTURE_PIXEL_SIZE.y*grad_length;
	vec4 bg_color = texture(palette, vec2(start_r + ground_color.r, start_b + ground_color.b));
	vec3 grad_color = bg_color.rgb * (1.0 - smoothstep(0.0, 1.5, ((UV.y+g_offset)/g_length) ));
	
	COLOR.rgb += grad_color;
}
