shader_type particles;

uniform sampler2D flow;
uniform float scale = 1.0;

// https://thebookofshaders.com/10/
float random (float n) {
	vec2 st = vec2(TIME, n);
    return fract(sin(dot(st.xy,vec2(12.9898,78.233)))*43758.5453123);
}

void vertex() {
	if (RESTART) {
		TRANSFORM[3].x = random(float(INDEX)) * 1280.0 - 640.0;
		TRANSFORM[3].y = 0.0;
		if (random(TRANSFORM[3].x) < 0.5) {
			TRANSFORM[0].x = 0.5;
			TRANSFORM[1].y = 0.5;
		}
		TRANSFORM[0].x *= scale;
		TRANSFORM[1].y *= scale;
		TRANSFORM[0].x = clamp(TRANSFORM[0].x, 0.5, 10.0);
		TRANSFORM[1].y = clamp(TRANSFORM[0].x, 0.5, 10.0);
		VELOCITY.y = random(random(float(INDEX))) * 25.0 + 9.0;
		VELOCITY.y *= scale;
	}
	vec4 f = texture(flow, vec2(TRANSFORM[3].x, TRANSFORM[3].y));
	VELOCITY.x += random(f.r)-0.5;
	VELOCITY.x = clamp(VELOCITY.x, -10.0, 10.0);
}