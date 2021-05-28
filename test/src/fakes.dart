import 'package:test/fake.dart';
import 'package:dart_vector_tile_renderer/renderer.dart';

class FakeVectorTileLayer extends Fake implements VectorTileLayer {
  final String _name;

  FakeVectorTileLayer(this._name);

  @override
  String get name => _name;
}
