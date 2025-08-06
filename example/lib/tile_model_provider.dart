import 'package:vector_tile_renderer/vector_tile_renderer.dart';

class ExampleTileModelProvider extends SceneTileModelProvider {
  final Tileset tileset;
  final Theme theme;

  ExampleTileModelProvider(this.tileset, this.theme);

  @override
  SceneTileData? getModel(SceneTileIdentity tile) => ExampleSceneTileData(theme, tileset);
}

class ExampleSceneTileData extends SceneTileData {
  final Theme _theme;
  final Tileset _tileset;

  ExampleSceneTileData(this._theme, this._tileset);

  @override
  bool get disposed => false;

  @override
  String key() => 'z=0,x=0,y=0';

  @override
  RasterTileset? get rasterTileset => null;

  @override
  Theme get theme => _theme;

  @override
  Tileset? get tileset => _tileset;
}