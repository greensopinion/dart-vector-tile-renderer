import 'package:vector_tile_renderer/src/expressions/case_expression.dart';
import 'package:vector_tile_renderer/src/expressions/expression.dart';
import 'package:vector_tile_renderer/src/extensions.dart';

import 'parser.dart';
import 'parsers.dart' as Parsers;

class CaseParser<T> extends Parser<T> {
  @override
  Expression<T>? parseSpecial(data) {
    if (data is! List) {
      return null;
    }

    final copy = [...data];
    final fallback = Parsers.parse<T>(copy.removeLast());

    final cases = copy.skip(1).chunk(2).map((chunk) {
      final condition = Parsers.parse<bool>(chunk[0])!;
      final output = Parsers.parse<T>(chunk[1]);

      return Case<T>(condition, output);
    });

    return CaseExpression<T>(cases, fallback);
  }
}
