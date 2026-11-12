shader_type canvas_item;
// Full-screen PS1-style post effect: snaps the picture to a low-resolution pixel grid, softens
// it a touch, reduces colour depth with the PS1's 4x4 ordered dither (matrix from the PSX
// Animation Library's psx_look addon, CC BY 4.0), then applies a tint, vignette and CRT-style
// colour fringing at the screen edges.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest, repeat_disable;

uniform float lines : hint_range(120.0, 1080.0) = 240.0;
uniform bool dither = true;
uniform int color_bits : hint_range(1, 8) = 5;
uniform float softness : hint_range(0.0, 1.0) = 0.35;
uniform float saturation : hint_range(0.0, 2.0) = 1.0;
uniform vec4 tint : source_color = vec4(1.0);
uniform float vignette : hint_range(0.0, 1.0) = 0.4;
uniform float fringe : hint_range(0.0, 0.02) = 0.004;

const mat4 PS1_DITHER = mat4(
	vec4(-4.0, 2.0, -3.0, 3.0),
	vec4(0.0, -2.0, 1.0, -1.0),
	vec4(-3.0, 3.0, -4.0, 2.0),
	vec4(1.0, -1.0, 0.0, -2.0));

vec3 grab(vec2 uv, vec2 centre_dir, vec2 px) {
	// Red and blue are sampled slightly apart along the line to the screen centre.
	vec2 off = centre_dir * fringe;
	vec2 a = floor(uv / px) * px;
	vec3 c;
	c.r = texture(screen_tex, a + px * 0.5 + off).r;
	c.g = texture(screen_tex, a + px * 0.5).g;
	c.b = texture(screen_tex, a + px * 0.5 - off).b;
	return c;
}

void fragment() {
	vec2 res = vec2(lines / SCREEN_PIXEL_SIZE.x * SCREEN_PIXEL_SIZE.y, lines);
	vec2 px = 1.0 / res;
	vec2 to_centre = SCREEN_UV - vec2(0.5);
	vec2 dir = to_centre * length(to_centre) * 2.0;

	vec3 c = grab(SCREEN_UV, dir, px);
	if (softness > 0.0) {
		vec3 n = grab(SCREEN_UV + vec2(px.x, 0.0), dir, px)
			+ grab(SCREEN_UV - vec2(px.x, 0.0), dir, px)
			+ grab(SCREEN_UV + vec2(0.0, px.y), dir, px)
			+ grab(SCREEN_UV - vec2(0.0, px.y), dir, px);
		c = mix(c, n * 0.25, softness * 0.5);
	}

	c = mix(vec3(dot(c, vec3(0.299, 0.587, 0.114))), c, saturation) * tint.rgb;
	c *= 1.0 - vignette * smoothstep(0.25, 0.85, length(to_centre * vec2(1.0, 0.85)) * 1.4);

	float steps = exp2(float(color_bits));
	float size = 256.0 / steps;
	ivec2 p = ivec2(floor(SCREEN_UV * res)) & ivec2(3);
	float d = dither ? (PS1_DITHER[p.x][p.y] + 0.5) * size / 8.0 : 0.0;
	c = clamp(round((c * 255.0 + d) / 255.0 * (steps - 1.0)), 0.0, steps - 1.0) / (steps - 1.0);
	COLOR = vec4(c, 1.0);
}
