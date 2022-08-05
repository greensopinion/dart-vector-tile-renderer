import 'dart:io';

import 'package:test/test.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';
import 'extensions.dart';
import 'package:http/http.dart' as http;

void main() {
  //
  test('introspects a vector tile', () async {
    final response = await http.get(Uri.parse(
        'https://a.tile.thunderforest.com/thunderforest.outdoors-v2/12/650/1405.vector.pbf?apikey=02345b18d4b2430b8ca6d24c22e6c0aa'));
    expect(response.statusCode, 200);
    final bytes = response.bodyBytes;
    final tile = VectorTileReader().read(bytes);
    final introspectedLayers =
        tile.layers.map((layer) => introspectLayer(layer)).toList();
    final result = introspectedLayers.sorted().join("\n");
    print(result);
  });
}

String introspectLayer(VectorTileLayer layer) {
  return "${layer.name}\n${_introspectLayerFeatures(layer)}";
}

String _introspectLayerFeatures(VectorTileLayer layer) {
  final featureDetailsByType = <String, _FeatureDetails>{};
  layer.features.forEach((feature) {
    var details = featureDetailsByType[_typeName(feature.type)];
    if (details == null) {
      details = _FeatureDetails();
      featureDetailsByType[_typeName(feature.type)] = details;
    }
    final properties = feature.decodeProperties();
    details.propertyNames.addAll(properties.keys);
    properties.forEach((key, value) {
      if (_classifiedPropertyNames.contains(key) && value.stringValue != null) {
        var propertyValues = details!.valuesByPropertyName[key];
        if (propertyValues == null) {
          propertyValues = <String>{};
          details.valuesByPropertyName[key] = propertyValues;
        }
        propertyValues.add(value.stringValue);
      }
    });
  });
  return featureDetailsByType.keys.toList().sorted().map((typeName) {
    final details = featureDetailsByType[typeName]!;
    return "\t$typeName\n\t\t${details.propertyNames.toList().sorted().map((e) {
      final values = details.valuesByPropertyName[e];
      if (values != null && !values.isEmpty) {
        return "$e: ${values.toList().sorted().join(", ")}";
      }
      return e;
    }).join("\n\t\t")}";
  }).join("\n");
}

String _typeName(VectorTileGeomType? type) {
  switch (type) {
    case null:
      return "null";
    case VectorTileGeomType.UNKNOWN:
      return "unknown";
    case VectorTileGeomType.POINT:
      return "point";
    case VectorTileGeomType.LINESTRING:
      return "linestring";
    case VectorTileGeomType.POLYGON:
      return "polygon";
  }
}

class _FeatureDetails {
  final propertyNames = <String>{};
  final valuesByPropertyName = <String, Set<String?>>{};
}

final _classifiedPropertyNames = {
  "class",
  "type",
  "tunnel",
  "bridge",
  "admin_level"
};
