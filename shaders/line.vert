#pragma shader stage(vertex)

uniform FrameInfo {
  mat4 model_transform;
  mat4 camera_transform;
  vec3 camera_position;
}
frame_info;

uniform LineStyle {
  float width;
}
line_style;

uniform Meta {
  float num_points;
}
meta;

uniform extentScalings {
  float extentScale;
}
extent_scalings;

uniform sampler2D points;

in vec3 position;
in vec2 uv;
in float round;

out vec3 v_position;
out vec3 v_normal;
out vec3 v_viewvector;
out vec2 v_texture_coords;
out vec4 v_color;

out float v_length;
out float cumulative_length;

vec2 getPoint(int i) {
  float u = float(i) / (meta.num_points - 1.0);
  vec2 value = texture(points, vec2(u, 0)).xy;
  return vec2((value.x / extent_scalings.extentScale) - 1, 1 - (value.y / extent_scalings.extentScale));
}

float getCumulativeLength() {
  float lengthSum = 0.0;
  int currentIndex = int(position.x);

  for (int i = 1; i <= currentIndex; i++) {
    vec2 prev = getPoint(i - 1);
    vec2 curr = getPoint(i);

    lengthSum += length(curr - prev);
  }

  return lengthSum;
}

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
  vec2 origin = getPoint(int(position.y));
  vec2 a = getSegmentPos(origin, getPoint(int(position.x)), 1);
  vec2 b = getSegmentPos(origin, getPoint(int(position.z)), -1);
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
    result = getSegmentPos(getPoint(int(position.x)), getPoint(int(position.y)), 1);
  } else {
    result = getMiterPos();
  }
  gl_Position = vec4(result, 0.0, 1.0);

  v_position = vec3(result, 0.0);
  v_viewvector = frame_info.camera_position - v_position;
  v_normal = vec3(1,0,0);
  v_texture_coords = vec2(uv.x, uv.y * round);
  v_color = vec4(0,0,0,1);


  vec2 curr = getPoint(int(position.x));
  vec2 next = getPoint(int(position.z));

  vec2 vec = next - curr;
  float check = 0;
  if (vec.x != 0) {
    check = vec.x;
  } else if (vec.y != 0) {
    check = vec.y;
  }

  v_length = length(vec) * extent_scalings.extentScale;
  cumulative_length = getCumulativeLength() * extent_scalings.extentScale;
} 