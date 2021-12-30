import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/themes/expression/expression.dart';
import 'package:fixnum/fixnum.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

void main() {
  final _parser = ExpressionParser(Logger.noop());

  final _properties = [
    {
      'a-string': VectorTileValue(stringValue: 'a-string-value'),
      'another-string': VectorTileValue(stringValue: 'another-string-value')
    },
    {
      'a-bool': VectorTileValue(boolValue: true),
      'a-false-bool': VectorTileValue(boolValue: false)
    },
    {
      'an-int': VectorTileValue(intValue: Int64(33)),
      'a-double': VectorTileValue(doubleValue: 13.2)
    }
  ];
  final _context = EvaluationContext(() => _properties, Logger.noop());

  test('parses an unsupported expression', () {
    final json = {'not-supported': true};
    final expression = _parser.parse(json);
    expect(expression, isA<UnsupportedExpression>());
    expect(expression.evaluate(_context), isNull);
    expect((expression as UnsupportedExpression).json, equals(json));
  });

  test('supports operators', () {
    expect(
        _parser.supportedOperators().toList()..sort(),
        equals([
          '!',
          '!=',
          '!has',
          '!in',
          '<',
          '<=',
          '==',
          '>',
          '>=',
          'get',
          'has',
          'in'
        ]));
  });

  group('literal expressions:', () {
    void _assertLiteral(dynamic value) {
      final expression = _parser.parse(value);
      expect(expression.evaluate(_context), equals(value));
    }

    test('parses a string', () {
      _assertLiteral('a string');
      _assertLiteral('another string');
    });

    test('parses a boolean', () {
      _assertLiteral(true);
      _assertLiteral(false);
    });
    test('parses a double', () {
      _assertLiteral(0.2);
      _assertLiteral(0.35);
    });
    test('parses an integer', () {
      _assertLiteral(2);
      _assertLiteral(35);
    });
  });

  group('property expressions:', () {
    void _assertGetProperty(String property, dynamic value) {
      final expression = _parser.parse(['get', property]);
      expect(expression.evaluate(_context), equals(value));
    }

    void _assertHasProperty(String property, bool isPresent) {
      final expression = _parser.parse(['has', property]);
      expect(expression.evaluate(_context), equals(isPresent));
    }

    void _assertNotHasProperty(String property, bool expected) {
      final expression = _parser.parse(['!has', property]);
      expect(expression.evaluate(_context), equals(expected));
    }

    void _assertInProperty(String property, List values, bool expected) {
      final expression = _parser.parse(['in', property, ...values]);
      expect(expression.evaluate(_context), equals(expected));
    }

    void _assertNotInProperty(String property, List values, bool expected) {
      final expression = _parser.parse(['!in', property, ...values]);
      expect(expression.evaluate(_context), equals(expected));
    }

    test('parses a get property', () {
      _assertGetProperty('a-string', 'a-string-value');
      _assertGetProperty('another-string', 'another-string-value');
      _assertGetProperty('a-bool', true);
      _assertGetProperty('a-false-bool', false);
      _assertGetProperty('an-int', 33);
      _assertGetProperty('a-double', 13.2);
      _assertGetProperty('no-such-value', null);
    });

    test('parses a has property', () {
      _assertHasProperty('a-string', true);
      _assertHasProperty('a-bool', true);
      _assertHasProperty('a-false-bool', true);
      _assertHasProperty('a-double', true);
      _assertHasProperty('no-such-value', false);
    });

    test('parses a !has property', () {
      _assertNotHasProperty('a-string', false);
      _assertNotHasProperty('a-bool', false);
      _assertNotHasProperty('a-false-bool', false);
      _assertNotHasProperty('a-double', false);
      _assertNotHasProperty('no-such-value', true);
    });
    test('parses a in property', () {
      _assertInProperty('a-string', ['first-value', 'a-string-value'], true);
      _assertInProperty('a-string', ['first-value', 'second-value'], false);
    });
    test('parses a !in property', () {
      _assertNotInProperty(
          'a-string', ['first-value', 'a-string-value'], false);
      _assertNotInProperty('a-string', ['first-value', 'second-value'], true);
    });
  });

  group('boolean expressions:', () {
    void _assertNotExpression(dynamic delegateExpression, bool expected) {
      final expression = _parser.parse(['!', delegateExpression]);
      expect(expression.evaluate(_context), equals(expected));
    }

    void _assertEqualsExpression(dynamic first, dynamic second, bool expected) {
      final expression = _parser.parse(['==', first, second]);
      expect(expression.evaluate(_context), equals(expected));
    }

    void _assertNotEqualsExpression(
        dynamic first, dynamic second, bool expected) {
      final expression = _parser.parse(['!=', first, second]);
      expect(expression.evaluate(_context), equals(expected));
    }

    void _assertExpression(dynamic jsonExpression, bool expected) {
      final expression = _parser.parse(jsonExpression);
      expect(expression.evaluate(_context), equals(expected));
    }

    test('parses a ! expression', () {
      _assertNotExpression(['get', 'a-bool'], false);
      _assertNotExpression(['get', 'a-false-bool'], true);
      _assertNotExpression('a-bool', false);
      _assertNotExpression('a-false-bool', true);
    });

    test('parses a == expression', () {
      _assertEqualsExpression(['get', 'a-bool'], false, false);
      _assertEqualsExpression(['get', 'a-bool'], true, true);
      _assertEqualsExpression('a-bool', true, true);
      _assertEqualsExpression(33, ['get', 'an-int'], true);
      _assertEqualsExpression(1, 1, true);
      _assertEqualsExpression(1, 2, false);
    });

    test('parses a != expression', () {
      _assertNotEqualsExpression(['get', 'a-bool'], false, true);
      _assertNotEqualsExpression(['get', 'a-bool'], true, false);
      _assertNotEqualsExpression('a-bool', true, false);
      _assertNotEqualsExpression(33, ['get', 'an-int'], false);
      _assertNotEqualsExpression(1, 1, false);
      _assertNotEqualsExpression(1, 2, true);
    });

    test('parses a > expression', () {
      _assertExpression(['>', 1, 2], false);
      _assertExpression(['>', 1, 1], false);
      _assertExpression(['>', 2, 1], true);
      _assertExpression(['>', null, 1], false);
      _assertExpression(['>', 'an-int', 32], true);
      _assertExpression(['>', 'an-int', 33], false);
      _assertExpression(['>', 'an-int', 34], false);
    });

    test('parses a >= expression', () {
      _assertExpression(['>=', 1, 2], false);
      _assertExpression(['>=', 1, 1], true);
      _assertExpression(['>=', 2, 1], true);
      _assertExpression(['>=', null, 1], false);
      _assertExpression(['>=', 'an-int', 32], true);
      _assertExpression(['>=', 'an-int', 33], true);
      _assertExpression(['>=', 'an-int', 34], false);
    });

    test('parses a < expression', () {
      _assertExpression(['<', 1, 2], true);
      _assertExpression(['<', 1, 1], false);
      _assertExpression(['<', 2, 1], false);
      _assertExpression(['<', null, 1], false);
      _assertExpression(['<', 'an-int', 32], false);
      _assertExpression(['<', 'an-int', 33], false);
      _assertExpression(['<', 'an-int', 34], true);
    });

    test('parses a <= expression', () {
      _assertExpression(['<=', 1, 2], true);
      _assertExpression(['<=', 1, 1], true);
      _assertExpression(['<=', 2, 1], false);
      _assertExpression(['<=', null, 1], false);
      _assertExpression(['<=', 'an-int', 32], false);
      _assertExpression(['<=', 'an-int', 33], true);
      _assertExpression(['<=', 'an-int', 34], true);
    });
  });
}
