import '../context.dart';

extension ImageContextExtension on Context {
  bool hasImage(String imageName) =>
      tileSource.spriteIndex?.spriteByName[imageName] != null;
}
