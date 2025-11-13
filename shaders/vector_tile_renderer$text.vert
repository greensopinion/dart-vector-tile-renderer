#include "shaders/vector_tile_renderer$utils.glsl"

uniform FrameInfo {
    mat4 model_transform;
    mat4 camera_transform;
    vec3 camera_position;
}
frame_info;

uniform TileOffset {
    float scale;
}
tile_offset;

in vec2 offset;
in vec2 uv;
in vec2 anchor;
in float rotation;
in float rotation_scale;
in float min_scale;
in float font_size;

out vec2 v_texture_coords;
out float v_font_size;

void main() {
    mat4 transform = frame_info.camera_transform;

    float scale = getScaleFactor(frame_info.camera_transform, frame_info.model_transform) * tile_offset.scale;

    if (scale < min_scale) {
        gl_Position = vec4(0.0, 0.0, -10.0, 1.0);
        v_texture_coords = vec2(0.0, 0.0);
        v_font_size = -1;
        return;
    }

    vec4 finalOffset = vec4(offset, 0.0, 0.0);
    float rot = rotation;

    if (rotation_scale > 0) {
        rot -= atan(transform[1][0], transform[0][0]);
    }

    finalOffset = mat4(
    cos(rot), sin(rot), 0, 0,
    -sin(rot), cos(rot), 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 0
    ) * finalOffset;

    vec3 world_position = vec3(anchor.x + (finalOffset.x / scale), anchor.y + (finalOffset.y / scale), 0.0);

    gl_Position = vec4((frame_info.model_transform * vec4(world_position, 1.0)).xy, 0.0, 1.0);

    v_texture_coords = uv;
    v_font_size = font_size;
}