uniform FrameInfo {
    mat4 model_transform;
    mat4 camera_transform;
    vec3 camera_position;
}
frame_info;

in vec2 offset;      // Character offset relative to anchor
in vec2 uv;          // Texture coordinates
in vec2 anchor;      // Anchor position in world space

out vec3 v_position;
out vec3 v_normal;
out vec3 v_viewvector;
out vec2 v_texture_coords;
out vec4 v_color;

void main() {
    mat4 transform = frame_info.model_transform;

    float scale = (transform[0].x + transform[1].y) / 2;

    vec3 world_position = vec3(anchor.x + (offset.x / scale), anchor.y + (offset.y / scale), 0.0);
    
    gl_Position = transform * vec4(world_position, 1.0);

    v_position = world_position;
    v_viewvector = frame_info.camera_position - v_position;
    v_normal = vec3(1,0,0);
    v_texture_coords = uv;
    v_color = vec4(0,0,0,1);
}