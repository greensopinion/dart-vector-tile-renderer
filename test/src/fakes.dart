import 'package:test/fake.dart';
import 'package:tile_inator/tile_inator.dart';

class FakeVectorTileLayer extends Fake implements VectorTileLayer {
  final String _name;

  FakeVectorTileLayer(this._name);

  @override
  String get name => _name;
}
