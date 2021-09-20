import 'package:vector_tile_renderer/src/expressions/expression.dart';
import 'package:vector_tile_renderer/src/expressions/match_expression.dart';
import 'package:vector_tile_renderer/src/extensions.dart';

import 'parser.dart';
import 'parsers.dart' as Parsers;

class MatchParser<T> extends Parser<T> {
  @override
  Expression<T>? parseSpecial(data) {
    if (data is! List) {
      return null;
    }

    final copy = [...data];
    final inputType = _findInputType(copy);

    if (inputType == double) {
      return _parse<double>(copy);
    }

    if (inputType == String) {
      return _parse<String>(copy);
    }

    return null;
  }

  Expression<T>? _parse<Input>(List data) {
    final input = Parsers.parse<Input>(data[1]);
    final fallback = Parsers.parse<T>(data.removeLast());

    final matchChunks = data.skip(2).chunk(2);
    final matches = matchChunks.map((chunk) {
      final matchInput = chunk[0];
      final compareExpression = Parsers.parse<T>(chunk[1]);

      return Match<Input, T>(matchInput, compareExpression);
    });

    return MatchExpression<T, Input>(input, matches, fallback);
  }

  Type _findInputType(List data) {
    final referenceField = data[2];

    var type = referenceField.runtimeType;
    if (referenceField is List) {
      type = referenceField[0].runtimeType;
    }

    if (type == num) {
      type = double;
    }

    if (type == String || type == double) {
      return type;
    }

    throw ArgumentError(
      "$data does not appear to contain a valid match "
      "expression. Make sure that the input labels are either literal numbers"
      " or strings or lists of one of the two. "
      "See https://docs.mapbox.com/mapbox-gl-js/style-spec/expressions/#match",
    );
  }
}
