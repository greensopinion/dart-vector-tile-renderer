import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/themes/expression/expression.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

void main() {
  final parser = ExpressionParser(const Logger.noop());

  final properties = {
    'a-string': 'a-string-value',
    'another-string': 'another-string-value',
    'a-latin-ligature': 'ﬁ',
    'a-bengali-string': 'বাংলা',
    'a-burmese-string': 'မြန်မာဘာသာ',
    'a-khmer-string': 'អក្សរខ្មែរ',
    'a-bool': true,
    'a-false-bool': false,
    'an-int': 33,
    'a-double': 13.2,
    'level': 127
  };
  var zoom = 1.0;
  context() => EvaluationContext(
      () => properties, TileFeatureType.linestring, const Logger.noop(),
      zoom: zoom, zoomScaleFactor: 1.0);

  void assertExpression(dynamic jsonExpression, String cacheKey, expected) {
    final expression = parser.parse(jsonExpression);
    final result = expression.evaluate(context());
    if (result is double && expected is double) {
      expect(result, closeTo(expected, 0.001));
    } else {
      expect(result, equals(expected));
    }
    expect(expression.cacheKey, cacheKey);
  }

  test('parses an unsupported expression', () {
    final json = {'not-supported': true};
    final expression = parser.parse(json);
    expect(expression, isA<UnsupportedExpression>());
    expect(expression.evaluate(context()), isNull);
    expect((expression as UnsupportedExpression).json, equals(json));
    expect(expression.cacheKey, 'unsupported');
  });

  test('supports operators', () {
    expect(
        parser.supportedOperators().toList()..sort(),
        equals([
          '!',
          '!=',
          '!has',
          '!in',
          '%',
          '*',
          '+',
          '-',
          '/',
          '<',
          '<=',
          '==',
          '>',
          '>=',
          '^',
          'all',
          'any',
          'case',
          'coalesce',
          'concat',
          'geometry-type',
          'get',
          'has',
          'in',
          'interpolate',
          'is-supported-script',
          'let',
          'match',
          'sqrt',
          'step',
          'string',
          'to-boolean',
          'to-number',
          'to-string',
          'var'
        ]));
  });

  group('literal expressions:', () {
    void assertLiteral(dynamic value) {
      final expression = parser.parse(value);
      expect(expression.evaluate(context()), equals(value));
      expect(expression.cacheKey, 'literal($value)');
    }

    test('parses a string', () {
      assertLiteral('a string');
      assertLiteral('another string');
    });
    test('parses a boolean', () {
      assertLiteral(true);
      assertLiteral(false);
    });
    test('parses a double', () {
      assertLiteral(0.2);
      assertLiteral(0.35);
    });
    test('parses an integer', () {
      assertLiteral(2);
      assertLiteral(35);
    });
  });
  group('type expressions:', () {
    test('parses to-string', () {
      assertExpression(['to-string', true], 'toString(literal(true))', 'true');
      assertExpression(
          ['to-string', false], 'toString(literal(false))', 'false');
      assertExpression(['to-string', 1234], 'toString(literal(1234))', '1234');
      assertExpression(['to-string', null], 'toString(literal(null))', '');
      assertExpression([
        'to-string',
        ['get', 'a-string']
      ], 'toString(get(a-string))', 'a-string-value');
    });

    test('parses to-boolean', () {
      assertExpression(['to-boolean', true], 'toBoolean(literal(true))', true);
      assertExpression(
          ['to-boolean', false], 'toBoolean(literal(false))', false);
      assertExpression([
        'to-boolean',
        ['get', 'an-int']
      ], 'toBoolean(get(an-int))', true);
      assertExpression([
        'to-boolean',
        ['get', 'a-double']
      ], 'toBoolean(get(a-double))', true);
      assertExpression([
        'to-boolean',
        ['get', 'no-such-property']
      ], 'toBoolean(get(no-such-property))', false);
    });

    test('parses to-number', () {
      assertExpression(['to-number', true], 'toNumber(literal(true))', 1);
      assertExpression(['to-number', false], 'toNumber(literal(false))', 0);
      assertExpression([
        'to-number',
        ['get', 'an-int']
      ], 'toNumber(get(an-int))', 33);
      assertExpression([
        'to-number',
        ['get', 'a-double']
      ], 'toNumber(get(a-double))', 13.2);
      assertExpression([
        'to-number',
        ['get', 'no-such-property'],
        15
      ], 'toNumber(get(no-such-property),literal(15))', 15);
      assertExpression([
        'to-number',
        ['get', 'no-such-property']
      ], 'toNumber(get(no-such-property))', 0);
    });
  });

  group('property expressions:', () {
    void assertGetProperty(String property, dynamic value) {
      final expression = parser.parse(['get', property]);
      expect(expression.evaluate(context()), equals(value));
    }

    void assertHasProperty(String property, bool isPresent) {
      final expression = parser.parse(['has', property]);
      expect(expression.evaluate(context()), equals(isPresent));
    }

    void assertNotHasProperty(String property, bool expected) {
      final expression = parser.parse(['!has', property]);
      expect(expression.evaluate(context()), equals(expected));
    }

    void assertInProperty(String property, List values, bool expected) {
      final expression = parser.parse(['in', property, ...values]);
      expect(expression.evaluate(context()), equals(expected));
    }

    void assertNotInProperty(String property, List values, bool expected) {
      final expression = parser.parse(['!in', property, ...values]);
      expect(expression.evaluate(context()), equals(expected));
    }

    test('parses a formatted string', () {
      assertExpression('{a-string}', 'get(a-string)', 'a-string-value');
      assertExpression('{no-match}', 'get(no-match)', null);
    });

    test('parses a get property', () {
      assertGetProperty('a-string', 'a-string-value');
      assertGetProperty('another-string', 'another-string-value');
      assertGetProperty('a-bool', true);
      assertGetProperty('a-false-bool', false);
      assertGetProperty('an-int', 33);
      assertGetProperty('a-double', 13.2);
      assertGetProperty('no-such-value', null);
    });

    test('parses a property expression', () {
      // I couldn't find the spec for this, but themes use it with
      // extrusion
      final expression =
          parser.parse({'property': 'a-string', 'type': 'identity'});
      expect(expression.evaluate(context()), equals('a-string-value'));
    });

    test('parses a has property', () {
      assertHasProperty('a-string', true);
      assertHasProperty('a-bool', true);
      assertHasProperty('a-false-bool', true);
      assertHasProperty('a-double', true);
      assertHasProperty('no-such-value', false);
    });

    test('parses a !has property', () {
      assertNotHasProperty('a-string', false);
      assertNotHasProperty('a-bool', false);
      assertNotHasProperty('a-false-bool', false);
      assertNotHasProperty('a-double', false);
      assertNotHasProperty('no-such-value', true);
    });
    test('parses a in property', () {
      assertInProperty('a-string', ['first-value', 'a-string-value'], true);
      assertInProperty('a-string', ['first-value', 'second-value'], false);
    });
    test('parses a !in property', () {
      assertNotInProperty('a-string', ['first-value', 'a-string-value'], false);
      assertNotInProperty('a-string', ['first-value', 'second-value'], true);
    });

    test('parses \$type', () {
      assertGetProperty('\$type', 'LineString');
    });
  });

  group('other expressions:', () {
    test('parses geometry-type', () {
      assertExpression(['geometry-type'], 'get(\$type)', 'LineString');
    });
  });

  group('boolean expressions:', () {
    void assertNotExpression(dynamic delegateExpression, bool expected) {
      final expression = parser.parse(['!', delegateExpression]);
      expect(expression.evaluate(context()), equals(expected));
    }

    void assertEqualsExpression(dynamic first, dynamic second, bool expected) {
      final expression = parser.parse(['==', first, second]);
      expect(expression.evaluate(context()), equals(expected));
    }

    void assertNotEqualsExpression(
        dynamic first, dynamic second, bool expected) {
      final expression = parser.parse(['!=', first, second]);
      expect(expression.evaluate(context()), equals(expected));
    }

    test('parses a ! expression', () {
      assertNotExpression(['get', 'a-bool'], false);
      assertNotExpression(['get', 'a-false-bool'], true);
      assertNotExpression('a-bool', false);
      assertNotExpression('a-false-bool', true);
    });

    test('parses a == expression', () {
      assertEqualsExpression(['get', 'a-bool'], false, false);
      assertEqualsExpression(['get', 'a-bool'], true, true);
      assertEqualsExpression('a-bool', true, true);
      assertEqualsExpression(33, ['get', 'an-int'], true);
      assertEqualsExpression(1, 1, true);
      assertEqualsExpression(1, 2, false);
    });

    test('parses a != expression', () {
      assertNotEqualsExpression(['get', 'a-bool'], false, true);
      assertNotEqualsExpression(['get', 'a-bool'], true, false);
      assertNotEqualsExpression('a-bool', true, false);
      assertNotEqualsExpression(33, ['get', 'an-int'], false);
      assertNotEqualsExpression(1, 1, false);
      assertNotEqualsExpression(1, 2, true);
    });

    test('parses a > expression', () {
      assertExpression(['>', 1, 2], '(literal(1) > literal(2))', false);
      assertExpression(['>', 1, 1], '(literal(1) > literal(1))', false);
      assertExpression(['>', 2, 1], '(literal(2) > literal(1))', true);
      assertExpression(['>', null, 1], '(literal(null) > literal(1))', false);
      assertExpression(
          ['>', 'an-int', 32], '(get(an-int) > literal(32))', true);
      assertExpression(
          ['>', 'an-int', 33], '(get(an-int) > literal(33))', false);
      assertExpression(
          ['>', 'an-int', 34], '(get(an-int) > literal(34))', false);
    });

    test('parses a >= expression', () {
      assertExpression(['>=', 1, 2], '(literal(1) >= literal(2))', false);
      assertExpression(['>=', 1, 1], '(literal(1) >= literal(1))', true);
      assertExpression(['>=', 2, 1], '(literal(2) >= literal(1))', true);
      assertExpression(['>=', null, 1], '(literal(null) >= literal(1))', false);
      assertExpression(
          ['>=', 'an-int', 32], '(get(an-int) >= literal(32))', true);
      assertExpression(
          ['>=', 'an-int', 33], '(get(an-int) >= literal(33))', true);
      assertExpression(
          ['>=', 'an-int', 34], '(get(an-int) >= literal(34))', false);
    });

    test('parses a < expression', () {
      assertExpression(['<', 1, 2], '(literal(1) < literal(2))', true);
      assertExpression(['<', 1, 1], '(literal(1) < literal(1))', false);
      assertExpression(['<', 2, 1], '(literal(2) < literal(1))', false);
      assertExpression(['<', null, 1], '(literal(null) < literal(1))', false);
      assertExpression(
          ['<', 'an-int', 32], '(get(an-int) < literal(32))', false);
      assertExpression(
          ['<', 'an-int', 33], '(get(an-int) < literal(33))', false);
      assertExpression(
          ['<', 'an-int', 34], '(get(an-int) < literal(34))', true);
    });

    test('parses a <= expression', () {
      assertExpression(['<=', 1, 2], '(literal(1) <= literal(2))', true);
      assertExpression(['<=', 1, 1], '(literal(1) <= literal(1))', true);
      assertExpression(['<=', 2, 1], '(literal(2) <= literal(1))', false);
      assertExpression(['<=', null, 1], '(literal(null) <= literal(1))', false);
      assertExpression(
          ['<=', 'an-int', 32], '(get(an-int) <= literal(32))', false);
      assertExpression(
          ['<=', 'an-int', 33], '(get(an-int) <= literal(33))', true);
      assertExpression(
          ['<=', 'an-int', 34], '(get(an-int) <= literal(34))', true);
    });

    test('parses an all expression', () {
      assertExpression(
          ['all', true, false], '(all [literal(true),literal(false)])', false);
      assertExpression(
          ['all', false, true], '(all [literal(false),literal(true)])', false);
      assertExpression(
          ['all', true, true], '(all [literal(true),literal(true)])', true);
    });

    test('parses an all expression with no arguments', () {
      assertExpression(['all'], '(all [])', true);
    });

    test('parses an any expression', () {
      assertExpression(
          ['any', true, false], '(any [literal(true),literal(false)])', true);
      assertExpression(
          ['any', false, true], '(any [literal(false),literal(true)])', true);
      assertExpression(
          ['any', true, true], '(any [literal(true),literal(true)])', true);
      assertExpression(['any', false, false],
          '(any [literal(false),literal(false)])', false);
    });

    test('parses an any expression with no arguments', () {
      assertExpression(['any'], '(any [])', false);
    });

    test('parses a match expression', () {
      assertExpression([
        'match',
        ['get', 'a-string'],
        ['no-match-value', 'a-string-value'],
        true
      ], 'match(get(a-string),[literal(no-match-value),literal(a-string-value)],literal(true))',
          true);
      assertExpression([
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
      assertExpression([
        'match',
        ['get', 'another-string'],
        ['no-match-value', 'a-string-value'],
        false
      ], 'match(get(another-string),[literal(no-match-value),literal(a-string-value)],literal(false))',
          null);
    });
    test('parses a match with a fallback', () {
      assertExpression([
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

    test('parses an is-supported-script expression for latin script strings',
        () {
      assertExpression([
        'is-supported-script',
        ['get', 'a-string']
      ], 'isSupportedScript(get(a-string))', true);
      assertExpression([
        'is-supported-script',
        ['get', 'a-latin-ligature']
      ], 'isSupportedScript(get(a-latin-ligature))', true);
    });

    test('parses an is-supported-script expression for complex script strings',
        () {
      assertExpression([
        'is-supported-script',
        ['get', 'a-bengali-string']
      ], 'isSupportedScript(get(a-bengali-string))', true);
      assertExpression([
        'is-supported-script',
        ['get', 'a-burmese-string']
      ], 'isSupportedScript(get(a-burmese-string))', true);
      assertExpression([
        'is-supported-script',
        ['get', 'a-khmer-string']
      ], 'isSupportedScript(get(a-khmer-string))', true);
    });
  });
  group('math expressions:', () {
    test('provides % expression', () {
      assertExpression(['%', 3, 2], '(literal(3)%literal(2))', 1);
    });
    test('provides * expression', () {
      assertExpression(['*', 3, 2], '(literal(3)*literal(2))', 6);
    });
    test('provides + expression', () {
      assertExpression(['+', 3, 2], '(literal(3)+literal(2))', 5);
    });
    test('provides - expression', () {
      assertExpression(['-', 3, 2], '(literal(3)-literal(2))', 1);
    });
    test('provides / expression', () {
      assertExpression(['/', 3, 2], '(literal(3)/literal(2))', 1.5);
    });
    test('provides ^ expression', () {
      assertExpression(['^', 3, 2], '(literal(3)^literal(2))', 9);
    });
    test('provides sqrt expression', () {
      assertExpression(['sqrt', 4], 'sqrt(literal(4))', 2);
    });
  });

  group('coalesce expressions:', () {
    final expression = [
      'coalesce',
      ['get', 'an-unexpected-string'],
      ['get', 'another-string']
    ];
    const expectedCacheKey =
        'coalesce(get(an-unexpected-string),get(another-string))';
    test('provides a cache key and value', () {
      assertExpression(expression, expectedCacheKey, "another-string-value");
    });
  });

  group('concat expressions:', () {
    final expression = [
      'concat',
      ['get', 'an-unexpected-string'],
      ['get', 'another-string'],
      'a-value'
    ];
    const expectedCacheKey =
        'concat(get(an-unexpected-string),get(another-string),literal(a-value))';
    test('provides a cache key and value', () {
      assertExpression(
          expression, expectedCacheKey, 'another-string-valuea-value');
    });
  });

  group('string expressions:', () {
    final expression = [
      'string',
      ['get', 'an-unexpected-string'],
      ['get', 'another-string']
    ];
    const expectedCacheKey =
        'string(get(an-unexpected-string),get(another-string))';
    test('provides a cache key and value', () {
      assertExpression(expression, expectedCacheKey, "another-string-value");
    });
  });

  group('step expressions:', () {
    final expression = [
      'step',
      ['zoom'],
      0,
      10,
      1,
      11,
      1.5
    ];
    const expectedCacheKey =
        'step(get(zoom),literal(0),[stop(literal(10),literal(1)),stop(literal(11),literal(1.5))])';
    test('provides a cache key', () {
      assertExpression(expression, expectedCacheKey, 0);
    });

    test('provides a stepped value', () {
      zoom = 10.0;
      assertExpression(expression, expectedCacheKey, 0);
      zoom = 10.1;
      assertExpression(expression, expectedCacheKey, 1);
      zoom = 11;
      assertExpression(expression, expectedCacheKey, 1);
      zoom = 11.1;
      assertExpression(expression, expectedCacheKey, 1.5);
    });

    test('provides another stepped value', () {
      final expression = [
        "step",
        ["zoom"],
        0,
        14,
        1
      ];
      const expectedCacheKey =
          'step(get(zoom),literal(0),[stop(literal(14),literal(1))])';
      zoom = 13;
      assertExpression(expression, expectedCacheKey, 0);
      zoom = 14.1;
      assertExpression(expression, expectedCacheKey, 1);
      zoom = 15;
      assertExpression(expression, expectedCacheKey, 1);
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
      const expectedCacheKey =
          'interpolate(get(zoom),linear,[stop(literal(9),literal(8.5)),stop(literal(15),literal(12)),stop(literal(22),literal(28))])';

      test('provides a value below the upper bound', () {
        zoom = 1;
        assertExpression(expression, expectedCacheKey, 8.5);
      });
      test('provides a linear progression', () {
        zoom = 9;
        assertExpression(expression, expectedCacheKey, 8.5);
        zoom = 10;
        assertExpression(expression, expectedCacheKey, 9.083);
        zoom = 11;
        assertExpression(expression, expectedCacheKey, 9.667);
        zoom = 12;
        assertExpression(expression, expectedCacheKey, 10.25);
        zoom = 13;
        assertExpression(expression, expectedCacheKey, 10.833);
        zoom = 14;
        assertExpression(expression, expectedCacheKey, 11.417);
        zoom = 15;
        assertExpression(expression, expectedCacheKey, 12);
      });

      test('provides a value above the upper bound', () {
        zoom = 25;
        assertExpression(expression, expectedCacheKey, 28);
      });

      test('provides a linear interpolation from map syntax', () {
        final expression = {
          'base': 1,
          'stops': [
            [13, 12],
            [14, 13]
          ]
        };
        const expectedCacheKey =
            'interpolate(get(zoom),linear,[stop(literal(13),literal(12)),stop(literal(14),literal(13))])';

        zoom = 1;
        assertExpression(expression, expectedCacheKey, 12);
        zoom = 13;
        assertExpression(expression, expectedCacheKey, 12);
        zoom = 14;
        assertExpression(expression, expectedCacheKey, 13);
      });

      test('provides color interpolation', () {
        final expression = [
          "interpolate",
          ["linear"],
          ["get", "level"],
          110,
          "rgba(0,0,0,0.08)",
          127,
          "rgba(0,0,0,0.06)",
          143,
          "rgba(0,0,0,0.04)",
          160,
          "rgba(0,0,0,0.02)"
        ];
        assertExpression(
            expression,
            'interpolate(get(level),linear,[stop(literal(110),literal(rgba(0,0,0,0.08))),stop(literal(127),literal(rgba(0,0,0,0.06))),stop(literal(143),literal(rgba(0,0,0,0.04))),stop(literal(160),literal(rgba(0,0,0,0.02)))])',
            'rgba(0,0,0,0.06)');
      });

      test('supports linear with base', () {
        const base = 1;
        final expression = [
          "interpolate",
          ["linear", base],
          ["zoom"],
          9,
          8.5
        ];
        zoom = 1;
        assertExpression(
            expression,
            'interpolate(get(zoom),linear,[stop(literal(9),literal(8.5))])',
            8.5);
      });
    });

    group('cubic-bezier interpolation:', () {
      final expression = [
        "interpolate",
        ["cubic-bezier", 0.5, 0, 1, 1],
        ["zoom"],
        11,
        10.5,
        15,
        16
      ];
      const expectedCacheKey =
          'interpolate(get(zoom),cubicBezier(0.5,0.0,1.0,1.0),[stop(literal(11),literal(10.5)),stop(literal(15),literal(16))])';

      test('provides a value below the upper bound', () {
        zoom = 1;
        assertExpression(expression, expectedCacheKey, 10.5);
      });

      test('provides a value above the upper bound', () {
        zoom = 18;
        assertExpression(expression, expectedCacheKey, 16);
      });

      test('provides an cubic-bezier progression', () {
        zoom = 10;
        assertExpression(expression, expectedCacheKey, 10.5);
        zoom = 11;
        assertExpression(expression, expectedCacheKey, 10.5);
        zoom = 12;
        assertExpression(expression, expectedCacheKey, 10.914);
        zoom = 13;
        assertExpression(expression, expectedCacheKey, 12.029);
        zoom = 14;
        assertExpression(expression, expectedCacheKey, 13.725);
        zoom = 15;
        assertExpression(expression, expectedCacheKey, 16.0);
        zoom = 20;
        assertExpression(expression, expectedCacheKey, 16.0);
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
      const expectedCacheKey =
          'interpolate(get(zoom),exponential(literal(1.2)),[stop(literal(9),literal(8.5)),stop(literal(15),literal(12))])';

      test('provides a value below the upper bound', () {
        zoom = 1;
        assertExpression(expression, expectedCacheKey, 8.5);
      });
      test('provides an exponential progression', () {
        zoom = 9;
        assertExpression(expression, expectedCacheKey, 8.5);
        zoom = 10;
        assertExpression(expression, expectedCacheKey, 8.852);
        zoom = 11;
        assertExpression(expression, expectedCacheKey, 9.275);
        zoom = 12;
        assertExpression(expression, expectedCacheKey, 9.783);
        zoom = 13;
        assertExpression(expression, expectedCacheKey, 10.392);
        zoom = 14;
        assertExpression(expression, expectedCacheKey, 11.123);
        zoom = 15;
        assertExpression(expression, expectedCacheKey, 12);
      });

      test('provides exponential interpolation from map syntax', () {
        final expression = {
          'base': 2,
          'stops': [
            [13, 12],
            [14, 13]
          ]
        };
        const cacheKey =
            'interpolate(get(zoom),exponential(literal(2)),[stop(literal(13),literal(12)),stop(literal(14),literal(13))])';
        zoom = 1;
        assertExpression(expression, cacheKey, 12);
        zoom = 13;
        assertExpression(expression, cacheKey, 12);
        zoom = 13.5;
        assertExpression(expression, cacheKey, 12.414);
        zoom = 14;
        assertExpression(expression, cacheKey, 13);
      });
    });
  });
  group('variables:', () {
    final expression = [
      "let",
      "aVariable",
      ["get", 'zoom'],
      [
        "*",
        ['var', 'aVariable'],
        2
      ]
    ];
    const expectedCacheKey = '(get(zoom)*literal(2))';
    test('provides variable expressions', () {
      zoom = 3;
      assertExpression(expression, expectedCacheKey, zoom * 2);
    });
  });
  group('case expression:', () {
    final expression = [
      "case",
      [
        '==',
        3,
        ["get", 'zoom']
      ],
      1,
      [
        '==',
        4,
        ["get", 'zoom']
      ],
      2,
      3
    ];
    const expectedCacheKey =
        'case(equals(literal(3),get(zoom)):literal(1);equals(literal(4),get(zoom)):literal(2);literal(true):literal(3))';
    test('provides case expression that evaluates to a fallback', () {
      zoom = 1;
      assertExpression(expression, expectedCacheKey, 3);
    });
    test('provides case expression that evaluates to a first case', () {
      zoom = 3;
      assertExpression(expression, expectedCacheKey, 1);
    });
    test('provides case expression that evaluates to another case', () {
      zoom = 4;
      assertExpression(expression, expectedCacheKey, 2);
    });
  });
}
