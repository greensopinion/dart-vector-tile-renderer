import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/features/text_wrapper.dart';

void main() {
  test('does not wrap text within bounds', () {
    expect(wrapText('some text', 6.5, 10), ['some text']);
  });
  test('wraps text', () {
    expect(wrapText('ocean park', 20.0, 8), ['ocean', 'park']);
  });
  test('wraps text with multiple words', () {
    expect(wrapText('sunnyside acres urban forest park', 14.0, 10),
        ['sunnyside acres', 'urban forest park']);
  });
}
