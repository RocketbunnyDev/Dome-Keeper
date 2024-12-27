shader_type canvas_item;

void fragment() {
	vec2 suv = SCREEN_UV;
	vec4 c = texture(TEXTURE, UV);
	vec4 n = texture(NORMAL_TEXTURE, UV);
	suv.x += (n.r - 0.5f) * 0.05;
	suv.y += (n.g - 0.5f) * 0.05;
	vec4 distort = texture(SCREEN_TEXTURE, suv);
	COLOR.rgb = distort.rgb;
	COLOR.a = c.a;
}