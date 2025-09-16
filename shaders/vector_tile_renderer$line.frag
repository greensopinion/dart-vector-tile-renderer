#version 150

uniform LineMaterial {
  vec4 color;
  float drawLength;
  float spaceLength;
}
line_material;

in vec2 v_texture_coords;
in vec2 v_position;
in float v_length;
in float cumulative_length;

out vec4 frag_color;

void main() {
  if (abs(v_position.x) > 1.001 || abs(v_position.y) > 1.001) {
    frag_color = vec4(0, 0, 0, 0);
    return;
  }

  vec4 base_color = line_material.color;
  vec4 alt_color = vec4(0, 0, 0, 0);

  float line_length_pixels = v_length + cumulative_length;

  float cycleLength = line_material.drawLength + line_material.spaceLength;
  float distInCycle = mod(line_length_pixels, cycleLength);

  if (distInCycle < line_material.drawLength) {
    if (v_texture_coords.y != 0.0) {
        float dist = length(v_texture_coords);
        float inside = step(dist, 1.0);
        frag_color = mix(alt_color, base_color, inside);
    } else {
        frag_color = base_color;
    }
  } else {
    frag_color = alt_color;
  }
}
