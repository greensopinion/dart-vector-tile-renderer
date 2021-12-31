import '../vector_tile_renderer.dart';

extension VectorTileFeatureExtension on VectorTileFeature {
  String? stringProperty(String name) {
    final properties = decodeProperties();
    return properties[name]?.stringValue;
  }
}
