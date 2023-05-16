import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/themes/color_parser.dart';

void main() {
  test('parses a hex RGB color', () {
    final color = ColorParser.toColor('#90d86c');
    expect(color, isNotNull);
    expect(color!.alpha, 0xff);
    expect(color.red, 0x90);
    expect(color.green, 0xd8);
    expect(color.blue, 0x6c);
  });

  test('parses an RGB color', () {
    final color = ColorParser.toColor('rgb(239, 238,12)');
    expect(color, isNotNull);
    expect(color!.alpha, 0xff);
    expect(color.red, 239);
    expect(color.green, 238);
    expect(color.blue, 12);
  });

  test('parses an RGBA color with numeric alpha', () {
    final color = ColorParser.toColor('rgba(239, 238, 12, 0.36)');
    expect(color, isNotNull);
    expect(color!.alpha, 92);
    expect(color.red, 239);
    expect(color.green, 238);
    expect(color.blue, 12);
  });

  test('parses an RGBA color with floating point alpha', () {
    final floatAlphaColor = ColorParser.toColor('rgba(239, 238, 12, 0.36)');
    final percentAlphaColor = ColorParser.toColor('rgba(239, 238, 12, 36%)');
    expect(floatAlphaColor, percentAlphaColor);
  });

  test('parses an hsl color', () {
    final color = ColorParser.toColor('hsl(248, 7%, 66%)');
    expect(color, isNotNull);
    expect(color!.alpha, 0xff);
    expect(color.red, 0xA4);
    expect(color.green, 0xA2);
    expect(color.blue, 0xAE);
  });

  test('parses an hsla color with floating point alpha', () {
    final color = ColorParser.toColor('hsla(96, 40%, 49%, 0.36)');
    expect(color, isNotNull);
    expect(color!.alpha, 92);
    expect(color.red, 0x73);
    expect(color.green, 0xAF);
    expect(color.blue, 0x4B);
  });

  test('parses an hsla color with percentage alpha', () {
    final floatAlphaColor = ColorParser.toColor('hsla(96, 40%, 49%, 0.36)');
    final percentAlphaColor = ColorParser.toColor('hsla(96, 40%, 49%, 36%)');
    expect(floatAlphaColor, percentAlphaColor);
  });
}
