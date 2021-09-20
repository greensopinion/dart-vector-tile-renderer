import 'package:vector_tile_renderer/src/expressions/expression.dart';
import 'package:vector_tile_renderer/src/expressions/step_expression.dart';
import 'package:vector_tile_renderer/src/extensions.dart';

import 'parser.dart';
import 'parsers.dart' as Parsers;

class StepParser<T> extends ExpressionParser<T> {
  @override
  Expression<T>? parse(data) {
    if (data is! List) return null;

    assert(
      data.length >= 3 && data.length.isOdd,
      'Case expressions must have an odd amount of fields and be at least 3 '
      'fields long: The string literal "step", followed by a numeric value '
      'expression as input, followed by the baseline output, followed by pairs '
      'of input-steps and their respective output values.\n'
      'See https://docs.mapbox.com/mapbox-gl-js/style-spec/expressions/#step for more information.\n'
      'Failed parsing on expression $data',
    );

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
