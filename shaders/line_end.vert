uniform FrameInfo {
    mat4 model_transform;
    mat4 camera_transform;
    vec3 camera_position;
}
frame_info;

uniform LinePositions {
    vec4 points[4];
}
line_positions;

uniform LineStyle {
    float width;
}
line_style;


in vec3 position;
in vec2 uv;

out vec3 v_position;
out vec3 v_normal;
out vec3 v_viewvector;
out vec2 v_texture_coords;
out vec4 v_color;

vec2 getSegmentPos() {
    vec2 curr = line_positions.points[int(position.x)].xy;
    vec2 prev = line_positions.points[int(position.y)].xy;
    float thickness = line_style.width / 2.0;

    vec2 unitDir = normalize(curr - prev);
    vec2 perp = vec2(unitDir.y, -unitDir.x);

    return curr + (perp * thickness * uv.x) + (unitDir * thickness * uv.y);
}

void main() {
    vec2 result;

    result = getSegmentPos();

    gl_Position = vec4(result, 0.0, 1.0);

    v_texture_coords = uv;

    v_position = vec3(result, 0.0);
    v_viewvector = frame_info.camera_position - v_position;
    v_normal = vec3(1,0,0);
    v_color = vec4(0,0,0,1);
}