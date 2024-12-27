shader_type canvas_item;

uniform float strength : hint_range(1, 10) = 2.f;

uniform vec2 p1_center_offset = vec2(0, 0);
uniform bool p2 = false;
uniform vec2 p2_center_offset;
uniform vec2 zoom = vec2(1.f);
uniform vec3 color_conversion = vec3(0.7, 0.7, 0.7);
uniform float vignette_alpha = 1.f;

void fragment() {
	// Reverse the y-coord
	vec2 p1offset = p1_center_offset / (2.f * zoom);
	p1offset.y = -p1offset.y;
	p1offset *= SCREEN_PIXEL_SIZE;
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	
	float zoom_factor = zoom.x * 4.f;
	
	// TODO Add Player 2 position and calculate combined mask for both players

	// Distance from center
	vec2 suv = SCREEN_UV / (SCREEN_PIXEL_SIZE / zoom);
	suv = floor(suv);
	suv *= (SCREEN_PIXEL_SIZE / zoom);
	vec2 p1_center = vec2(0.5) + p1offset * 2.f;
	float p1_dist = distance(suv * vec2(aspect, 1.0), p1_center * vec2(aspect, 1.0)) * zoom_factor;
	
	// Get screen color
	vec4 screen_tex = texture(SCREEN_TEXTURE, SCREEN_UV);
	COLOR = screen_tex;

	// Banding
	int bands = 3;
	float size = strength * 0.1;
	float t = TIME * 5.f;
	float magnitude = 0.003;
	float alpha = 0.5f;
	float size_offset = sin(t) * magnitude;
	vec3 mask = vec3(step(p1_dist, size + size_offset));
	for(int i = 0; i < bands; i++) {
		size_offset = (pow(float(i)/10.f, 0.8f)) + sin(t + 2.f * float(i)) * magnitude;
		mask += vec3(step(p1_dist, size + size_offset)) * alpha;
	}
	mask += vec3(1.f) * alpha * 3.f;
	mask /= (1.f + float(bands + 3) * alpha);
	COLOR.rgb *= mask;
	
	// Vignette
	COLOR.rgb = mix(COLOR.rgb, COLOR.ggg * color_conversion, clamp(2.f * (1.f-mask.r), 0.f, 1.f));
	COLOR.a = vignette_alpha;
}