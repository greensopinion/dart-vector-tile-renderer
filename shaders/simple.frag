
uniform Paint {
  vec4 color;
}
paint;

uniform AntiAliasing {
  float enabled;
  float edgeWidth;
}
antialiasing;

out vec4 frag_color;

void main() {

  if (abs(v_position.x) > 1.0 || abs(v_position.y) > 1.0) {
    frag_color = vec4(0, 0, 0, 0);
    return;
  }

  frag_color = paint.color;
}
