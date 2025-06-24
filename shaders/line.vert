uniform FrameInfo {
  mat4 model_transform;
  mat4 camera_transform;
  vec3 camera_position;
}
frame_info;

#define MAX_POINTS 1024

uniform LinePositions {
    vec2 points[MAX_POINTS];
}
line_positions;

uniform LineStyle {
  float width;
}
line_style;


in vec3 position;

out vec3 v_position;
out vec3 v_normal;
out vec3 v_viewvector;
out vec2 v_texture_coords;
out vec4 v_color;

void main() {

  vec2 curr = line_positions.points[int(position.x)];
  vec2 next = line_positions.points[int(position.z)];
  float widthOffset = position.y * line_style.width / 2.0;

  vec2 unitDir = normalize(next - curr);
  vec2 perp = vec2(unitDir.y, -unitDir.x);

  vec2 result = curr + (widthOffset * perp);

  gl_Position = vec4(result, 0.0, 1.0);

  v_position = vec3(result, 0.0);
  v_viewvector = frame_info.camera_position - v_position;
  v_normal = vec3(1,0,0);
  v_texture_coords = vec2(0, 0);
  v_color = vec4(0,0,0,1);
}