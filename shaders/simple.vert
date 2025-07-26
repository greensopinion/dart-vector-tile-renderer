uniform FrameInfo {
  mat4 model_transform;
  mat4 camera_transform;
  vec3 camera_position;
}
frame_info;

in vec3 position;

out vec3 v_position;
out vec3 v_normal;
out vec3 v_viewvector;
out vec2 v_texture_coords;
out vec4 v_color;

void main() {
  mat4 transform = frame_info.model_transform;
  gl_Position = transform * vec4(position, 1.0);

  v_position = position;
  v_viewvector = frame_info.camera_position - v_position;
  v_normal = vec3(1,0,0);
  v_texture_coords = vec2(position.x + 1, 1 - position.y) / 2.0;
  v_color = vec4(1,1,1,1);
}