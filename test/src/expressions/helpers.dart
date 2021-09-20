import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/expressions/expression.dart';

void expectEvaluated<T>(Expression<T> actual, dynamic expected,
    [Map<String, dynamic> args = const {}]) {
  final evaluated = actual.evaluate(args);
  expect(evaluated, expected);
}
