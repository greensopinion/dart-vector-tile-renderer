uniform FrameInfo {
  mat4 model_transform;
  mat4 camera_transform;
  vec3 camera_position;
}
frame_info;

#define MAX_POINTS 512

uniform LinePositions {
    vec2 points[MAX_POINTS];
};

uniform LineStyle {
  float width;
};

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
// 2. above or below the line (0 or 1)
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

in vec3 position;

out vec3 v_position;


void main() {

  vec4 model_position = frame_info.model_transform * vec4(position, 1.0);
  v_position = model_position.xyz;
  gl_Position = frame_info.camera_transform * model_position;
}
