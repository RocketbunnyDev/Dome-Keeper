shader_type canvas_item;

uniform sampler2D tex_tr;
uniform sampler2D tex_tl;
uniform sampler2D tex_br;
uniform sampler2D tex_bl;

uniform vec2 frame_coords_tl = vec2(1,0);
uniform vec2 frame_coords_tr = vec2(1,0);
uniform vec2 frame_coords_bl = vec2(1,0);
uniform vec2 frame_coords_br = vec2(1,0);
uniform vec2 sheet_size = vec2(12,12);

void fragment() {
	vec2 cell_size = vec2(1.f) / sheet_size;
	vec2 uv_tl = UV;
	vec2 uv_tr = UV + (frame_coords_tr - frame_coords_tl) * cell_size;
	vec2 uv_bl = UV + (frame_coords_bl - frame_coords_tl) * cell_size;
	vec2 uv_br = UV + (frame_coords_br - frame_coords_tl) * cell_size;
	vec4 out_tl = step(uv_tl.y, (frame_coords_tl.y + 0.5)*cell_size.y) * step(uv_tl.x, (frame_coords_tl.x + 0.5)*cell_size.x) * texture(tex_tl, uv_tl);
	vec4 out_tr = step(uv_tr.y, (frame_coords_tr.y + 0.5)*cell_size.y) * step((frame_coords_tr.x + 0.5)*cell_size.x, uv_tr.x) * texture(tex_tr, uv_tr);
	vec4 out_bl = step((frame_coords_bl.y + 0.5)*cell_size.y, uv_bl.y) * step(uv_bl.x, (frame_coords_bl.x + 0.5)*cell_size.x) * texture(tex_bl, uv_bl);
	vec4 out_br = step((frame_coords_br.y + 0.5)*cell_size.y, uv_br.y) * step((frame_coords_br.x + 0.5)*cell_size.x, uv_br.x) * texture(tex_br, uv_br);
	
	COLOR = out_tl + out_tr + out_bl + out_br;
}