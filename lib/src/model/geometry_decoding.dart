import 'dart:ui';

enum _Command {
  moveTo,
  lineTo,
  closePath,
}

@pragma('vm:prefer-inline')
_Command _decodeCommand(int command) {
  switch (command & 0x7) {
    case 1:
      return _Command.moveTo;
    case 2:
      return _Command.lineTo;
    case 7:
      return _Command.closePath;
    default:
      throw ArgumentError('Unknown command: ${command & 0x7}');
  }
}

@pragma('vm:prefer-inline')
int _decodeCommandLength(int command) => command >> 3;

@pragma('vm:prefer-inline')
int _decodeZigZag(int value) => (value >> 1) ^ -(value & 1);

Iterable<Offset> decodePoints(List<int> geometry) sync* {
  final it = geometry.iterator;

  // Decode MoveTo command
  // ignore: cascade_invocations
  it.moveNext();
  final moveToCommand = it.current;
  assert(_decodeCommand(moveToCommand) == _Command.moveTo);
  final points = _decodeCommandLength(moveToCommand);
  assert(points >= 1);

  // Decode points.
  for (var i = 0; i < points; i++) {
    it.moveNext();
    final x = _decodeZigZag(it.current);
    it.moveNext();
    final y = _decodeZigZag(it.current);
    yield Offset(x.toDouble(), y.toDouble());
  }
}

Iterable<Path> decodeLineStrings(List<int> geometry) sync* {
  // Cursor point.
  // Note that it is never reset between line strings.
  var cx = 0;
  var cy = 0;

  final it = geometry.iterator;
  while (it.moveNext()) {
    // Start of a new line string.
    final points = <Offset>[];

    // Decode MoveTo command
    final moveToCommand = it.current;
    assert(_decodeCommand(moveToCommand) == _Command.moveTo);
    assert(_decodeCommandLength(moveToCommand) == 1);

    // Move to the first point.
    it.moveNext();
    cx += _decodeZigZag(it.current);
    it.moveNext();
    cy += _decodeZigZag(it.current);
    points.add(Offset(cx.toDouble(), cy.toDouble()));

    // Decode LineTo command.
    it.moveNext();
    final lineToCommand = it.current;
    assert(_decodeCommand(lineToCommand) == _Command.lineTo);
    final lineSegments = _decodeCommandLength(lineToCommand);
    assert(lineSegments >= 1);

    // Add the line segments.
    for (var i = 0; i < lineSegments; i++) {
      it.moveNext();
      cx += _decodeZigZag(it.current);
      it.moveNext();
      cy += _decodeZigZag(it.current);
      points.add(Offset(cx.toDouble(), cy.toDouble()));
    }

    yield Path()..addPolygon(points, false);
  }
}

Iterable<Path> decodePolygons(List<int> geometry) sync* {
  Path? polygon;

  // Cursor point.
  // Note that it is never reset between polygons or rings.
  var cx = 0;
  var cy = 0;

  final it = geometry.iterator;
  while (it.moveNext()) {
    // Start of a new ring.
    final points = <Offset>[];

    // The rings area. We need it to know if the ring is exterior or interior.
    var a = 0;

    // The first point of the ring. We need it to calculate its area.
    var x0 = 0;
    var y0 = 0;

    // Decode MoveTo command
    final moveToCommand = it.current;
    assert(_decodeCommand(moveToCommand) == _Command.moveTo);
    assert(_decodeCommandLength(moveToCommand) == 1);

    // Move to the first point.
    it.moveNext();
    cx += _decodeZigZag(it.current);
    it.moveNext();
    cy += _decodeZigZag(it.current);
    x0 = cx;
    y0 = cy;
    points.add(Offset(cx.toDouble(), cy.toDouble()));

    // Decode LineTo command.
    it.moveNext();
    final lineToCommand = it.current;
    assert(_decodeCommand(lineToCommand) == _Command.lineTo);
    final ringSegments = _decodeCommandLength(lineToCommand);
    assert(ringSegments >= 1);

    // Add the ring segments.
    for (var i = 0; i < ringSegments; i++) {
      it.moveNext();
      final x = cx + _decodeZigZag(it.current);
      it.moveNext();
      final y = cy + _decodeZigZag(it.current);
      a += (cx * y) - (x * cy);
      cx = x;
      cy = y;
      points.add(Offset(cx.toDouble(), cy.toDouble()));
    }
    a += (cx * y0) - (x0 * cy);

    // Decode ClosePath command.
    it.moveNext();
    final closePathCommand = it.current;
    assert(
      _decodeCommand(closePathCommand) == _Command.closePath,
    );
    assert(_decodeCommandLength(closePathCommand) == 1);

    assert(a != 0);
    if (a.isNegative) {
      // We just decoded an interior ring.

      // Add the ring to the current polygon.
      assert(polygon != null);
      polygon!.addPolygon(points, true);
    } else {
      // We just decoded an exterior ring.

      if (polygon != null) {
        // If we have a previous polygon, it is now complete, so yield it.
        yield polygon;
      }

      // Make the ring the current polygon.
      polygon = Path()
        ..fillType = PathFillType.evenOdd
        ..addPolygon(points, true);
    }
  }

  // The last polygon wont be completed in the decode loop, so yield it now.
  assert(polygon != null);
  yield polygon!;
}
