import 'package:vector_tile_renderer/src/expressions/argument_expression.dart';
import 'package:vector_tile_renderer/src/expressions/expression.dart';
import 'package:vector_tile_renderer/src/expressions/value_expression.dart';
import 'package:vector_tile_renderer/src/logger.dart';
import 'package:vector_tile_renderer/src/parsers/match.dart';

import 'case.dart';
import 'coalesce.dart';
import 'step.dart';

abstract class Parser<T> {
  Expression<T>? parseSpecial(dynamic data);
  Expression<T>? preCommon(dynamic data) {}

  Expression<T>? parse(dynamic data) {
    if (data == null) return null;

    final preCommonResult = preCommon(data);
    if (preCommonResult != null) {
      return preCommonResult;
    }

    final common = _parseCommonExpressions(data);

    final result = common ?? parseSpecial(data);
    if (result == null) {
      Logger.console().warn(
        () =>
            '[dart_vector_tile_renderer] Could not parse $data to an expression',
      );
    }

    return result;
  }

  Expression<T>? _parseCommonExpressions(dynamic data) {
    if (data is T && T != dynamic) return ValueExpression(data);

    if (data is! List) {
      return null;
    }

    if (data[0] == 'case') return CaseParser<T>().parseSpecial(data);
    if (data[0] == 'coalesce') return CoalesceParser<T>().parseSpecial(data);
    if (data[0] == 'get') return ArgumentExpression<T>(data[1]);
    if (data[0] == 'match') return MatchParser<T>().parseSpecial(data);
    if (data[0] == 'step') return StepParser<T>().parseSpecial(data);
    if (data[0] == 'zoom') return ArgumentExpression<T>('zoom');

    return null;
  }
}
