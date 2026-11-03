shader_type canvas_item;

uniform float vignette_intensity : hint_range(0.0, 2.0) = 0.65;
uniform float red_pulse_strength : hint_range(0.0, 0.5) = 0.08;
uniform float scanline_alpha : hint_range(0.0, 0.3) = 0.04;
uniform float time_scale : hint_range(0.1, 5.0) = 1.6;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV;
    vec2 centered = uv - 0.5;
    float dist = length(centered);

    // Emergency LAB-03 red alarm pulse
    float pulse = (sin(TIME * time_scale) * 0.5 + 0.5) * red_pulse_strength;
    // Slight flicker
    float flicker = step(0.985, hash(vec2(floor(TIME * 14.0), 1.0))) * 0.06;

    // Scanline effect
    float scanline = sin(uv.y * 850.0) * scanline_alpha;

    // Dark crimson vignette
    float vig = smoothstep(0.32, 0.88, dist) * vignette_intensity;
    vec3 col = mix(vec3(0.0), vec3(0.55, 0.02, 0.04), pulse + flicker);

    float final_alpha = clamp(vig + pulse * 0.6 + scanline, 0.0, 0.78);
    COLOR = vec4(col, final_alpha);
}
