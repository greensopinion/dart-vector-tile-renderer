uniform FragInfo {
  vec4 textColor;
  vec4 haloColor;
}
frag_info;

uniform Age {
  int milliseconds;
}
age;

uniform sampler2D sdf;

in vec2 v_texture_coords;
in float v_font_size;

out vec4 frag_color;

const float baseSoftness = 0.05;
const float baseThreshold = 0.975;

const float baseHaloSoftness = 0.06;
const float baseHaloThreshold = 0.85;

void main() {
  if (v_font_size < 0) {
    discard;
  }

  float sdfValue = 1 - texture(sdf, v_texture_coords).r;
  float softness = baseSoftness * (16 / v_font_size);

  float alphaText = smoothstep(baseThreshold - softness, baseThreshold + softness, sdfValue);

  float alphaHalo = smoothstep(baseHaloThreshold - baseHaloSoftness, baseHaloThreshold + baseHaloSoftness, sdfValue);

  // Foreground (text)
  vec3 Cf = frag_info.textColor.rgb;
  float Af = alphaText * frag_info.textColor.a;

  // Background (halo)
  vec3 Cb = frag_info.haloColor.rgb;
  float Ab = alphaHalo * frag_info.haloColor.a;

  // Over operator: text over halo
  float outA  = Af + Ab * (1.0 - Af);
  vec3 outRgb = (Cf * Af + Cb * Ab * (1.0 - Af)) / outA;

  frag_color = vec4(outRgb, min(1.0, outA) * min(1.0, age.milliseconds / 500.0));
}
