#include "shaders/utils.glsl"

uniform FrameInfo {
    mat4 model_transform;
    mat4 camera_transform;
    vec3 camera_position;
}
frame_info;

uniform TextGeometry {
    float rotation_scale;
    float rotation;
}
text_geometry;

in vec2 offset;
in vec2 uv;
in vec2 aabbMin;
in vec2 aabbMax;

out vec3 v_position;
out vec3 v_normal;
out vec3 v_viewvector;
out vec2 v_texture_coords;
out vec4 v_color;

void main() {
    mat4 transform = frame_info.camera_transform;
    vec2 anchor = (aabbMin + aabbMax) / 2;

    float scale = getScaleFactor(frame_info.camera_transform, frame_info.model_transform);

    vec4 finalOffset = vec4(offset, 0.0, 0.0);
    float rot = text_geometry.rotation;

    if (text_geometry.rotation_scale > 0) {
        rot -= atan(transform[1][0], transform[0][0]);
    }

    finalOffset = mat4(
        cos(rot), sin(rot), 0, 0,
        -sin(rot), cos(rot), 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 0
    ) * finalOffset;

    vec3 world_position = vec3(anchor.x + (finalOffset.x / scale), anchor.y + (finalOffset.y / scale), 0.0);
    
    gl_Position = frame_info.model_transform * vec4(world_position, 1.0);

    v_position = world_position;
    v_viewvector = frame_info.camera_position - v_position;
    v_normal = vec3(1,0,0);
    v_texture_coords = uv;
    v_color = vec4(1,1,1,1);
}