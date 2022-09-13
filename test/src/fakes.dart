import 'package:test/fake.dart';
import 'package:vector_tile/vector_tile.dart';

class FakeVectorTileLayer extends Fake implements VectorTileLayer {
  final String _name;

  FakeVectorTileLayer(this._name);

  @override
  String get name => _name;
}
