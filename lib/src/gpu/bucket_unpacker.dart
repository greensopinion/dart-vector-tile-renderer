import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';

import '../tileset_raster.dart';
import 'background/background_geometry.dart';
import 'gpu_map_settings.dart';
import 'colored_material.dart';
import 'line/line_geometry.dart';
import 'line/line_material.dart';
import 'polygon/polygon_geometry.dart';
import 'raster/raster_layer_builder.dart';
import 'text/text_geometry.dart';
import 'text/text_material.dart';
import 'texture_provider.dart';
import 'tile_render_data.dart';

class BucketUnpacker {
  final TextureProvider textureProvider;
  final RasterTileset rasterTileset;

  BucketUnpacker(this.textureProvider, this.rasterTileset);

  /// Keep all layer depths inside Impeller's [0, 1] clip-space z range while
  /// making layer order dominate flutter_scene's translucent depth sort.
  static const _maxLayerDepth = 0.95;

  void unpackOnto(Node parent, TileRenderData bucket) {
    final layerCount = bucket.data.length;
    var layer = 0;
    for (var packedMesh in bucket.data) {
      final layerDepth = layerCount <= 1
          ? 0.0
          : _maxLayerDepth * (layerCount - 1 - layer) / (layerCount - 1);
      final layerTransform =
          Matrix4.translation(Vector3(0, 0, layerDepth));
      if (packedMesh.geometry.type == GeometryType.raster) {
        final node = Node(localTransform: layerTransform)
          ..frustumCulled = GpuMapSettings.frustumCulling;
        parent.add(node);
        RasterLayerBuilder().build(node, packedMesh.geometry.uniform!,
            packedMesh.material.uniform!, rasterTileset);
      } else {
        parent.add(Node(
          localTransform: layerTransform,
          mesh: Mesh(_unpackGeometry(packedMesh.geometry),
              _unpackMaterial(packedMesh.material)),
        )..frustumCulled = GpuMapSettings.frustumCulling);
      }
      layer++;
    }
  }

  Material _unpackMaterial(PackedMaterial packed) =>
      _materialConstructors[packed.type.index]!.call(packed, textureProvider);

  Geometry _unpackGeometry(PackedGeometry packed) =>
      _geometryConstructors[packed.type.index]!.call(packed);
}

enum GeometryType {
  line,
  polygon,
  background,
  raster,
  text;
}

enum MaterialType {
  line,
  colored,
  raster,
  text,
}

final _geometryTypeToConstructor = {
  GeometryType.line: (a) => LineGeometry(a),
  GeometryType.polygon: (a) => PolygonGeometry(a),
  GeometryType.background: (a) => BackgroundGeometry(),
  GeometryType.raster: (a) => throw UnimplementedError(),
  GeometryType.text: (a) => TextGeometry(a)
};

final _geometryConstructors =
    GeometryType.values.map((v) => _geometryTypeToConstructor[v]).toList();

final _materialTypeToConstructor = {
  MaterialType.line: (a, b) => LineMaterial(a),
  MaterialType.colored: (a, b) => ColoredMaterial(a),
  MaterialType.raster: (a, b) => throw UnimplementedError(),
  MaterialType.text: (a, b) => TextMaterial(a, b),
};

final _materialConstructors =
    MaterialType.values.map((v) => _materialTypeToConstructor[v]).toList();
