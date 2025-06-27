uniform Paint {
    vec4 color;
}
paint;

in vec3 v_position;
in vec3 v_normal;
in vec3 v_viewvector;

in vec2 v_texture_coords;

in vec4 v_color;

out vec4 frag_color;

void main() {
    vec4 base_color = paint.color;
    vec4 alt_color = vec4(0, 0, 0, 0);

    float dist = length(v_texture_coords);
    float inside = step(dist, 1.0);

    frag_color = mix(alt_color, base_color, inside);
}