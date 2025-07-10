uniform Paint {
  vec4 color;
}
paint;

uniform dashMeasurements {
  float drawLength;
  float spaceLength;
}
dash_measurements;

in vec3 v_position;
in vec3 v_normal;
in vec3 v_viewvector;

in vec2 v_texture_coords;

in vec4 v_color;

in float v_progress;
in float v_length;
in float cumulative_length;

out vec4 frag_color;

void main() {

  vec4 base_color = paint.color;
  vec4 alt_color = vec4(0, 0, 0, 0);

  float v_progressButPositiveAndNormalized = (v_progress + 1) / 2;
  float lengthAlongLineInPixels = v_progressButPositiveAndNormalized * v_length + cumulative_length;
  float lengthNoCumulative = v_progressButPositiveAndNormalized * v_length;

  float cycleLength = dash_measurements.drawLength + dash_measurements.spaceLength;
  float distInCycle = mod(lengthAlongLineInPixels, cycleLength);

  if (distInCycle < dash_measurements.drawLength && v_length - lengthNoCumulative < dash_measurements.drawLength) {
    frag_color = paint.color;
  } else {
    frag_color = alt_color;
  }
}
