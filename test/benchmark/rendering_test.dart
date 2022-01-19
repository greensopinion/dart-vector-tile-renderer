import 'dart:ui';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:vector_tile_renderer/src/constants.dart';
import 'package:vector_tile_renderer/src/themes/light_theme.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../src/test_tile.dart';

Picture _renderPicture({
  required Theme theme,
  required double scale,
  required Tileset tileset,
  required double zoom,
}) {
  assert(scale >= 1 && scale <= 4);

  double size = scale * tileSize;
  final rect = Rect.fromLTRB(0, 0, size, size);

  final recorder = PictureRecorder();
  final canvas = Canvas(recorder, rect);
  canvas.clipRect(rect);
  canvas.scale(scale.toDouble(), scale.toDouble());

  Renderer(theme: theme).render(
    canvas,
    tileset,
    zoomScaleFactor: scale,
    zoom: zoom,
  );

  return recorder.endRecording();
}

class RenderPicture extends BenchmarkBase {
  RenderPicture({
    required this.zoom,
    required this.preprocessTile,
  }) : super('RenderPicture('
            'zoom: $zoom, '
            'preprocessTile: $preprocessTile'
            ')');

  static Future<void> setupAll() async {
    testTile = await readTestTile(ThemeReader().read(lightThemeData()));
  }

  static late final Tile testTile;

  final double zoom;
  final bool preprocessTile;

  late final Theme theme;
  late final Tileset tileset;

  @override
  void setup() {
    theme = ThemeReader().read(lightThemeData());
    final tileset = Tileset({'openmaptiles': testTile});

    this.tileset = preprocessTile
        ? TilesetPreprocessor(theme).preprocess(tileset)
        : tileset;
  }

  @override
  void run() => _renderPicture(
        theme: theme,
        tileset: tileset,
        scale: 1,
        zoom: zoom,
      );
}

Future<void> main() async {
  await RenderPicture.setupAll();

  final benchmarks = [
    for (final zoom in <double>[0, 12, 24]) ...[
      RenderPicture(zoom: zoom, preprocessTile: false),
      RenderPicture(zoom: zoom, preprocessTile: true),
    ]
  ];

  for (final benchmark in benchmarks) {
    benchmark.report();
  }
}
