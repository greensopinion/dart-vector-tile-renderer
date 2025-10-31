#include "shaders/vector_tile_renderer$utils.glsl"

uniform FrameInfo {
    mat4 model_transform;
    mat4 camera_transform;
    vec3 camera_position;
}
frame_info;

const int layer_count = 4;
const float inv_spacing = 2;

in vec2 offset;
in vec2 uv;
in vec2 anchor0;
in vec2 anchor1;
in vec2 anchor2;
in vec2 anchor3;
in float rotation0;
in float rotation1;
in float rotation2;
in float rotation3;
in float rotation_scale;
in float min_scale;
in float font_size;

out vec2 v_texture_coords;
out float v_font_size;

float mixAngle(float a, float b, float t) {
    const float TWO_PI = 6.28318530718; // 2*pi
    float delta = mod(b - a + 3.14159265359, TWO_PI) - 3.14159265359;
    return mod(a + delta * t, TWO_PI);
}

void main() {
    mat4 transform = frame_info.camera_transform;

    float scale = getScaleFactor(frame_info.camera_transform, frame_info.model_transform);

    if (scale < min_scale) {
        gl_Position = vec4(0.0, 0.0, -10.0, 1.0);
        v_texture_coords = vec2(0.0, 0.0);
        v_font_size = -1;
        return;
    }

    vec2 anchors[layer_count] = vec2[layer_count](anchor0, anchor1, anchor2, anchor3);
    float rotations[layer_count] = float[layer_count](rotation0, rotation1, rotation2, rotation3);


    // Map scale to layer index
    float scaledIndex = (scale - 1.0) * inv_spacing;
    int i0 = int(floor(scaledIndex));
    int i1 = i0 + 1;

    // Clamp indices to valid range
    i0 = clamp(i0, 0, layer_count - 1);
    i1 = clamp(i1, 0, layer_count - 1);

    float t = fract(scaledIndex); // fraction between the two layers

    // Interpolate anchors and rotations
    vec2 interpolatedAnchor = mix(anchors[i0], anchors[i1], t);
    float interpolatedRotation = mixAngle(rotations[i0], rotations[i1], t);

    vec4 finalOffset = vec4(offset, 0.0, 0.0);
    float rot = interpolatedRotation;

    if (rotation_scale > 0) {
        rot -= atan(transform[1][0], transform[0][0]);
    }

    finalOffset = mat4(
        cos(rot), sin(rot), 0, 0,
        -sin(rot), cos(rot), 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 0
    ) * finalOffset;

    vec3 world_position = vec3(interpolatedAnchor.x + (finalOffset.x / scale), interpolatedAnchor.y + (finalOffset.y / scale), 0.0);
    
    gl_Position = vec4((frame_info.model_transform * vec4(world_position, 1.0)).xy, 0.0, 1.0);

    v_texture_coords = uv;
    v_font_size = font_size;
}