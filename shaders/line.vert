uniform FrameInfo {
  mat4 model_transform;
  mat4 camera_transform;
  vec3 camera_position;
}
frame_info;

#define MAX_POINTS 512

uniform LinePositions {
    vec2 points[MAX_POINTS];
}
line_positions;

uniform LineStyle {
  float width;
}
line_style;

in vec3 position;

void main() {

  vec2 curr = line_positions.points[int(position.x)];
  vec2 next = line_positions.points[int(position.z)];
  float widthOffset = position.y * line_style.width / 2.0;

  vec2 unitDir = normalize(next - curr);
  vec2 perp = vec2(unitDir.y, -unitDir.x);

  vec2 result = curr + (widthOffset * perp);

  gl_Position = vec4(result, 0.0, 1.0);
}



// line that consists of segments
// each segment is a line between two points
//
// uniform: p1 - p2 - p3
// uniform: thickness
//
// need: normal from the line p1-p2, above or below
//
// index formula indates which point, and above or below
// each point is represented by three numbers:
// 1. index into the position uniform for the point
// 2. above or below the line (-1 or 1)
// 3. index into the normal uniform for the source/destination point
//
//
// vertices:
//
//  a  ---- b
//  p1 ---- p2
//. c  ---- d
//
// c, a, b, c, d, b
//