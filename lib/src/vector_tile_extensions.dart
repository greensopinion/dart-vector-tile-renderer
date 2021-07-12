import '../vector_tile_renderer.dart';

import 'extensions.dart';

extension VectorTileFeatureExtension on VectorTileFeature {
  String? stringProperty(String name) {
    final properties = decodeProperties();
    return properties
        .map((e) => e[name])
        .whereType<VectorTileValue>()
        .firstOrNull()
        ?.stringValue;
  }
}
