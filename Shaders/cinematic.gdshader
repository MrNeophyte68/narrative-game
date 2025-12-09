shader_type canvas_item;

// --- Chromatic Aberration ---
uniform float aberration_intensity: hint_range(0.0, 5.0, 0.1) = 1.0;
uniform float aberration_threshold: hint_range(0.0, 2.0, 0.1) = 1.0;

// --- Grain ---
uniform float grain_intensity : hint_range(0.0, 1.0) = 0.1;
uniform float min_lum : hint_range(0.0, 1.0) = 0.0;
uniform float max_lum : hint_range(0.0, 1.0) = 1.0;
uniform float time_scale : hint_range(0.0, 1.0) = 0.5;

// --- Vignette ---
uniform float vignette_radius:    hint_range(0.0, 1.0) = 0.22;
uniform float vignette_softness:  hint_range(0.0, 1.0) = 0.38;
uniform float vignette_intensity: hint_range(0.0, 3.0) = 2.00;
uniform float vignette_contrast:  hint_range(0.5, 4.0) = 2.20;
uniform vec4 vignette_color: source_color = vec4(0.0, 0.0, 0.0, 1.0);

// --- Texture ---
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

float vector_angle(vec2 v) {
    if (abs(v.x) < 0.0001 && abs(v.y) < 0.0001) return 0.0;
    return atan(v.y, v.x);
}

vec2 rotate_vector(vec2 v, float cos_theta, float sin_theta) {
    return vec2(
        v.x * cos_theta - v.y * sin_theta,
        v.x * sin_theta + v.y * cos_theta
    );
}

float noise(vec2 p) {
    return (fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * 2.0;
}

vec3 soft_light(vec3 A, vec3 B) {
    vec3 branch1 = 2.0 * A * B + A * A * (1.0 - 2.0 * B);
    vec3 branch2 = 2.0 * A * (1.0 - B) + sqrt(A) * (2.0 * B - 1.0);
    vec3 condition = step(0.5, B);
    return mix(branch1, branch2, condition);
}

void fragment() {
    vec2 uv = SCREEN_UV;

    // --- Chromatic Aberration ---
    vec2 center = vec2(0.5);
    vec2 dir = uv - center;
    float angle = vector_angle(dir);
    float dist = 2.0 * length(dir);
    float effect = exp(aberration_intensity * (dist - aberration_threshold));

    float cos_angle = cos(angle);
    float sin_angle = sin(angle);

    vec2 r_offset = rotate_vector(vec2(-1.0, 0.0) * effect * aberration_intensity, cos_angle, sin_angle);
    vec2 g_offset = vec2(0.0);
    vec2 b_offset = rotate_vector(vec2(1.0, 0.0) * effect * aberration_intensity, cos_angle, sin_angle);

    float r = texture(screen_texture, fma(r_offset, SCREEN_PIXEL_SIZE, uv)).r;
    float g = texture(screen_texture, fma(g_offset, SCREEN_PIXEL_SIZE, uv)).g;
    float b = texture(screen_texture, fma(b_offset, SCREEN_PIXEL_SIZE, uv)).b;
    float a = texture(screen_texture, uv).a;

    vec3 color = vec3(r, g, b);

    // --- Grain ---
    float lum = dot(color, vec3(0.299, 0.587, 0.114));
    float factor = 1.0 - smoothstep(min_lum, max_lum, lum);
    vec2 offset = vec2(sin(TIME * time_scale), cos(TIME * time_scale)) * 20.0;
    vec2 noise_uv = uv + offset;

    float noise_r = noise(noise_uv);
    float noise_g = noise(noise_uv + vec2(0.1, 0.2));
    float noise_b = noise(noise_uv + vec2(0.3, 0.4));
    vec3 grain = vec3(noise_r, noise_g, noise_b) * grain_intensity * factor;

    vec3 grain_color = clamp(vec3(0.5) + grain, 0.0, 1.0);
    color = soft_light(color, grain_color);

    // --- Vignette ---
    vec2 centered = uv - vec2(0.5);
    float edge_box = max(abs(centered.x) * 2.0, abs(centered.y) * 2.0);
    float edge_radial = length(centered) * 2.0;
    float shape = mix(edge_box, edge_radial, 0.25);

    float vignette = smoothstep(vignette_radius, vignette_radius + vignette_softness, shape);
    vignette = pow(vignette, vignette_contrast);
    float vignette_alpha = clamp(vignette * vignette_intensity, 0.0, 1.0);

    color = mix(color, vignette_color.rgb, vignette_alpha);

    COLOR = vec4(color, a);
}