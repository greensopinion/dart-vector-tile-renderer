import 'package:vector_tile_renderer/src/expressions/argument_expression.dart';
import 'package:vector_tile_renderer/src/expressions/expression.dart';
import 'package:vector_tile_renderer/src/parsers/parsers.dart';

class StringParser extends CommonParser<String> {
  @override
  Expression<String>? preCommon(data) {
    if (data is! String) {
      return null;
    }

    final match = RegExp(r'\{(.+?)\}').firstMatch(data);
    if (match != null) {
      final fieldName = match.group(1);
      if (fieldName != null) {
        return ArgumentExpression<String>(fieldName);
      }
    }
  }
}
