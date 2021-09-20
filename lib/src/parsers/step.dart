import 'package:vector_tile_renderer/src/expressions/expression.dart';
import 'package:vector_tile_renderer/src/expressions/step_expression.dart';
import 'package:vector_tile_renderer/src/extensions.dart';

import 'parser.dart';
import 'parsers.dart' as Parsers;

class StepParser<T> extends Parser<T> {
  @override
  Expression<T>? parseSpecial(data) {
    if (data is! List) return null;

    final input = Parsers.parse<double>(data[1])!;

    final base = Parsers.parse<T>(data[2])!;

    final chunks = data.skip(3).chunk(2).map((chunk) {
      final step = chunk[0];
      final value = Parsers.parse<T>(chunk[1]);

      return Step<T>(step, value);
    });

    return StepExpression<T>(input, base, chunks);
  }
}
