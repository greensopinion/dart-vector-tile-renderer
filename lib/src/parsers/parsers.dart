import 'dart:ui';

import 'package:vector_tile_renderer/src/expressions/expression.dart';

import 'boolean.dart';
import 'color.dart';
import 'double.dart';
import 'parser.dart';

final Map<Type, Parser> _parsers = {
  double: DoubleParser(),
  bool: BooleanParser(),
  Color: ColorParser(),
};

/// The common parser has no logic for parsing any special cases and can serve
///  as a parser for everything not specified in _parsers.
class CommonParser<T> extends Parser<T> {
  parseSpecial(data) => null;
}

Parser<T> parserFor<T>() {
  if (!_parsers.containsKey(T)) {
    return CommonParser();
  }

  return _parsers[T] as Parser<T>;
}

Expression<T>? parse<T>(dynamic data) => parserFor<T>().parse(data);
