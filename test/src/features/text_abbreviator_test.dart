import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/features/text_abbreviator.dart';

void main() {
  final abbreviator = TextAbbreviator();
  test('abbreviates road names', () {
    expect(abbreviator.abbreviate('Some Road'), 'Some Rd');
    expect(abbreviator.abbreviate('Some Crescent'), 'Some Cres');
  });
  test('does not abbreviate other words', () {
    expect(abbreviator.abbreviate('Crescent Road'), 'Crescent Rd');
    expect(abbreviator.abbreviate('Road Road'), 'Road Rd');
  });
}
