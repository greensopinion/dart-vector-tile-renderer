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
in vec2 uv;
in float round;

out vec3 v_position;
out vec3 v_normal;
out vec3 v_viewvector;
out vec2 v_texture_coords;
out vec4 v_color;

vec2 getSegmentPos(vec2 curr, vec2 next, float flip) {
  float offsetDist = line_style.width / 2.0;

  vec2 unitDir = normalize(next - curr);
  vec2 perp = vec2(unitDir.y, -unitDir.x);

  return curr + (uv.x * offsetDist * perp * flip) + (uv.y * offsetDist * unitDir);
}

float eulerDist(vec2 vec) {
  return sqrt(vec.x * vec.x + vec.y * vec.y);
}

vec2 getMiterPos() {
  vec2 origin = line_positions.points[int(position.y)].xy;
  vec2 a = getSegmentPos(origin, line_positions.points[int(position.x)].xy, 1);
  vec2 b = getSegmentPos(origin, line_positions.points[int(position.z)].xy, -1);
  vec2 c = vec2((a.x + b.x) / 2, (a.y + b.y) / 2);

  vec2 vec = c - origin;
  float vecLength = eulerDist(vec);

  if (vecLength <= 0) {
    return c;
  }

  vec2 resultDir = normalize(vec);
  float resultLength = (pow(eulerDist(c - a), 2)) / vecLength;

  return c + (resultDir * resultLength);
}

void main() {
  vec2 result;
  if (position.z == 0) {
    result = getSegmentPos(line_positions.points[int(position.x)].xy, line_positions.points[int(position.y)].xy, 1);
  } else {
    result = getMiterPos();
  }

  gl_Position = vec4(result, 0.0, 1.0);

  v_position = vec3(result, 0.0);
  v_viewvector = frame_info.camera_position - v_position;
  v_normal = vec3(1,0,0);
  v_texture_coords = vec2(uv.x, uv.y * round);
  v_color = vec4(0,0,0,1);
}