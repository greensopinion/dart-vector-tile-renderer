import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/themes/expression/expression.dart';
import 'package:fixnum/fixnum.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

void main() {
  final _parser = ExpressionParser(Logger.noop());

  final _properties = {
    'a-string': VectorTileValue(stringValue: 'a-string-value'),
    'another-string': VectorTileValue(stringValue: 'another-string-value'),
    'a-bool': VectorTileValue(boolValue: true),
    'a-false-bool': VectorTileValue(boolValue: false),
    'an-int': VectorTileValue(intValue: Int64(33)),
    'a-double': VectorTileValue(doubleValue: 13.2)
  };
  var zoom = 1.0;
  _context() => EvaluationContext(
      () => _properties, VectorTileGeomType.LINESTRING, zoom, Logger.noop());

  void _assertExpression(dynamic jsonExpression, String cacheKey, expected) {
    final expression = _parser.parse(jsonExpression);
    final result = expression.evaluate(_context());
    if (result is double && expected is double) {
      expect(result, closeTo(expected, 0.001));
    } else {
      expect(result, equals(expected));
    }
    expect(expression.cacheKey, cacheKey);
  }

  test('parses an unsupported expression', () {
    final json = {'not-supported': true};
    final expression = _parser.parse(json);
    expect(expression, isA<UnsupportedExpression>());
    expect(expression.evaluate(_context()), isNull);
    expect((expression as UnsupportedExpression).json, equals(json));
    expect(expression.cacheKey, 'unsupported');
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
          'all',
          'any',
          'get',
          'has',
          'in',
          'interpolate',
          'match',
          'to-string'
        ]));
  });

  group('literal expressions:', () {
    void _assertLiteral(dynamic value) {
      final expression = _parser.parse(value);
      expect(expression.evaluate(_context()), equals(value));
      expect(expression.cacheKey, 'literal($value)');
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
  group('type expressions:', () {
    test('parses to-string', () {
      _assertExpression(['to-string', true], 'toString(literal(true))', 'true');
      _assertExpression(
          ['to-string', false], 'toString(literal(false))', 'false');
      _assertExpression(['to-string', 1234], 'toString(literal(1234))', '1234');
      _assertExpression(['to-string', null], 'toString(literal(null))', '');
      _assertExpression([
        'to-string',
        ['get', 'a-string']
      ], 'toString(get(a-string))', 'a-string-value');
    });
  });

  group('property expressions:', () {
    void _assertGetProperty(String property, dynamic value) {
      final expression = _parser.parse(['get', property]);
      expect(expression.evaluate(_context()), equals(value));
    }

    void _assertHasProperty(String property, bool isPresent) {
      final expression = _parser.parse(['has', property]);
      expect(expression.evaluate(_context()), equals(isPresent));
    }

    void _assertNotHasProperty(String property, bool expected) {
      final expression = _parser.parse(['!has', property]);
      expect(expression.evaluate(_context()), equals(expected));
    }

    void _assertInProperty(String property, List values, bool expected) {
      final expression = _parser.parse(['in', property, ...values]);
      expect(expression.evaluate(_context()), equals(expected));
    }

    void _assertNotInProperty(String property, List values, bool expected) {
      final expression = _parser.parse(['!in', property, ...values]);
      expect(expression.evaluate(_context()), equals(expected));
    }

    test('parses a formatted string', () {
      _assertExpression('{a-string}', 'get(a-string)', 'a-string-value');
      _assertExpression('{no-match}', 'get(no-match)', null);
    });

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

    test('parses \$type', () {
      _assertGetProperty('\$type', 'LineString');
    });
  });

  group('boolean expressions:', () {
    void _assertNotExpression(dynamic delegateExpression, bool expected) {
      final expression = _parser.parse(['!', delegateExpression]);
      expect(expression.evaluate(_context()), equals(expected));
    }

    void _assertEqualsExpression(dynamic first, dynamic second, bool expected) {
      final expression = _parser.parse(['==', first, second]);
      expect(expression.evaluate(_context()), equals(expected));
    }

    void _assertNotEqualsExpression(
        dynamic first, dynamic second, bool expected) {
      final expression = _parser.parse(['!=', first, second]);
      expect(expression.evaluate(_context()), equals(expected));
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
      _assertExpression(['>', 1, 2], '(literal(1) > literal(2))', false);
      _assertExpression(['>', 1, 1], '(literal(1) > literal(1))', false);
      _assertExpression(['>', 2, 1], '(literal(2) > literal(1))', true);
      _assertExpression(['>', null, 1], '(literal(null) > literal(1))', false);
      _assertExpression(
          ['>', 'an-int', 32], '(get(an-int) > literal(32))', true);
      _assertExpression(
          ['>', 'an-int', 33], '(get(an-int) > literal(33))', false);
      _assertExpression(
          ['>', 'an-int', 34], '(get(an-int) > literal(34))', false);
    });

    test('parses a >= expression', () {
      _assertExpression(['>=', 1, 2], '(literal(1) >= literal(2))', false);
      _assertExpression(['>=', 1, 1], '(literal(1) >= literal(1))', true);
      _assertExpression(['>=', 2, 1], '(literal(2) >= literal(1))', true);
      _assertExpression(
          ['>=', null, 1], '(literal(null) >= literal(1))', false);
      _assertExpression(
          ['>=', 'an-int', 32], '(get(an-int) >= literal(32))', true);
      _assertExpression(
          ['>=', 'an-int', 33], '(get(an-int) >= literal(33))', true);
      _assertExpression(
          ['>=', 'an-int', 34], '(get(an-int) >= literal(34))', false);
    });

    test('parses a < expression', () {
      _assertExpression(['<', 1, 2], '(literal(1) < literal(2))', true);
      _assertExpression(['<', 1, 1], '(literal(1) < literal(1))', false);
      _assertExpression(['<', 2, 1], '(literal(2) < literal(1))', false);
      _assertExpression(['<', null, 1], '(literal(null) < literal(1))', false);
      _assertExpression(
          ['<', 'an-int', 32], '(get(an-int) < literal(32))', false);
      _assertExpression(
          ['<', 'an-int', 33], '(get(an-int) < literal(33))', false);
      _assertExpression(
          ['<', 'an-int', 34], '(get(an-int) < literal(34))', true);
    });

    test('parses a <= expression', () {
      _assertExpression(['<=', 1, 2], '(literal(1) <= literal(2))', true);
      _assertExpression(['<=', 1, 1], '(literal(1) <= literal(1))', true);
      _assertExpression(['<=', 2, 1], '(literal(2) <= literal(1))', false);
      _assertExpression(
          ['<=', null, 1], '(literal(null) <= literal(1))', false);
      _assertExpression(
          ['<=', 'an-int', 32], '(get(an-int) <= literal(32))', false);
      _assertExpression(
          ['<=', 'an-int', 33], '(get(an-int) <= literal(33))', true);
      _assertExpression(
          ['<=', 'an-int', 34], '(get(an-int) <= literal(34))', true);
    });

    test('parses an all expression', () {
      _assertExpression(
          ['all', true, false], '(all [literal(true),literal(false)])', false);
      _assertExpression(
          ['all', false, true], '(all [literal(false),literal(true)])', false);
      _assertExpression(
          ['all', true, true], '(all [literal(true),literal(true)])', true);
    });

    test('parses an all expression with no arguments', () {
      _assertExpression(['all'], '(all [])', true);
    });

    test('parses an any expression', () {
      _assertExpression(
          ['any', true, false], '(any [literal(true),literal(false)])', true);
      _assertExpression(
          ['any', false, true], '(any [literal(false),literal(true)])', true);
      _assertExpression(
          ['any', true, true], '(any [literal(true),literal(true)])', true);
      _assertExpression(['any', false, false],
          '(any [literal(false),literal(false)])', false);
    });

    test('parses an any expression with no arguments', () {
      _assertExpression(['any'], '(any [])', false);
    });

    test('parses a match expression', () {
      _assertExpression([
        'match',
        ['get', 'a-string'],
        ['no-match-value', 'a-string-value'],
        true
      ], 'match(get(a-string),[literal(no-match-value),literal(a-string-value)],literal(true))',
          true);
      _assertExpression([
        'match',
        ['get', 'a-string'],
        'no-match-value',
        false,
        'a-string-value',
        true
      ], 'match(get(a-string),[literal(no-match-value)],[literal(a-string-value)],literal(false),literal(true))',
          true);
    });
    test('parses a match without a fallback', () {
      _assertExpression([
        'match',
        ['get', 'another-string'],
        ['no-match-value', 'a-string-value'],
        false
      ], 'match(get(another-string),[literal(no-match-value),literal(a-string-value)],literal(false))',
          null);
    });
    test('parses a match with a fallback', () {
      _assertExpression([
        'match',
        ['get', 'another-string'],
        ['no-match-value', 'a-string-value'],
        false,
        ['another-no-match-value'],
        false,
        true
      ], 'match(get(another-string),[literal(no-match-value),literal(a-string-value)],[literal(another-no-match-value)],literal(false),literal(false),literal(true))',
          true);
    });
  });

  group('interpolate expressions:', () {
    group('linear interpolation:', () {
      final expression = [
        "interpolate",
        ["linear"],
        ["zoom"],
        9,
        8.5,
        15,
        12,
        22,
        28
      ];
      final expectedCacheKey =
          'interpolate(get(zoom),linear,[stop(literal(9),literal(8.5)),stop(literal(15),literal(12)),stop(literal(22),literal(28))])';

      test('provides a value below the upper bound', () {
        zoom = 1;
        _assertExpression(expression, expectedCacheKey, null);
      });
      test('provides a linear progression', () {
        zoom = 9;
        _assertExpression(expression, expectedCacheKey, 8.5);
        zoom = 10;
        _assertExpression(expression, expectedCacheKey, 9.083);
        zoom = 11;
        _assertExpression(expression, expectedCacheKey, 9.667);
        zoom = 12;
        _assertExpression(expression, expectedCacheKey, 10.25);
        zoom = 13;
        _assertExpression(expression, expectedCacheKey, 10.833);
        zoom = 14;
        _assertExpression(expression, expectedCacheKey, 11.417);
        zoom = 15;
        _assertExpression(expression, expectedCacheKey, 12);
      });

      test('provides a value above the upper bound', () {
        zoom = 25;
        _assertExpression(expression, expectedCacheKey, 28);
      });

      test('provides a linear interpolation from map syntax', () {
        final expression = {
          'base': 1,
          'stops': [
            [13, 12],
            [14, 13]
          ]
        };
        final expectedCacheKey =
            'interpolate(get(zoom),linear,[stop(literal(13),literal(12)),stop(literal(14),literal(13))])';

        zoom = 1;
        _assertExpression(expression, expectedCacheKey, null);
        zoom = 13;
        _assertExpression(expression, expectedCacheKey, 12);
        zoom = 14;
        _assertExpression(expression, expectedCacheKey, 13);
      });
    });

    group('exponential interpolation:', () {
      final expression = [
        "interpolate",
        ["exponential", 1.2],
        ["zoom"],
        9,
        8.5,
        15,
        12
      ];
      final expectedCacheKey =
          'interpolate(get(zoom),exponential(literal(1.2)),[stop(literal(9),literal(8.5)),stop(literal(15),literal(12))])';

      test('provides a value below the upper bound', () {
        zoom = 1;
        _assertExpression(expression, expectedCacheKey, null);
      });
      test('provides an exponential progression', () {
        zoom = 9;
        _assertExpression(expression, expectedCacheKey, 8.5);
        zoom = 10;
        _assertExpression(expression, expectedCacheKey, 8.852);
        zoom = 11;
        _assertExpression(expression, expectedCacheKey, 9.275);
        zoom = 12;
        _assertExpression(expression, expectedCacheKey, 9.783);
        zoom = 13;
        _assertExpression(expression, expectedCacheKey, 10.392);
        zoom = 14;
        _assertExpression(expression, expectedCacheKey, 11.123);
        zoom = 15;
        _assertExpression(expression, expectedCacheKey, 12);
      });

      test('provides exponential interpolation from map syntax', () {
        final expression = {
          'base': 2,
          'stops': [
            [13, 12],
            [14, 13]
          ]
        };
        final cacheKey =
            'interpolate(get(zoom),exponential(literal(2)),[stop(literal(13),literal(12)),stop(literal(14),literal(13))])';
        zoom = 1;
        _assertExpression(expression, cacheKey, null);
        zoom = 13;
        _assertExpression(expression, cacheKey, 12);
        zoom = 13.5;
        _assertExpression(expression, cacheKey, 12.414);
        zoom = 14;
        _assertExpression(expression, cacheKey, 13);
      });
    });
  });
}
