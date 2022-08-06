import 'package:flutter/rendering.dart';

import 'style.dart';

extension LineCapExtension on LineCap {
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

extension LineJoinExtension on LineJoin {
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
