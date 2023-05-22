import 'dart:convert';

import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/themes/sprite_reader.dart';

import '../test_files.dart';
import '../test_logger.dart';

void main() {
  test('reads a sprite index', () async {
    final index = SpriteIndexReader(logger: testLogger).read(
        jsonDecode(utf8.decode(await readTestFile('sample_sprites.json'))));
    expect(index, isNotNull);
    final firstSprite = index.spriteByName['first-sprite']!;
    expect(firstSprite.x, 0);
    expect(firstSprite.y, 0);
    expect(firstSprite.height, 128);
    expect(firstSprite.width, 128);
    expect(firstSprite.content, isNull);
    expect(firstSprite.stretchX, [
      [0, 128]
    ]);
    expect(firstSprite.stretchY, [
      [0, 128]
    ]);
    final secondSprite = index.spriteByName['second-sprite']!;
    expect(secondSprite.x, 120);
    expect(secondSprite.y, 128);
    expect(secondSprite.height, 80);
    expect(secondSprite.width, 40);
    expect(secondSprite.content, [0, 34, 40, 46]);
    expect(secondSprite.stretchX, [
      [0, 40]
    ]);
    expect(secondSprite.stretchY, [
      [0, 80]
    ]);
  });
}
