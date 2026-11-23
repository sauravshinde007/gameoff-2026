shader_type spatial;
// Hover outline for interactables (inverted hull). Applied as material_overlay:
// the mesh is redrawn with front faces culled and pushed out along its normals,
// so only a rim around the silhouette shows. Width is in screen pixels.
render_mode unshaded, cull_front, shadows_disabled, fog_disabled;

uniform vec3 outline_color : source_color = vec3(1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 3.0;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 view_normal = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec2 dir = (PROJECTION_MATRIX * vec4(view_normal, 0.0)).xy;
	if (length(dir) > 0.0001) {
		dir = normalize(dir);
	}
	clip.xy += dir * outline_width * 2.0 / VIEWPORT_SIZE * clip.w;
	POSITION = clip;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
