uniform FrameInfo {
    mat4 model_transform;
    mat4 camera_transform;
    vec3 camera_position;
}
frame_info;

in vec3 position;
in vec2 uv;

out vec3 v_position;
out vec3 v_normal;
out vec3 v_viewvector;
out vec2 v_texture_coords;
out vec4 v_color;

void main() {
    gl_Position = vec4((frame_info.model_transform * vec4(position, 1.0)).xy, 1.0, 1.0);

    v_position = position;
    v_viewvector = frame_info.camera_position - v_position;
    v_normal = vec3(1,0,0);
    v_texture_coords = uv;
    v_color = vec4(1,1,1,1);
}