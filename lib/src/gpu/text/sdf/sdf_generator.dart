import 'dart:typed_data';
import 'dart:math' as math;

/// SDF generation functions based on Felzenszwalb/Huttenlocher algorithm
Uint8List generateSDF(Uint8List bitmap, int width, int height, int radius, double cutoff) {
  final size = width * height;
  final gridOuter = Float64List(size);
  final gridInner = Float64List(size);
  final f = Float64List(math.max(width, height));
  final z = Float64List(math.max(width, height) + 1);
  final v = Int32List(math.max(width, height));
  
  // Initialize grids
  for (int i = 0; i < size; i++) {
    final alpha = bitmap[i];
    gridOuter[i] = alpha == 0 ? 999999 : 0;
    gridInner[i] = alpha > 0 ? 999999 : 0;
  }
  
  // Transform along columns
  for (int x = 0; x < width; x++) {
    _edt1d(gridOuter, f, v, z, x, width, height, width);
    _edt1d(gridInner, f, v, z, x, width, height, width);
  }
  
  // Transform along rows
  for (int y = 0; y < height; y++) {
    _edt1d(gridOuter, f, v, z, y * width, width, 1, 1);
    _edt1d(gridInner, f, v, z, y * width, width, 1, 1);
  }
  
  final result = Uint8List(size);
  for (int i = 0; i < size; i++) {
    final d = math.sqrt(gridOuter[i]) - math.sqrt(gridInner[i]);
    final normalized = math.max(0, math.min(255, (d / radius + cutoff) * 255));
    result[i] = normalized.round();
  }
  
  return result;
}

void _edt1d(Float64List grid, Float64List f, Int32List v, Float64List z,
    int offset, int stride, int start, int step) {
  int q = 0;
  
  for (int i = 0; i < stride; i++) {
    f[i] = grid[offset + i * step];
  }
  
  for (int i = 0; i < stride; i++) {
    if (f[i] != 999999) {
      if (q == 0) {
        v[0] = i;
        z[0] = double.negativeInfinity;
        z[1] = double.infinity;
        q = 1;
      } else {
        while (q > 0 && q - 1 >= 0) {
          final j = v[q - 1];
          final s = ((f[i] + i * i) - (f[j] + j * j)) / (2 * i - 2 * j);
          if (s <= z[q - 1]) {
            q--;
          } else {
            break;
          }
        }
        
        if (q < stride) {
          v[q] = i;
          z[q] = q > 0 ? ((f[i] + i * i) - (f[v[q - 1]] + v[q - 1] * v[q - 1])) / (2 * i - 2 * v[q - 1]) : double.negativeInfinity;
          z[q + 1] = double.infinity;
          q++;
        }
      }
    }
  }
  
  if (q == 0) return;
  
  int j = 0;
  for (int i = 0; i < stride; i++) {
    while (j < q - 1 && z[j + 1] <= i) {
      j++;
    }
    if (j < q) {
      final dx = i - v[j];
      grid[offset + i * step] = f[v[j]] + dx * dx;
    }
  }
}