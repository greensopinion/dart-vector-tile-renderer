uniform FragInfo {
  vec4 color;
  float vertex_color_weight;
  float smoothness;
  float threshold;
}
frag_info;

uniform sampler2D sdf;

in vec3 v_position;
in vec3 v_normal;
in vec3 v_viewvector;
in vec2 v_texture_coords;
in vec4 v_color;

out vec4 frag_color;

void main() {

  float sdfValue = 1 - texture(sdf, v_texture_coords).r;

  float alpha = smoothstep(frag_info.threshold - frag_info.smoothness, frag_info.threshold + frag_info.smoothness, sdfValue);

  vec4 vertex_color = mix(vec4(1), v_color, frag_info.vertex_color_weight);
  frag_color = vec4(frag_info.color.rgb, alpha) * vertex_color * frag_info.color;
}