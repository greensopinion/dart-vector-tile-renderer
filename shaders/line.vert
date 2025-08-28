#pragma shader stage(vertex)

uniform FrameInfo {
  mat4 model_transform;
  mat4 camera_transform;
  vec3 camera_position;
}
frame_info;

uniform LineGeometry {
  float width;
  float extentScale;
}
line_geometry;

in vec2 point_a;
in vec2 point_b;
in vec2 offset;
in float roundness;
in float vertex_cumulative_length;

out vec2 v_texture_coords;

out float v_length;
out float cumulative_length;

vec2 scalePoint(vec2 p) {
  return vec2((p.x / line_geometry.extentScale) - 1, 1 - (p.y / line_geometry.extentScale));
}

vec2 getSegmentPos(vec2 curr, vec2 next) {
  float offsetDist = line_geometry.width / 2.0;

  vec2 unitDir = normalize(next - curr);
  vec2 perp = vec2(unitDir.y, -unitDir.x);

  mat4 transform = frame_info.model_transform;

  float scale = 0.5;

  return curr + (clamp(offset.x, -5, 5) * offsetDist * perp / scale) + (clamp(offset.y, -5, 5) * offsetDist * unitDir / scale);
}

void main() {
  vec2 curr = scalePoint(point_a);
  vec2 next = scalePoint(point_b);

  vec2 segment_pos = getSegmentPos(curr, next);

  gl_Position = frame_info.model_transform * vec4(segment_pos, 0.0, 1.0);

  v_texture_coords = vec2(offset.x, offset.y * roundness);

  v_length = distance(curr, next) * line_geometry.width;
  cumulative_length = vertex_cumulative_length * 2;
}