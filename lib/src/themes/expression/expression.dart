import '../../logger.dart';
import '../../model/tile_model.dart';

export 'expression_parser.dart';

class EvaluationContext {
  final Map<String, dynamic> Function() _properties;
  final TileFeatureType _featureType;
  final double zoom;
  final Logger logger;

  EvaluationContext(
      this._properties, this._featureType, this.zoom, this.logger);

  getProperty(String name) {
    if (name == '\$type') {
      return _typeName();
    } else if (name == 'zoom') {
      return zoom;
    }
    final properties = _properties();
    return properties[name];
  }

  _typeName() {
    switch (_featureType) {
      case TileFeatureType.point:
        return 'Point';
      case TileFeatureType.linestring:
        return 'LineString';
      case TileFeatureType.polygon:
        return 'Polygon';
    }
  }
}

abstract class Expression {
  final String cacheKey;

  Expression(this.cacheKey);

  evaluate(EvaluationContext context);

  DoubleExpression asDoubleExpression() => DoubleExpression(this);

  @override
  String toString() => cacheKey;

  /// the names of properties accessed by this expression
  Set<String> properties();
}

class DoubleExpression extends Expression {
  final Expression _delegate;

  DoubleExpression(this._delegate) : super('double(${_delegate.cacheKey})');

  double? evaluate(EvaluationContext context) {
    final result = _delegate.evaluate(context);
    if (result is num) {
      return result.toDouble();
    } else if (result != null) {
      context.logger.warn(() => 'expected double but got $result');
    }
  }

  @override
  Set<String> properties() => _delegate.properties();
}

class UnsupportedExpression extends Expression {
  final dynamic _json;

  UnsupportedExpression(this._json) : super('unsupported');

  get json => _json;

  @override
  evaluate(EvaluationContext context) => null;

  @override
  Set<String> properties() => {};
}

class NotNullExpression extends Expression {
  final Expression _delegate;

  NotNullExpression(this._delegate) : super('notNull(${_delegate.cacheKey})');

  @override
  evaluate(EvaluationContext context) => _delegate.evaluate(context) != null;

  @override
  Set<String> properties() => _delegate.properties();
}

class NotExpression extends Expression {
  final Expression _delegate;

  NotExpression(this._delegate) : super('!${_delegate.cacheKey}');

  @override
  evaluate(EvaluationContext context) {
    final operand = _delegate.evaluate(context);
    if (operand is bool) {
      return !operand;
    }
    context.logger.warn(() => 'NotExpression expected bool but got $operand');
    return null;
  }

  @override
  Set<String> properties() => _delegate.properties();
}

class EqualsExpression extends Expression {
  final Expression _first;
  final Expression _second;

  EqualsExpression(this._first, this._second)
      : super('equals(${_first.cacheKey},${_second.cacheKey})');

  @override
  evaluate(EvaluationContext context) {
    return _first.evaluate(context) == _second.evaluate(context);
  }

  @override
  Set<String> properties() => {..._first.properties(), ..._second.properties()};
}

class InExpression extends Expression {
  final Expression _first;
  final List _values;

  InExpression(this._first, this._values)
      : super('(${_first.cacheKey} in [${_values.join(',')}])');

  @override
  evaluate(EvaluationContext context) {
    final first = _first.evaluate(context);
    return _values.any((e) => first == e);
  }

  @override
  Set<String> properties() => _first.properties();
}

class AnyExpression extends Expression {
  final List<Expression> _delegates;

  AnyExpression(this._delegates)
      : super('(any [${_delegates.map((e) => e.cacheKey).join(',')}])');

  @override
  evaluate(EvaluationContext context) {
    for (final delegate in _delegates) {
      final val = delegate.evaluate(context);
      if (!(val is bool)) {
        context.logger.warn(() => 'AnyExpression expected bool but got $val');
      } else if (val) {
        return true;
      }
    }
    return false;
  }

  @override
  Set<String> properties() {
    final accumulator = <String>{};
    for (final delegate in _delegates) {
      accumulator.addAll(delegate.properties());
    }
    return accumulator;
  }
}

class AllExpression extends Expression {
  final List<Expression> _delegates;

  AllExpression(this._delegates)
      : super('(all [${_delegates.map((e) => e.cacheKey).join(',')}])');

  @override
  evaluate(EvaluationContext context) {
    for (final delegate in _delegates) {
      final val = delegate.evaluate(context);
      if (!(val is bool)) {
        context.logger.warn(() => 'AllExpression expected bool but got $val');
      } else if (!val) {
        return false;
      }
    }
    return true;
  }

  @override
  Set<String> properties() {
    final accumulator = <String>{};
    for (final delegate in _delegates) {
      accumulator.addAll(delegate.properties());
    }
    return accumulator;
  }
}

class ToStringExpression extends Expression {
  final Expression _delegate;

  ToStringExpression(this._delegate) : super('toString(${_delegate.cacheKey})');

  @override
  evaluate(EvaluationContext context) =>
      _delegate.evaluate(context)?.toString() ?? '';

  @override
  Set<String> properties() => _delegate.properties();
}
