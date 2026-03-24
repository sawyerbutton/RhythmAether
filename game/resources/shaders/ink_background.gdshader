shader_type canvas_item;

uniform float time_scale : hint_range(0.01, 1.0) = 0.15;
uniform float beat_pulse : hint_range(0.0, 2.0) = 0.0;
uniform vec4 base_color : source_color = vec4(0.102, 0.102, 0.18, 1.0);
uniform vec4 ink_color : source_color = vec4(0.91, 0.27, 0.37, 1.0);
uniform vec4 deep_color : source_color = vec4(0.06, 0.21, 0.38, 1.0);

// Simplex-like noise
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

void fragment() {
    vec2 uv = UV;
    float t = TIME * time_scale;

    // Flowing ink patterns
    float n1 = fbm(uv * 3.0 + vec2(t * 0.3, t * 0.2));
    float n2 = fbm(uv * 5.0 + vec2(-t * 0.2, t * 0.4) + n1 * 0.5);
    float n3 = fbm(uv * 2.0 + vec2(t * 0.1, -t * 0.15) + n2 * 0.3);

    // Combine layers
    float ink = smoothstep(0.3, 0.7, n2) * 0.15;
    float deep = smoothstep(0.4, 0.6, n3) * 0.1;

    // Beat reactive: pulse ink brightness
    ink += beat_pulse * 0.08 * smoothstep(0.2, 0.8, n1);
    deep += beat_pulse * 0.05;

    // Vignette (darker at edges)
    float vignette = 1.0 - length(uv - 0.5) * 0.8;
    vignette = clamp(vignette, 0.0, 1.0);

    // Top-to-bottom gradient (slightly lighter at top for depth)
    float gradient = mix(1.0, 0.85, uv.y);

    // Final color
    vec3 col = base_color.rgb * gradient * vignette;
    col += ink_color.rgb * ink;
    col += deep_color.rgb * deep;

    COLOR = vec4(col, 1.0);
}
