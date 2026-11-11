shader_type canvas_item;
// Grainy greenish security-camera look for the CCTV feed.

uniform vec3 tint = vec3(0.72, 1.0, 0.82);
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.16;
uniform float scanline_count = 180.0;
uniform float vignette : hint_range(0.0, 1.0) = 0.6;
uniform float noise_strength : hint_range(0.0, 0.5) = 0.07;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 col = vec3(g) * tint;
	col *= 1.0 - scanline_strength * (0.5 + 0.5 * sin(UV.y * scanline_count * 6.28318));
	col += (hash(UV * vec2(640.0, 360.0) + fract(TIME) * 10.0) - 0.5) * noise_strength;
	float d = distance(UV, vec2(0.5));
	col *= 1.0 - smoothstep(0.3, 0.85, d) * vignette;
	COLOR = vec4(col, 1.0);
}
