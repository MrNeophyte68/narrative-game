shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

/* RADIAL BLUR */
uniform vec2 blur_center = vec2(0.5, 0.5);
uniform float blur_power : hint_range(0.0, 0.2) = 0.04;
uniform int sampling_count : hint_range(1, 64) = 12;
uniform float radial_intensity : hint_range(0.0, 3.0) = 1.2;

/* RGB CHAOS */
uniform float chaos : hint_range(0.0, 32.0) = 1.0;
uniform float chaos_radius : hint_range(0.0, 1.0) = 0.5;
uniform float chaos_attenuation : hint_range(1.0, 5.0) = 2.0;

/* NEW: shake intensity */
uniform float chaos_shake_intensity : hint_range(0.0, 5.0) = 1.0;

varying vec2 amount_r;
varying vec2 amount_g;
varying vec2 amount_b;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453) - 0.5;
}

void vertex() {
	vec2 shifted_uv = (UV * 2.0) - 1.0;

	amount_r = normalize(vec2(
		rand(TIME * 1.3 * shifted_uv),
		rand(TIME * 1.64 * shifted_uv)
	));

	amount_g = normalize(vec2(
		rand(TIME * 1.5 * shifted_uv),
		rand(TIME * 1.7 * shifted_uv)
	));

	amount_b = normalize(vec2(
		rand(TIME * 1.17 * shifted_uv),
		rand(TIME * 1.23 * shifted_uv)
	));
}

void fragment() {

	/* -------- Radial Blur (Weighted) -------- */
	vec2 dir = SCREEN_UV - blur_center;
	vec3 blur_color = vec3(0.0);
	float total_weight = 0.0;

	for (int i = 0; i < sampling_count; i++) {
		float t = float(i) / float(sampling_count);
		float weight = 1.0 - t;

		vec2 offset_uv = SCREEN_UV - dir * blur_power * t;
		blur_color += texture(SCREEN_TEXTURE, offset_uv).rgb * weight;
		total_weight += weight;
	}

	blur_color = (blur_color / total_weight) * radial_intensity;

	/* -------- RGB Chaos (with shake intensity) -------- */
	vec2 chaos_v = vec2(chaos, -chaos) * SCREEN_PIXEL_SIZE;

	float dist = length((UV - vec2(0.5)) * 2.0);
	float att = clamp(dist / chaos_radius, 0.0, 1.0);
	chaos_v *= 1.0 - pow(att, chaos_attenuation);

	/* Apply shake intensity here */
	vec2 r_off = chaos_v * amount_r * chaos_shake_intensity;
	vec2 g_off = chaos_v * amount_g * chaos_shake_intensity;
	vec2 b_off = chaos_v * amount_b * chaos_shake_intensity;

	vec3 chaos_color;
	chaos_color.r = texture(SCREEN_TEXTURE, SCREEN_UV + r_off).r;
	chaos_color.g = texture(SCREEN_TEXTURE, SCREEN_UV + g_off).g;
	chaos_color.b = texture(SCREEN_TEXTURE, SCREEN_UV + b_off).b;

	/* -------- Final Composite -------- */
	COLOR.rgb = mix(blur_color, chaos_color, 0.35);
	COLOR.a = 1.0;
}