shader_type spatial;
render_mode cull_front, depth_test_disabled, unshaded;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 0.0, 1.0);
uniform float outline_width : hint_range(0.0, 0.1) = 0.02;

void vertex() {
    // Expand mesh along normals in view space
    vec4 clip_pos = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
    vec4 normal_clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(NORMAL, 0.0);
    
    vec2 offset = normalize(normal_clip.xy) * outline_width * clip_pos.w;
    clip_pos.xy += offset;
    
    POSITION = clip_pos;
}

void fragment() {
    ALBEDO = outline_color.rgb;
    ALPHA = outline_color.a;
}