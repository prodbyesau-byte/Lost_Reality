shader_type canvas_item;
void fragment() {
    float edge = smoothstep(0.32,0.76,distance(UV,vec2(0.5)));
    COLOR = vec4(0.008,0.012,0.013,edge*0.20);
}
