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


in vec3 position;

out vec3 v_position;
out vec3 v_normal;
out vec3 v_viewvector;
out vec2 v_texture_coords;
out vec4 v_color;

vec2 getSegmentPos(float y, int offset) {
    vec2 curr = line_positions.points[int(position.x)].xy;
    vec2 next = line_positions.points[int(position.z) + offset].xy;
    float widthOffset = y * line_style.width / 2.0;

    vec2 unitDir = normalize(next - curr);
    vec2 perp = vec2(unitDir.y, -unitDir.x);

    return curr + (widthOffset * perp);
}

void main() {
    vec2 result;

    if (position.y == 0) {
        result = line_positions.points[int(position.x)].xy;
    } else if (position.y < 1.5) {
        result = getSegmentPos(position.y, 0);
    } else if (abs(position.y) == 2) {
        vec2 o = line_positions.points[int(position.x)].xy;
        vec2 a = getSegmentPos(position.y / 2, 0) - o;
        vec2 b = getSegmentPos(position.y / 2, 2) - o;

        vec2 c = (a + b) / 2;

        float x = ((a.x * a.x / a.y) + a.y) / ((c.y / c.x) + (a.x / a.y));
        float y = (c.y / c.x) * x;
        result = vec2(x + o.x, y + o.y);
    }

    gl_Position = vec4(result, 0.0, 1.0);

    v_position = vec3(result, 0.0);
    v_viewvector = frame_info.camera_position - v_position;
    v_normal = vec3(1,0,0);
    v_texture_coords = vec2(0, 0);
    v_color = vec4(0,0,0,1);
}