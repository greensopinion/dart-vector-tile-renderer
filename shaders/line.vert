#pragma shader stage(vertex)

uniform FrameInfo {
  mat4 model_transform;
  mat4 camera_transform;
  vec3 camera_position;
}
frame_info;

uniform LineStyle {
  float width;
}
line_style;

uniform extentScalings {
  float extentScale;
}
extent_scalings;

in vec2 point_a;
in vec2 point_b;
in vec2 offset;
in float roundness;
in float vertex_cumulative_length;

out vec3 v_position;
out vec3 v_normal;
out vec3 v_viewvector;
out vec2 v_texture_coords;
out vec4 v_color;

out float v_length;
out float cumulative_length;

vec2 scalePoint(vec2 p) {
  return vec2((p.x / extent_scalings.extentScale) - 1, 1 - (p.y / extent_scalings.extentScale));
}

vec2 getSegmentPos(vec2 curr, vec2 next) {
  float offsetDist = line_style.width / 2.0;

  vec2 unitDir = normalize(next - curr);
  vec2 perp = vec2(unitDir.y, -unitDir.x);

  return curr + (offset.x * offsetDist * perp) + (offset.y * offsetDist * unitDir);
}

void main() {
  vec2 curr = scalePoint(point_a);
  vec2 next = scalePoint(point_b);

  vec2 segment_pos = getSegmentPos(curr, next);

  mat4 transform = frame_info.model_transform;

  gl_Position = transform * vec4(segment_pos, 0.0, 1.0);

  v_position = vec3(segment_pos, 0.0);
  v_viewvector = frame_info.camera_position - v_position;
  v_normal = vec3(1, 0, 0);
  v_texture_coords = vec2(offset.x, offset.y * roundness);
  v_color = vec4(0, 0, 0, 1);

  cumulative_length = vertex_cumulative_length * 2;
}