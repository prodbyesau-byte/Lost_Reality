shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;
uniform vec4 stain_color : source_color = vec4(0.18,0.20,0.15,1.0);
float hash21(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void fragment() {
    float breakup = hash21(floor(UV*18.0))*0.05;
    float edge = length(UV-vec2(0.5));
    ALBEDO = stain_color.rgb;
    ROUGHNESS = 0.87;
    SPECULAR = 0.20;
    ALPHA = (1.0-smoothstep(0.16,0.43,edge+breakup))*0.48;
}
