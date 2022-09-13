import 'package:vector_tile/vector_tile.dart';

extension VectorTileFeatureExtension on VectorTileFeature {
  String? stringProperty(String name) {
    final properties = decodeProperties();
    return properties[name]?.stringValue;
  }
}
