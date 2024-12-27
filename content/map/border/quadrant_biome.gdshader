shader_type canvas_item;

uniform sampler2D tex_tr;
uniform sampler2D tex_tl;
uniform sampler2D tex_br;
uniform sampler2D tex_bl;

uniform vec2 frame_coords = vec2(1,0);
uniform vec2 sheet_size = vec2(12,12);

vec2 get_pixel_uv(vec2 uv, vec2 texture_pixel_size) {
	uv /= texture_pixel_size;
	uv = floor(uv);
	uv *= texture_pixel_size;
	return uv;
}

void fragment() {
	vec2 pixel_uv = get_pixel_uv(UV, TEXTURE_PIXEL_SIZE);
	
	vec2 cell_size = vec2(1.f) / sheet_size;
	vec4 out_tl = step(UV.y, (frame_coords.y + 0.5)*cell_size.y) * step(UV.x, (frame_coords.x + 0.5)*cell_size.x) * texture(tex_tl, UV);
	vec4 out_tr = step(UV.y, (frame_coords.y + 0.5)*cell_size.y) * step((frame_coords.x + 0.5)*cell_size.x, UV.x) * texture(tex_tr, UV);
	vec4 out_br = step((frame_coords.y + 0.5)*cell_size.y, UV.y) * step((frame_coords.x + 0.5)*cell_size.x, UV.x) * texture(tex_br, UV);
	vec4 out_bl = step((frame_coords.y + 0.5)*cell_size.y, UV.y) * step(UV.x, (frame_coords.x + 0.5)*cell_size.x) * texture(tex_bl, UV);
	
	COLOR = out_tl + out_tr + out_bl + out_br;
}