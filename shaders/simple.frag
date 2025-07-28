
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
  frag_color = paint.color;
}
