#include "shaders/vector_tile_renderer$utils.glsl"

uniform FrameInfo {
    mat4 model_transform;
    mat4 camera_transform;
    vec3 camera_position;
}
frame_info;

in vec2 anchor;
in vec2 offset;
in vec2 uv;

out vec2 v_texture_coords;

void main() {
    mat4 transform = frame_info.camera_transform;

    float scale = getScaleFactor(frame_info.camera_transform, frame_info.model_transform);

    vec4 finalOffset = vec4(offset, 0.0, 0.0);

    float rot = - atan(transform[1][0], transform[0][0]);;

    finalOffset = mat4(
    cos(rot), sin(rot), 0, 0,
    -sin(rot), cos(rot), 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 0
    ) * finalOffset;

    vec3 world_position = vec3(anchor.x + (finalOffset.x / scale), anchor.y + (finalOffset.y / scale), 0.0);

    gl_Position = vec4((frame_info.model_transform * vec4(world_position, 1.0)).xy, 0.5, 1.0);

    v_texture_coords = uv;
}