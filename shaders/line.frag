uniform LineMaterial {
  vec4 color;
  float drawLength;
  float spaceLength;
}
dash_measurements;

uniform AntiAliasing {
  float enabled;
  float edgeWidth;
}
antialiasing;

in vec3 v_position;
in vec3 v_normal;
in vec3 v_viewvector;

in vec2 v_texture_coords;

in vec4 v_color;

in float v_length;
in float cumulative_length;

out vec4 frag_color;

void main() {

  if (abs(v_position.x) > 1.0 || abs(v_position.y) > 1.0) {
      frag_color = vec4(0, 0, 0, 0);
      return;
  }

  vec4 base_color = line_material.color;
  vec4 alt_color = vec4(0, 0, 0, 0);

  float line_length_pixels = v_length + cumulative_length;

  float cycleLength = line_material.drawLength + line_material.spaceLength;
  float distInCycle = mod(line_length_pixels, cycleLength);

  if (distInCycle < line_material.drawLength && v_length - v_length < line_material.drawLength) {
    if (v_texture_coords.y != 0.0) {
        float dist = length(v_texture_coords);
        
        if (antialiasing.enabled > 0.5) {
          float edge_width = antialiasing.edgeWidth;
          float solid_radius = 1.4 - edge_width;
          float alpha;
          
          if (dist <= solid_radius) {
            alpha = 1.0;
          } else {
            alpha = smoothstep(1.0, solid_radius, dist);
          }
          
          frag_color = vec4(base_color.rgb, base_color.a * alpha);
        } else {
          float inside = step(dist, 1.0);
          frag_color = mix(alt_color, base_color, inside);
        }
    } else {
        if (antialiasing.enabled > 0.5) {
          float dist = abs(v_texture_coords.y);
          float edge_width = antialiasing.edgeWidth;
          float solid_radius = 1.5 - edge_width;
          float alpha;
          
          if (dist <= solid_radius) {
            alpha = 1.0;
          } else {
            alpha = smoothstep(2.0, solid_radius, dist);
          }
          
          frag_color = vec4(base_color.rgb, base_color.a * alpha);
        } else {
          frag_color = paint.color;
        }
    }
  } else {
    frag_color = alt_color;
  }
}
