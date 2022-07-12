import '../../logger.dart';
import '../../model/tile_model.dart';
import 'property_accumulator.dart';

export 'expression_parser.dart';

class EvaluationContext {
  final Map<String, dynamic> Function() _properties;
  final TileFeatureType _featureType;
  final double zoom;
  final double zoomScaleFactor;
  final Logger logger;

  EvaluationContext(this._properties, this._featureType, this.logger,
      {required this.zoom, required this.zoomScaleFactor});

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
      case TileFeatureType.background:
        return 'Background';
    }
  }
}

abstract class Expression<T> {
  final String cacheKey;
  late final Set<String> _properties;

  Expression(this.cacheKey, Set<String> properties) {
    _properties = Set.unmodifiable(properties);
  }

  T? evaluate(EvaluationContext context);

  @override
  String toString() => cacheKey;

  /// the names of properties accessed by this expression
  Set<String> properties() => _properties;

  bool get isConstant;
}

class UnsupportedExpression extends Expression {
  final dynamic _json;

  UnsupportedExpression(this._json) : super('unsupported', <String>{});

  get json => _json;

  @override
  evaluate(EvaluationContext context) => null;

  @override
  bool get isConstant => true;
}

class NotNullExpression extends Expression {
  final Expression _delegate;

  NotNullExpression(this._delegate)
      : super('notNull(${_delegate.cacheKey})', _delegate.properties());

  @override
  evaluate(EvaluationContext context) => _delegate.evaluate(context) != null;

  @override
  bool get isConstant => _delegate.isConstant;
}

class NotExpression extends Expression {
  final Expression _delegate;

  NotExpression(this._delegate)
      : super('!${_delegate.cacheKey}', _delegate.properties());

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
  bool get isConstant => _delegate.isConstant;
}

class EqualsExpression extends Expression {
  final Expression _first;
  final Expression _second;

  EqualsExpression(this._first, this._second)
      : super('equals(${_first.cacheKey},${_second.cacheKey})',
            {..._first.properties(), ..._second.properties()});

  @override
  evaluate(EvaluationContext context) {
    return _first.evaluate(context) == _second.evaluate(context);
  }

  @override
  bool get isConstant => _first.isConstant && _second.isConstant;
}

class InExpression extends Expression {
  final Expression _first;
  final List _values;

  InExpression(this._first, this._values)
      : super('(${_first.cacheKey} in [${_values.join(',')}])',
            _first.properties());

  @override
  evaluate(EvaluationContext context) {
    final first = _first.evaluate(context);
    return _values.any((e) => first == e);
  }

  @override
  bool get isConstant => _first.isConstant;
}

class AnyExpression extends Expression {
  final List<Expression> _delegates;

  AnyExpression(this._delegates)
      : super('(any [${_delegates.map((e) => e.cacheKey).join(',')}])',
            _delegates.joinProperties());

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
  bool get isConstant => !_delegates.any((e) => !e.isConstant);
}

class AllExpression extends Expression {
  final List<Expression> _delegates;

  AllExpression(this._delegates)
      : super('(all [${_delegates.map((e) => e.cacheKey).join(',')}])',
            _delegates.joinProperties());

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
  bool get isConstant => !_delegates.any((e) => !e.isConstant);
}

class ToStringExpression extends Expression {
  final Expression _delegate;

  ToStringExpression(this._delegate)
      : super('toString(${_delegate.cacheKey})', _delegate.properties());

  @override
  evaluate(EvaluationContext context) =>
      _delegate.evaluate(context)?.toString() ?? '';

  @override
  bool get isConstant => _delegate.isConstant;
}
