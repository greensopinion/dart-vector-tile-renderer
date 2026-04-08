import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/themes/style.dart';

void main() {
  group('LayoutAnchor', () {
    test('values contains bottom', () {
      expect(LayoutAnchor.values(), contains(LayoutAnchor.bottom));
    });

    test('fromName resolves bottom', () {
      expect(LayoutAnchor.fromName('bottom'), equals(LayoutAnchor.bottom));
    });

    test('fromName resolves top', () {
      expect(LayoutAnchor.fromName('top'), equals(LayoutAnchor.top));
    });

    test('fromName resolves center', () {
      expect(LayoutAnchor.fromName('center'), equals(LayoutAnchor.center));
    });

    test('fromName returns DEFAULT for null', () {
      expect(LayoutAnchor.fromName(null), equals(LayoutAnchor.DEFAULT));
    });

    test('fromName returns DEFAULT for unknown name', () {
      expect(LayoutAnchor.fromName('unknown'), equals(LayoutAnchor.DEFAULT));
    });

    test('bottom has correct name', () {
      expect(LayoutAnchor.bottom.name, equals('bottom'));
    });
  });
}
