import 'dart:typed_data';

import 'package:flutter_gpu/gpu.dart';
import 'package:flutter_scene/scene.dart';

import 'shaders.dart';
import 'tile_render_data.dart';
import 'utils.dart';

class ColoredMaterial extends Material {
  late final ByteData _uniform;

  ColoredMaterial(PackedMaterial packed) {
    setFragmentShader(shaderLibrary["SimpleFragment"]!);
    _uniform = packed.uniform!;
  }

  @override
  void bind(
      RenderPass pass, HostBuffer transientsBuffer, Lighting lighting) {
    super.bind(pass, transientsBuffer, lighting);

    pass.bindUniform(
      fragmentShader.getUniformSlot("Paint"),
      transientsBuffer.emplace(_uniform),
    );

    configureRenderPass(pass);
    pass.setWindingOrder(WindingOrder.clockwise);
  }

  @override
  bool isOpaque() {
    // _uniform is `Paint { vec4 color }`; the 4th float is alpha. Fully opaque
    // fills (and the tile background) take the fast opaque+depth path. A
    // translucent fill (e.g. a park at partial opacity) instead goes to the
    // blended translucent pass so it composites over the layers beneath it —
    // matching the canvas renderer — rather than depth-occluding them (which
    // painted them as solid, over-saturated blotches).
    return _uniform.getFloat32(12, Endian.little) >= 0.999;
  }
}
