uniform sampler2D base_color_texture;

in vec2 v_texture_coords;

out vec4 frag_color;

void main() {

    vec4 textureColor = texture(base_color_texture, v_texture_coords);
    float a = textureColor.a;
    if (a > 0) {
        frag_color = vec4(textureColor.rgb / a, a);
    } else {
        discard;
    }
}