class SpriteIndex {
  final Map<String, Sprite> spriteByName;

  const SpriteIndex(this.spriteByName);
}

class Sprite {
  final String name;
  final int width;
  final int height;
  final int x;
  final int y;
  final int pixelRatio;
  final List<int>? content;
  final List<List<int>> stretchX;
  final List<List<int>> stretchY;

  Sprite(
      {required this.name,
      required this.width,
      required this.height,
      required this.x,
      required this.y,
      required this.pixelRatio,
      this.content,
      required this.stretchX,
      required this.stretchY});
}
