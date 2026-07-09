uniform FragInfo {
  vec4 textColor;
  vec4 haloColor;
}
frag_info;

// NOTE: float (not int) for Impeller GLES compatibility — GLES backend only
// supports float uniforms.
uniform Age {
  float milliseconds;
}
age;

uniform sampler2D sdf;

in vec2 v_texture_coords;

out vec4 frag_color;

const float baseSoftness = 0.05;
const float baseThreshold = 0.975;

const float baseHaloSoftness = 0.06;
const float baseHaloThreshold = 0.85;

void main() {
  float sdfValue = 1.0 - texture(sdf, v_texture_coords).r;

  // Fixed edge softness. We intentionally do NOT scale it by the glyph's font
  // size: under flutter_gpu's reflected vertex layout the trailing `font_size`
  // vertex attribute reads unreliably (the CPU-side value is correct, e.g.
  // 16.25, but the shader saw it as negative). The map's labels span a narrow
  // size range, so a constant softness matches the old output closely.
  // Off-screen glyphs are already culled by the vertex shader's gl_Position,
  // so the old `if (v_font_size < 0) discard;` (which the bad read tripped for
  // every glyph, hiding all text) is gone.
  float softness = baseSoftness;

  float alphaText = smoothstep(baseThreshold - softness, baseThreshold + softness, sdfValue);
  float alphaHalo = smoothstep(baseHaloThreshold - baseHaloSoftness, baseHaloThreshold + baseHaloSoftness, sdfValue);

  // Foreground (text)
  vec3 Cf = frag_info.textColor.rgb;
  float Af = alphaText * frag_info.textColor.a;

  // Background (halo)
  vec3 Cb = frag_info.haloColor.rgb;
  float Ab = alphaHalo * frag_info.haloColor.a;

  // Over operator: text over halo
  float outA = Af + Ab * (1.0 - Af);
  vec3 outRgb = outA > 0.0 ? (Cf * Af + Cb * Ab * (1.0 - Af)) / outA : vec3(0.0);

  frag_color = vec4(outRgb, min(1.0, outA) * min(1.0, age.milliseconds / 500.0));
}
