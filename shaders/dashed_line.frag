uniform dashMeasurements {
  float drawLength;
  float spaceLength;
}
dash_measurements;

in float v_progress;
in float v_length;

uniform Paint {
  vec4 color;
}
paint;

out vec4 frag_color;

void main() {
  float v_progressButPositiveAndNormalized = (v_progress + 1) / 2;
  float lengthAlongLineInPixels = v_progressButPositiveAndNormalized * v_length;

  float cycleLength = dash_measurements.drawLength + dash_measurements.spaceLength;
  float distInCycle = mod(lengthAlongLineInPixels, cycleLength);

  if (distInCycle < dash_measurements.drawLength) {
    frag_color = paint.color;
  } else {
    frag_color = vec4(v_length, distInCycle, cycleLength, 0);
  }
}
