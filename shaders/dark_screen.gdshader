shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float brightness : hint_range(0.0, 2.0) = 0.0;
uniform float darkness : hint_range(0.0, 1.0) = 0.0;
uniform float saturation : hint_range(0.0, 2.0) = 1.0;

uniform float vignette_strength : hint_range(0.0, 2.0) = 0.75;
uniform float vignette_softness : hint_range(0.01, 2.0) = 0.5;

uniform vec2 center = vec2(0.5, 0.5);

void fragment()
{
    vec4 screen_color = texture(screen_texture, SCREEN_UV);
    vec3 color = screen_color.rgb;

    // --- SATURATION ---
    float luminance = dot(color, vec3(0.299, 0.587, 0.114));
    vec3 grayscale = vec3(luminance);
    color = mix(grayscale, color, saturation);

    // --- DISTANCE FROM CENTER ---
    float dist = distance(SCREEN_UV, center);

    // --- DARKNESS VIGNETTE (stronger at edges) ---
    float edge_vignette = smoothstep(
        vignette_strength - vignette_softness,
        vignette_strength,
        dist
    );
    color = mix(color, vec3(0.0), darkness * edge_vignette * 1.3); 
    // 1.3 = extra darkening at edges

    // --- BRIGHTNESS (stronger in center) ---
    float center_vignette = 1.0 - edge_vignette; // invert
    color = mix(color, vec3(1.0), brightness * center_vignette);

    COLOR = vec4(color, screen_color.a);
}





