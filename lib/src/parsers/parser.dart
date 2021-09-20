import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:vector_tile_renderer/src/expressions/argument_expression.dart';
import 'package:vector_tile_renderer/src/expressions/expression.dart';
import 'package:vector_tile_renderer/src/expressions/value_expression.dart';
import 'package:vector_tile_renderer/src/parsers/match.dart';

import 'case.dart';
import 'coalesce.dart';
import 'step.dart';

abstract class ExpressionParser<T> {
  @protected
  Expression<T>? parse(dynamic data);

  @nonVirtual
  Expression<T>? parseExpression(dynamic data) {
    if (data == null) return null;

    final common = _parseCommonExpressions(data);

    final result = common ?? parse(data);
    assert(
      result != null,
      '[dart_vector_tile_renderer] Could not parse $data to an expression',
    );

    return result;
  }

  Expression<T>? _parseCommonExpressions(dynamic data) {
    if (data is T && T != dynamic) return ValueExpression(data);

    if (data is! List) {
      return null;
    }

    assert(
      data.length > 0,
      'Failed to parse expression $data; expected at least one element',
    );

    if (data[0] == 'case') return CaseParser<T>().parse(data);
    if (data[0] == 'coalesce') return CoalesceParser<T>().parse(data);
    if (data[0] == 'get') return ArgumentExpression<T>(data[1]);
    if (data[0] == 'match') return MatchParser<T>().parse(data);
    if (data[0] == 'step') return StepParser<T>().parse(data);
    if (data[0] == 'zoom') return ArgumentExpression<T>('zoom');

    return null;
  }
}
