shader_type spatial;
// Mirror surface. Shows the reflection camera's SubViewport, flipped left/right (the reflection
// camera's right is the mirror's left). When the mirror is idle it shows a dull dark glass.
render_mode unshaded, cull_back, shadows_disabled;

uniform sampler2D reflection : source_color, filter_nearest;
uniform vec4 tint : source_color = vec4(0.88, 0.92, 0.9, 1.0);
// Colour shown while the reflection is not being rendered.
uniform vec4 idle_color : source_color = vec4(0.08, 0.09, 0.09, 1.0);
uniform float active = 1.0;
// Darkens the edges a little, like old silvering.
uniform float edge_darken = 0.35;

void fragment() {
	vec3 refl = texture(reflection, vec2(1.0 - UV.x, UV.y)).rgb * tint.rgb;
	vec2 e = abs(UV - 0.5) * 2.0;
	float vignette = 1.0 - edge_darken * pow(max(e.x, e.y), 4.0);
	ALBEDO = mix(idle_color.rgb, refl, active) * vignette;
}
