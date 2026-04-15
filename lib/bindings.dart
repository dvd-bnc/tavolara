// ignore_for_file: non_constant_identifier_names

import 'dart:js_interop';

import 'package:web/web.dart' as web;

extension type P5ShapeMode._(Object? value) {}

typedef P5Factory = void Function(P5 sketch);
@JS('p5')
extension type P5._(JSObject _) implements JSObject {
  external factory P5._new(JSFunction factory, [web.HTMLElement? parent]);

  factory P5(P5Factory factory, [web.HTMLElement? parent]) {
    return P5._new(factory.toJS, parent);
  }

  @JS('draw')
  external JSFunction _draw;

  @JS('setup')
  external JSFunction _setup;

  void Function() get draw => (() => _draw.callAsFunction());
  void Function() get setup => (() => _setup.callAsFunction());

  set draw(void Function() value) => _draw = value.toJS;
  set setup(void Function() setup) => _setup = setup.toJS;

  external String SVG;
  external String RADIUS;
  external String CLOSE;

  external String MITER;
  external String BEVEL;
  external String ROUND;

  @JS('POINTS')
  external int _POINTS;
  @JS('LINES')
  external int _LINES;
  @JS('TRIANGLES')
  external int _TRIANGLES;
  @JS('TRIANGLE_FAN')
  external int _TRIANGLE_FAN;
  @JS('TRIANGLE_STRIP')
  external int _TRIANGLE_STRIP;
  @JS('QUADS')
  external String _QUADS;
  @JS('QUAD_STRIP')
  external String _QUAD_STRIP;
  @JS('TESS')
  external String _TESS;

  P5ShapeMode get POINTS => P5ShapeMode._(_POINTS);
  P5ShapeMode get LINES => P5ShapeMode._(_LINES);
  P5ShapeMode get TRIANGLES => P5ShapeMode._(_TRIANGLES);
  P5ShapeMode get TRIANGLE_FAN => P5ShapeMode._(_TRIANGLE_FAN);
  P5ShapeMode get TRIANGLE_STRIP => P5ShapeMode._(_TRIANGLE_STRIP);
  P5ShapeMode get QUADS => P5ShapeMode._(_QUADS);
  P5ShapeMode get QUAD_STRIP => P5ShapeMode._(_QUAD_STRIP);
  P5ShapeMode get TESS => P5ShapeMode._(_TESS);

  external num width;
  external num height;

  external web.HTMLCanvasElement createCanvas(num width, num height, [String? renderer]);

  @JS('color')
  external P5Color colorGrayscale(int amount, [int? alpha]);

  @JS('color')
  external P5Color colorRGB(int r, int g, int b, [int? alpha]);

  @JS('color')
  external P5Color colorHex(String hex);

  external void noLoop();
  external void redraw();
  external void save(String name);
  external void clear();

  external void push();
  external void pop();

  external void ellipseMode(String mode);

  @JS('beginClip')
  external void _beginClip([JSObject? config]);
  @JS('beginClip')
  external void _beginClipNoOptions();

  void beginClip({bool? invert}) {
    if (invert != null) {
      final config = {'invert': invert}.jsify() as JSObject;

      _beginClip(config);
    } else {
      _beginClipNoOptions();
    }
  }

  external void endClip();

  external void translate(num x, num y);
  external void scale(num x, [num? y]);
  external void rotate(num a);

  external void strokeWeight(num weight);
  external void strokeJoin(String join);

  external void stroke(P5Color color);
  external void fill(P5Color color);

  external void noStroke();
  external void noFill();

  external void circle(num x, num y, num v);
  external void line(num x1, num y1, num x2, num y2);
  external void point(num x, num y);
  external void arc(num x, num y, num w, num h, num start, num stop, [String? mode]);

  external void vertex(num x, num y);
  external void bezierVertex(num cx1, num cy1, num cx2, num cy2, num x, num y);

  @JS('beginShape')
  external void _beginShape([JSAny? mode]);
  void beginShape([P5ShapeMode? mode]) {
    if (mode == null) {
      _beginShape();
    } else {
      _beginShape(mode.value.jsify());
    }
  }

  external void endShape([String? mode]);
}

extension type P5Color._(JSObject _) implements JSObject {}

extension HTMLElementExt on web.HTMLElement {
  @JS('style')
  external void setStyle(String key, String value);
}
