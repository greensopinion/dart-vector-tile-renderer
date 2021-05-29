import 'package:test/test.dart';
import 'package:dart_vector_tile_renderer/src/themes/color_parser.dart';

void main() {
  test('parses an RGB color', () {
    final color = ColorParser.parse('#90d86c');
    expect(color, isNotNull);
    expect(color!.alpha, 0xff);
    expect(color.red, 0x90);
    expect(color.green, 0xd8);
    expect(color.blue, 0x6c);
  });
  test('parses an hsl color', () {
    final color = ColorParser.parse('hsl(248, 7%, 66%)');
    expect(color, isNotNull);
    expect(color!.alpha, 0xff);
    expect(color.red, 0xA4);
    expect(color.green, 0xA2);
    expect(color.blue, 0xAE);
  });
  test('parses an hsla color', () {
    final color = ColorParser.parse('hsla(96, 40%, 49%, 0.36)');
    expect(color, isNotNull);
    expect(color!.alpha, 92);
    expect(color.red, 0x73);
    expect(color.green, 0xAF);
    expect(color.blue, 0x4B);
  });
}
