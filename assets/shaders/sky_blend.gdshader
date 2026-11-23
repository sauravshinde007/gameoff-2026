shader_type sky;
// Cross-fades two equirectangular PSX Sky Sampler panoramas (day/sunset/night) for the
// day-night cycle. Driven by DayNight (scripts/environment/day_night.gd).

uniform sampler2D sky_a : source_color, filter_linear, repeat_enable;
uniform sampler2D sky_b : source_color, filter_linear, repeat_enable;
uniform float blend : hint_range(0.0, 1.0) = 0.0;
uniform float energy = 1.0;

void sky() {
	vec3 a = texture(sky_a, SKY_COORDS).rgb;
	vec3 b = texture(sky_b, SKY_COORDS).rgb;
	COLOR = mix(a, b, blend) * energy;
}
