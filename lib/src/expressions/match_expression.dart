import 'package:vector_tile_renderer/src/expressions/expression.dart';

class Match<Input, Output> {
  final dynamic input;
  final Expression<Output>? output;

  Match(this.input, this.output)
      : assert(input is List<Input> || input is Input);
}

class MatchExpression<Output, Input> extends Expression<Output> {
  final Expression<Input>? _compare;
  final Iterable<Match<Input, Output>> _matches;
  final Expression<Output>? _fallback;

  MatchExpression(this._compare, this._matches, this._fallback);

  @override
  Output? evaluate(Map<String, dynamic> args) {
    final compare = _compare?.evaluate(args);
    if (compare == null) {
      return _fallback?.evaluate(args);
    }

    for (final match in _matches) {
      final input = match.input;
      if (input == compare ||
          (input is List && match.input.contains(compare))) {
        return match.output?.evaluate(args);
      }
    }

    return _fallback?.evaluate(args);
  }
}
