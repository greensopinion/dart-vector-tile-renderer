uniform FrameInfo {
  mat4 model_transform;
  mat4 camera_transform;
  vec3 camera_position;
}
frame_info;

#define MAX_POINTS 1024

uniform LinePositions {
    vec4 points[MAX_POINTS];
}
line_positions;

uniform LineStyle {
  float width;
}
line_style;

// uniform dashMeasurements {
//   float drawLength;
//   float spaceLength;
// }
// dash_measurements;

uniform extentScalings {
  float extentScale;
}
extent_scalings;

in vec3 position;

out float v_progress;
out float v_length;

out vec3 v_position;
out vec3 v_normal;
out vec3 v_viewvector;
out vec2 v_texture_coords;
out vec4 v_color;



vec2 getSegmentPos() {
  vec2 curr = line_positions.points[int(position.x)].xy;
  vec2 next = line_positions.points[int(position.z)].xy;
  float widthOffset = position.y * line_style.width / 2.0;

  vec2 unitDir = normalize(next - curr);
  vec2 perp = vec2(unitDir.y, -unitDir.x);

  return curr + (widthOffset * perp);
}

void main() {
  vec2 result;

  if (position.y == 0) {
    result = line_positions.points[int(position.x)].xy;
  } else if (position.y < 1.5) {
    result = getSegmentPos();
  }

  gl_Position = vec4(result, 0.0, 1.0);

  v_position = vec3(result, 0.0);
  v_viewvector = frame_info.camera_position - v_position; //* dash_measurements.drawLength * dash_measurements.spaceLength;
  v_normal = vec3(1,0,0);
  v_texture_coords = vec2(0, 0);
  v_color = vec4(0,0,0,1);

  vec2 curr = line_positions.points[int(position.x)].xy;
  vec2 next = line_positions.points[int(position.z)].xy;

  vec2 vec = next - curr;
  float check = 0;
  if (vec.x != 0) {
    check = vec.x;
  } else if (vec.y != 0) {
    check = vec.y;
  }
  v_progress = sign(check);

  v_length = length(vec) * extent_scalings.extentScale;
}