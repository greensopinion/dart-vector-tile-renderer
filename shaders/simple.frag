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

  if (abs(v_position.x) > 1.0 || abs(v_position.y) > 1.0) {
    frag_color = vec4(0, 0, 0, 0);
    return;
  }

  frag_color = paint.color;
}