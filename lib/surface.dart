import 'dart:ui';

import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:tavolara/bindings.dart';

abstract interface class Surface {
  void push();
  void pop();

  void beginClip({bool invert = false});
  void endClip();

  void translate(num x, num y);
  void scale(num x, [num? y]);
  void rotate(num a);

  void strokeWeight(num weight);
  void strokeJoin(StrokeJoin join);

  void stroke(Color color);
  void fill(Color color);

  void noStroke();
  void noFill();

  void circle(num x, num y, num v);
  void line(num x1, num y1, num x2, num y2);
  void point(num x, num y);
  void arc(num x, num y, num w, num h, num start, num stop);

  void vertex(num x, num y);
  void bezierVertex(num cx1, num cy1, num cx2, num cy2, num x, num y);

  void beginShape([PointMode mode = PointMode.polygon]);
  void endShape({bool close = false});
}

class P5Surface implements Surface {
  final P5 p5;

  P5Surface(this.p5);

  @override
  void arc(num x, num y, num w, num h, num start, num stop) => p5.arc(x, y, w, h, start, stop);

  @override
  void beginClip({bool invert = false}) => p5.beginClip(invert: invert);

  @override
  void beginShape([PointMode mode = PointMode.polygon]) => switch (mode) {
    .polygon => p5.beginShape(),
    .lines => p5.beginShape(p5.LINES),
    .points => p5.beginShape(p5.POINTS),
  };

  @override
  void bezierVertex(num cx1, num cy1, num cx2, num cy2, num x, num y) =>
      p5.bezierVertex(cx1, cy1, cx2, cy2, x, y);

  @override
  void circle(num x, num y, num v) => p5.circle(x, y, v);

  @override
  void endClip() => p5.endClip();

  @override
  void endShape({bool close = false}) => close ? p5.endShape(p5.CLOSE) : p5.endShape();

  @override
  void fill(Color color) =>
      p5.fill(p5.colorRGB(color.red8bit, color.green8bit, color.blue8bit, color.alpha8bit));

  @override
  void line(num x1, num y1, num x2, num y2) => p5.line(x1, y1, x2, y2);

  @override
  void noFill() => p5.noFill();

  @override
  void noStroke() => p5.noStroke();

  @override
  void point(num x, num y) => p5.point(x, y);

  @override
  void pop() => p5.pop();

  @override
  void push() => p5.push();

  @override
  void rotate(num a) => p5.rotate(a);

  @override
  void scale(num x, [num? y]) => y != null ? p5.scale(x, y) : p5.scale(x);

  @override
  void stroke(Color color) =>
      p5.stroke(p5.colorRGB(color.red8bit, color.green8bit, color.blue8bit, color.alpha8bit));

  @override
  void strokeJoin(StrokeJoin join) => p5.strokeJoin(switch (join) {
    .miter => p5.MITER,
    .bevel => p5.BEVEL,
    .round => p5.ROUND,
  });

  @override
  void strokeWeight(num weight) => p5.strokeWeight(weight);

  @override
  void translate(num x, num y) => p5.translate(x, y);

  @override
  void vertex(num x, num y) => p5.vertex(x, y);
}

sealed class _PathCommand {
  final Offset point;

  const _PathCommand(this.point);
}

class _VertexCommand extends _PathCommand {
  const _VertexCommand(super.point);
}

class _BezierCommand extends _PathCommand {
  final Offset c1;
  final Offset c2;

  const _BezierCommand(this.c1, this.c2, super.point);
}

class _PaintStyle {
  bool applyFill;
  Color fill;
  bool applyStroke;
  Color stroke;
  StrokeJoin strokeJoin;
  double strokeWeight;

  _PaintStyle({
    this.applyFill = false,
    this.fill = const Color(0xFF000000),
    this.applyStroke = false,
    this.stroke = const Color(0xFF000000),
    this.strokeJoin = .miter,
    this.strokeWeight = 0,
  });

  _PaintStyle clone() {
    return _PaintStyle(
      applyFill: applyFill,
      fill: fill,
      applyStroke: applyStroke,
      stroke: stroke,
      strokeJoin: strokeJoin,
      strokeWeight: strokeWeight,
    );
  }
}

class CanvasSurface implements Surface {
  final Canvas canvas;

  PointMode _pointMode = .polygon;
  final List<_PathCommand> _shapePoints = [];
  bool _recordingPoints = false;

  Path _clipPath = Path();
  bool _buildClip = false;
  bool _invertClip = false;

  final List<_PaintStyle> _styleStack = [_PaintStyle()];

  CanvasSurface(this.canvas);

  @override
  void arc(num x, num y, num w, num h, num start, num stop) {
    _paint(
      (paint) => canvas.drawArc(
        Rect.fromCenter(
          center: Offset(x.toDouble(), y.toDouble()),
          width: w.toDouble() * 2,
          height: h.toDouble() * 2,
        ),
        start.toDouble(),
        (stop - start).toDouble(),
        false,
        paint,
      ),
    );
  }

  @override
  void beginClip({bool invert = false}) {
    _clipPath = Path();
    _buildClip = true;
    _invertClip = invert;
  }

  @override
  void beginShape([PointMode mode = PointMode.polygon]) {
    _pointMode = mode;
    _shapePoints.clear();
    _recordingPoints = true;
  }

  @override
  void bezierVertex(num cx1, num cy1, num cx2, num cy2, num x, num y) {
    if (!_recordingPoints) return;
    _shapePoints.add(
      _BezierCommand(
        Offset(cx1.toDouble(), cy1.toDouble()),
        Offset(cx2.toDouble(), cy2.toDouble()),
        Offset(x.toDouble(), y.toDouble()),
      ),
    );
  }

  @override
  void circle(num x, num y, num v) {
    if (_buildClip) {
      _clipPath.addOval(
        Rect.fromCircle(center: Offset(x.toDouble(), y.toDouble()), radius: v.toDouble()),
      );
    } else {
      _paint((paint) => canvas.drawCircle(Offset(x.toDouble(), y.toDouble()), v.toDouble(), paint));
    }
  }

  @override
  void endClip() {
    if (_invertClip) {
      _clipPath
        ..addRect(Rect.fromLTRB(-9999, -9999, 9999, 9999))
        ..fillType = PathFillType.evenOdd;
    }
    canvas.clipPath(_clipPath);
    _buildClip = false;
  }

  @override
  void endShape({bool close = false}) {
    if (_shapePoints.isEmpty) {
      _recordingPoints = false;
      _shapePoints.clear();
      return;
    }

    if (_buildClip) {
      final path = _clipPath; //Path();
      var init = false;
      for (final point in _shapePoints) {
        switch (point) {
          case _VertexCommand(:final point):
            if (!init) {
              path.moveTo(point.dx, point.dy);
              init = true;
            } else {
              path.lineTo(point.dx, point.dy);
            }
          case _BezierCommand(:final c1, :final c2, :final point):
            path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, point.dx, point.dy);
        }
      }
      if (close) path.close();
      // _clipPath.addPath(path, .zero);
      _recordingPoints = false;
      _shapePoints.clear();
      return;
    }

    if (_pointMode == .polygon) {
      final path = Path();
      var init = false;
      for (final point in _shapePoints) {
        switch (point) {
          case _VertexCommand(:final point):
            if (!init) {
              path.moveTo(point.dx, point.dy);
              init = true;
            } else {
              path.lineTo(point.dx, point.dy);
            }
          case _BezierCommand(:final c1, :final c2, :final point):
            path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, point.dx, point.dy);
        }
      }
      if (close) path.close();
      _paint((paint) => canvas.drawPath(path, paint));
    } else {
      final points = _shapePoints.whereType<_VertexCommand>().map((e) => e.point).toList();
      if (close) {
        points.add(points.first);
      }
      _paint((paint) => canvas.drawPoints(_pointMode, points, paint));
    }
    _recordingPoints = false;
    _shapePoints.clear();
  }

  @override
  void fill(Color color) {
    _styleStack.last.applyFill = true;
    _styleStack.last.fill = color;
  }

  @override
  void line(num x1, num y1, num x2, num y2) {
    canvas.drawLine(
      Offset(x1.toDouble(), y1.toDouble()),
      Offset(x2.toDouble(), y2.toDouble()),
      _strokePaint,
    );
  }

  @override
  void noFill() {
    _styleStack.last.applyFill = false;
  }

  @override
  void noStroke() {
    _styleStack.last.applyStroke = false;
  }

  @override
  void point(num x, num y) {
    canvas.drawCircle(
      Offset(x.toDouble(), y.toDouble()),
      _styleStack.last.strokeWeight / 2,
      Paint()..color = _style.stroke,
    );
  }

  @override
  void pop() {
    _styleStack.removeLast();
    canvas.restore();
  }

  @override
  void push() {
    _styleStack.add(_styleStack.last.clone());
    canvas.save();
  }

  @override
  void rotate(num a) {
    canvas.rotate(a.toDouble());
  }

  @override
  void scale(num x, [num? y]) {
    canvas.scale(x.toDouble(), y?.toDouble());
  }

  @override
  void stroke(Color color) {
    _styleStack.last.applyStroke = true;
    _styleStack.last.stroke = color;
  }

  @override
  void strokeJoin(StrokeJoin join) {
    _styleStack.last.strokeJoin = join;
  }

  @override
  void strokeWeight(num weight) {
    _styleStack.last.strokeWeight = weight.toDouble();
  }

  @override
  void translate(num x, num y) {
    canvas.translate(x.toDouble(), y.toDouble());
  }

  @override
  void vertex(num x, num y) {
    if (!_recordingPoints) return;
    _shapePoints.add(_VertexCommand(Offset(x.toDouble(), y.toDouble())));
  }

  _PaintStyle get _style => _styleStack.last;

  Paint get _strokePaint => Paint()
    ..color = _style.stroke
    ..strokeJoin = _style.strokeJoin
    ..strokeWidth = _style.strokeWeight
    ..strokeMiterLimit = 999
    ..strokeCap = .round
    ..style = .stroke;
  Paint get _fillPaint => Paint()..color = _style.fill;

  void _paint(void Function(Paint paint) fn) {
    if (_style.applyFill) fn(_fillPaint);
    if (_style.applyStroke) fn(_strokePaint);
  }
}
