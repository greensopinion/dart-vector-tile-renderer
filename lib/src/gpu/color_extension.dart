import 'dart:ui';

import 'package:vector_math/vector_math.dart' as vm;

extension GpuColor on Color {
  vm.Vector4 get vector4 => vm.Vector4(r, g, b, a);
}
