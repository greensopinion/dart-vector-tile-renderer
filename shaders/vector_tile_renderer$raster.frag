uniform FragInfo {
    vec4 color;
    float vertex_color_weight;
}
frag_info;

uniform sampler2D base_color_texture;

in vec3 v_position;
in vec3 v_normal;
in vec3 v_viewvector;
in vec2 v_texture_coords;
in vec4 v_color;

out vec4 frag_color;

void main() {
    if (abs(v_position.x) > 1.001 || abs(v_position.y) > 1.001) {
        frag_color = vec4(0, 0, 0, 0);
        return;
    }

    vec4 textureColor = texture(base_color_texture, v_texture_coords);
    float a = textureColor.a;
    if (a > 0) {
        textureColor = vec4(textureColor.rgb / a, a);
    }

    vec4 vertex_color = mix(vec4(1), v_color, frag_info.vertex_color_weight);
    frag_color = textureColor * vertex_color * frag_info.color;
}