shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform int surface_kind = 0; // 0 concrete, 1 boards, 2 worn tile, 3 asphalt
uniform float wetness : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D micro_normal : hint_normal, filter_linear_mipmap, repeat_enable;
varying vec3 world_position;

float hash21(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
float noise2(vec2 p) {
    vec2 i = floor(p); vec2 f = fract(p); f = f*f*(3.0-2.0*f);
    return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);
}
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
    vec2 p = world_position.xz;
    float broad = noise2(p*0.55);
    float wear = noise2(p*3.0);
    vec3 base = vec3(0.27,0.285,0.27);
    float seam = 0.0;
    if (surface_kind == 1) {
        vec2 uv = vec2(p.x*3.3, p.y*0.46 + floor(p.x*3.3)*0.39);
        vec2 cell = floor(uv); vec2 f = fract(uv);
        float edge = min(min(f.x,1.0-f.x),min(f.y,1.0-f.y));
        seam = 1.0 - smoothstep(0.002,max(0.022,fwidth(edge)*1.1),edge);
        float grain = noise2(vec2(p.x*38.0,p.y*1.3));
        base = vec3(0.245,0.205,0.157) * (0.82+hash21(cell)*0.35) * (0.93+grain*0.12);
    } else if (surface_kind == 2) {
        vec2 uv = p*1.5; vec2 f = fract(uv);
        float edge = min(min(f.x,1.0-f.x),min(f.y,1.0-f.y));
        seam = 1.0-smoothstep(0.009,0.024,edge);
        float checker = mod(floor(uv.x)+floor(uv.y),2.0);
        base = mix(vec3(0.28,0.30,0.27),vec3(0.37,0.36,0.30),checker);
    } else if (surface_kind == 3) {
        base = vec3(0.14,0.16,0.16);
    } else {
        vec2 f = fract(p/3.0);
        seam = 1.0-smoothstep(0.001,0.006,min(min(f.x,1.0-f.x),min(f.y,1.0-f.y)));
    }
    float damp = smoothstep(0.43,0.72,broad) * wetness;
    // Palette values are authored in sRGB like StandardMaterial3D colors.
    // Convert them to linear so floors do not appear brighter than all other assets.
    ALBEDO = pow(base,vec3(2.2)) * (0.88+wear*0.17) * mix(1.0,0.65,seam) * mix(1.0,0.70,damp);
    ROUGHNESS = mix(0.88,0.24,damp);
    SPECULAR = mix(0.28,0.5,damp);
    METALLIC = 0.0;
    NORMAL_MAP = texture(micro_normal,p*0.5).rgb;
    NORMAL_MAP_DEPTH = mix(0.18,0.05,damp);
    AO = mix(1.0,0.78,seam);
}
