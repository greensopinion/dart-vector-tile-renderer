import 'dart:ui';

import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/features/extensions.dart';
import 'package:vector_tile_renderer/src/themes/style.dart';

void main() {
  group('LayoutAnchorExtension.offset', () {
    final size = Size(100, 50);

    test('bottom returns offset anchored to bottom', () {
      final offset = LayoutAnchor.bottom.offset(size);
      expect(offset, equals(Offset(-50, -50)));
    });

    test('top returns offset anchored to top', () {
      final offset = LayoutAnchor.top.offset(size);
      expect(offset, equals(Offset(-50, 0)));
    });

    test('center returns offset anchored to center', () {
      final offset = LayoutAnchor.center.offset(size);
      expect(offset, equals(Offset(-50, -25)));
    });

    test('all anchors share the same x offset', () {
      final bottomX = LayoutAnchor.bottom.offset(size).dx;
      final topX = LayoutAnchor.top.offset(size).dx;
      final centerX = LayoutAnchor.center.offset(size).dx;
      expect(bottomX, equals(topX));
      expect(topX, equals(centerX));
    });

    test('bottom y offset equals negative height', () {
      final offset = LayoutAnchor.bottom.offset(Size(200, 80));
      expect(offset.dy, equals(-80));
    });
  });
}
