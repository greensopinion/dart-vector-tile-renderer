import 'package:vector_tile_renderer/src/expressions/case_expression.dart';
import 'package:vector_tile_renderer/src/expressions/expression.dart';
import 'package:vector_tile_renderer/src/extensions.dart';

import 'parser.dart';
import 'parsers.dart' as Parsers;

class CaseParser<T> extends ExpressionParser<T> {
  @override
  Expression<T>? parse(data) {
    if (data is! List) {
      return null;
    }

    final copy = [...data];

    assert(
      copy.length.isEven && copy.length >= 4,
      'Case expressions must have an even amount of fields: The string literal '
      '"case" followed by pairs of condition and value and finally the default '
      'value.\n'
      'See https://docs.mapbox.com/mapbox-gl-js/style-spec/expressions/#case for more information.\n'
      'Failed parsing on expression $data',
    );

    final fallback = Parsers.parse<T>(copy.removeLast());

    final cases = copy.skip(1).chunk(2).map((chunk) {
      final condition = Parsers.parse<bool>(chunk[0])!;
      final output = Parsers.parse<T>(chunk[1]);

      return Case<T>(condition, output);
    });

    return CaseExpression<T>(cases, fallback);
  }
}
