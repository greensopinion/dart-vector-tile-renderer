import 'package:flutter/rendering.dart';
import '../themes/expression/expression.dart';
import '../themes/style.dart';

class LineStyler {
  final Style _style;
  final EvaluationContext _context;

  LineStyler(this._style, this._context);
  void apply(Paint paint) {
    final lineCap =
        _style.lineLayout?.lineCap.evaluate(_context) ?? LineCap.DEFAULT;
    final lineJoin =
        _style.lineLayout?.lineJoin.evaluate(_context) ?? LineJoin.DEFAULT;
    lineCap.apply(paint);
    lineJoin.apply(paint);
  }
}

extension _LineCapExtension on LineCap {
  void apply(Paint paint) {
    paint.strokeCap = _toStrokeCap();
  }

  StrokeCap _toStrokeCap() {
    if (this == LineCap.butt) {
      return StrokeCap.butt;
    }
    if (this == LineCap.round) {
      return StrokeCap.round;
    }
    if (this == LineCap.square) {
      return StrokeCap.square;
    }
    throw 'not implemented: $name';
  }
}

extension _LineJoinExtension on LineJoin {
  void apply(Paint paint) {
    paint.strokeJoin = _toStrokeJoin();
  }

  StrokeJoin _toStrokeJoin() {
    if (this == LineJoin.miter) {
      return StrokeJoin.miter;
    }
    if (this == LineJoin.bevel) {
      return StrokeJoin.bevel;
    }
    if (this == LineJoin.round) {
      return StrokeJoin.round;
    }
    throw 'not implemented: $name';
  }
}
