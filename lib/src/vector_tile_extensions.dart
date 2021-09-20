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

  Map<String, VectorTileValue> get collectedProperties {
    final properties = decodeProperties();
    Map<String, VectorTileValue> result = {};
    for (final propertyList in properties) {
      result = {...result, ...propertyList};
    }

    return result;
  }
}
