
uniform Paint {
  vec4 color;
}
paint;

out vec4 frag_color;

void main() {
  frag_color = paint.color;
}