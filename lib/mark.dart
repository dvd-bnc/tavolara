import 'dart:math' as math;
import 'dart:ui';

import 'package:tavolara/bindings.dart';
import 'package:tavolara/config.dart';
import 'package:tavolara/surface.dart';
import 'package:web/web.dart' as web;

// disk
// petal
// sepal
// halo

class TavolaraSketch {
  late final P5 p5;
  TavolaraMark? mark;

  TavolaraSketch({required double size, required web.HTMLElement parent}) {
    p5 = P5((sketch) {
      sketch.setup = () => _setup(sketch, size);
      sketch.draw = _draw;
    }, parent);
  }

  void _setup(P5 p5, double size) {
    final canvas = p5.createCanvas(size, size, p5.SVG);
    canvas.style.visibility = "visible";
    p5.noLoop();
  }

  void _draw() {
    if (mark == null) return;

    p5.clear();

    mark!.buildDefaultMark(P5Surface(p5), 0, 0, p5.width);
  }

  void save(String name) {
    p5.save("$name.svg");
  }

  void bootstrap(Configuration config, Style style) {
    mark ??= TavolaraMark(config: config, style: style);
    p5.redraw();
  }

  void updateConfiguration(Configuration config) {
    mark!.config = config;
    p5.redraw();
  }

  void updateStyle(Style style) {
    mark!.style = style;
    p5.redraw();
  }
}

class TavolaraMark {
  Style style;
  Configuration config;
  final int petalResolution;

  TavolaraMark({required this.style, required this.config, this.petalResolution = 36});

  void buildDefaultMark(Surface surface, num x, num y, num size) {
    surface.push();

    surface.beginClip();
    surface.circle(size / 2, size / 2, size);
    surface.endClip();

    if (surface case final P5Surface p5surface) {
      p5surface.p5.ellipseMode(p5surface.p5.RADIUS);
    }

    surface.translate(x + size / 2, y + size / 2);

    surface.fill(style.backgroundColor);
    surface.noStroke();
    surface.circle(0, 0, size / 2);

    final scaleFactor = (size / 600);
    surface.scale(scaleFactor);

    // surface.setStroke(style, .thicker);
    // surface.line(0, -200, 0, 200);
    // surface.beginShape();
    // surface.vertex(-200, 0);
    // surface.vertex(0, -200);
    // surface.vertex(200, 0);
    // surface.vertex(0, 200);
    // surface.endShape(close: true);

    buildMark(surface);

    surface.pop();
  }

  void buildMark(Surface surface) {
    surface.push();

    buildHalo(surface);
    buildSepal(surface);
    buildPetal(surface);
    buildDisk(surface);

    surface.pop();
  }

  void buildDisk(Surface surface) {
    switch (config.diskConfig) {
      case ConcentricDiskConfiguration concentricConfig:
        final intraSpace = config.diskConfig.radius - concentricConfig.innerRadius;

        if (concentricConfig.innerRadius < 8) {
          surface.setFill(style);
          surface.circle(0, 0, concentricConfig.innerRadius);
        }

        surface.setStroke(style, .thin);
        surface.circle(0, 0, concentricConfig.innerRadius);

        switch (concentricConfig.decoration) {
          case .none:
            break;
          case .lines:
            final spaceFromEdge = intraSpace > 20;

            surface.setStroke(style, .thinner);
            for (int i = 0; i < concentricConfig.elementAmount; i++) {
              final angle =
                  ((math.pi * 2) / concentricConfig.elementAmount) * i + concentricConfig.rotation;

              final rotationPoint = Offset.fromDirection(angle);
              final a =
                  rotationPoint *
                  (spaceFromEdge
                      ? concentricConfig.innerRadius + intraSpace / 2 - 8
                      : config.diskConfig.radius);
              final b =
                  rotationPoint *
                  (spaceFromEdge
                      ? concentricConfig.innerRadius + intraSpace / 2 + 8
                      : config.diskConfig.radius);

              surface.line(a.dx, a.dy, b.dx, b.dy);
            }
          case .dots:
            surface.push();

            surface.setStroke(style, .thin);
            surface.rotate(concentricConfig.rotation);
            for (int i = 0; i < concentricConfig.elementAmount; i++) {
              surface.point(0, concentricConfig.innerRadius + intraSpace / 2);
              surface.rotate((math.pi * 2) / concentricConfig.elementAmount);
            }

            surface.pop();
        }

        surface.setStroke(style, .thicker);
        surface.circle(0, 0, config.diskConfig.radius);
      case SimpleDiskConfiguration _:
        surface.setStroke(style, .thicker);
        surface.circle(0, 0, config.diskConfig.radius);
        surface.setStroke(style, .thin);
        surface.circle(0, 0, config.diskConfig.radius / 3);
        surface.setFill(style);
        surface.circle(0, 0, config.diskConfig.radius / 6);
      case FaceDiskConfiguration faceConfig:
        surface.setStroke(style, .thicker);
        surface.circle(0, 0, config.diskConfig.radius);

        surface.push();

        surface.beginClip();
        surface.circle(0, 0, config.diskConfig.radius);
        surface.endClip();

        buildEye(
          surface,
          faceConfig.eyeStyle,
          -42 - faceConfig.eyeVariance.dx,
          -20 + faceConfig.eyeVariance.dy,
        );
        if (faceConfig.noseStyle != .winking) {
          buildEye(
            surface,
            faceConfig.eyeStyle,
            42 + faceConfig.eyeVariance.dx,
            -20 + faceConfig.eyeVariance.dy,
          );
        }
        buildMouth(surface, faceConfig.mouthStyle, 0, 48);
        buildNose(surface, faceConfig.noseStyle, 0, -12);

        buildCheek(surface, faceConfig.cheekStyle, faceConfig.cheekVariance.dx, -54, 25);
        buildCheek(surface, faceConfig.cheekStyle, faceConfig.cheekVariance.dy, 54, 25);

        surface.pop();
    }
  }

  void buildEye(Surface surface, FaceDiskEyeStyle eyeStyle, num x, num y) {
    surface.push();

    surface.translate(x, y);

    switch (eyeStyle) {
      case .almond:
        surface.setStroke(style, .thin);

        surface.beginShape();
        surface.vertex(-14, 0);
        surface.bezierVertex(-14, 0, -7.58, -7, 0, -7);
        surface.bezierVertex(7.58, -7, 14, 0, 14, 0);
        surface.bezierVertex(14, 0, 7.58, 7, 0, 7);
        surface.bezierVertex(-7.58, 7, -14, 0, -14, 0);
        surface.endShape(close: true);
      case .concentric:
        surface.setStroke(style, .thin);
        surface.circle(0, 0, 6);
        surface.circle(0, 0, 15);
      case .dot:
        surface.setStroke(style, .thickest);
        surface.point(0, 0);
    }

    surface.pop();
  }

  void buildMouth(Surface surface, FaceDiskMouthStyle mouthStyle, num x, num y) {
    surface.push();
    surface.translate(x, y);

    surface.setStroke(style, .thin);

    switch (mouthStyle) {
      case .elliptical:
        surface.beginShape();
        surface.vertex(-22, 0);
        surface.bezierVertex(-22, 0, -14, -9, 0, -9);
        surface.bezierVertex(14, -9, 22, 0, 22, 0);
        surface.bezierVertex(22, 0, 14, 9, 0, 9);
        surface.bezierVertex(-14, 9, -22, 0, -22, 0);
        surface.endShape(close: true);

        surface.line(-22, 0, 22, 0);
      case .rectangular:
        surface.beginShape();
        surface.vertex(-26, -9);
        surface.vertex(26, -9);
        surface.vertex(26, 9);
        surface.vertex(-26, 9);
        surface.endShape(close: true);

        surface.line(-26, 0, 26, 0);
      case .line:
        surface.beginShape();
        surface.vertex(-18, 0);
        surface.vertex(18, 0);
        surface.endShape();
      case .concentric:
        surface.circle(0, 0, 5);
        surface.circle(0, 0, 13);
      case .smiling:
        surface.beginShape();
        surface.vertex(-26, -8);
        surface.bezierVertex(-25.67, -1.33, -22.14, 4.76, -17, 8);
        surface.vertex(17, 8);
        surface.bezierVertex(22.14, 4.76, 25.67, -1.33, 26, -8);
        surface.endShape(close: true);

        surface.line(-23.97, 0, 23.97, 0);
    }

    surface.pop();
  }

  void buildNose(Surface surface, FaceDiskNoseStyle noseStyle, num x, num y) {
    surface.push();
    surface.translate(x, y);

    surface.beginShape();

    surface.setStroke(style, .thicker);

    switch (noseStyle) {
      case .eagled:
        surface.vertex(-41, -32);
        surface.bezierVertex(-2, -23.5, -7, 32, -7, 32);
        surface.vertex(7, 32);
        surface.bezierVertex(7, 32, 2, -23.5, 41, -32);
      case .straight:
        surface.vertex(-35, -32);
        surface.bezierVertex(-11, -33.5, -6.5, -16, -9, 32);
        surface.vertex(9, 32);
        surface.bezierVertex(6.5, -16, 11, -33.5, 35, -32);
      case .rounded:
        surface.vertex(-35, -32);
        surface.bezierVertex(-15, -45.5, 9.57, -13.5, -19, 32);
        surface.vertex(19, 32);
        surface.bezierVertex(-9.57, -13.5, 15, -45.5, 35, -32);
      case .wide:
        surface.vertex(-10, -2);
        surface.vertex(-19, 32);
        surface.vertex(19, 32);
        surface.vertex(10, -2);
      case .winking:
        surface.vertex(-9, 32);
        surface.vertex(9, 32);
        surface.bezierVertex(7, -7, 16.37, -17, 34.87, -17);
        surface.vertex(48.87, -17);
    }

    surface.endShape();

    surface.pop();
  }

  void buildCheek(Surface surface, FaceDiskCheekStyle cheekStyle, double variance, num x, num y) {
    surface.push();
    surface.translate(x, y);

    surface.setStroke(style, .thinner);

    switch (cheekStyle.value) {
      case 1:
        break;
      case 2:
        surface.circle(0, 0, 8);
        surface.circle(0, 0, 19);
      default:
        surface.beginShape();

        for (int i = 0; i < cheekStyle.value; i++) {
          final angle = (math.pi * 2 / cheekStyle.value) * i + variance;
          final p = Offset.fromDirection(angle, 11);
          surface.vertex(p.dx, p.dy);
        }

        surface.endShape(close: true);

        surface.beginShape();

        for (int i = 0; i < cheekStyle.value; i++) {
          final angle = (math.pi * 2 / cheekStyle.value) * i + variance;
          final p = Offset.fromDirection(angle, 24);
          surface.vertex(p.dx, p.dy);
        }

        surface.endShape(close: true);
    }

    surface.pop();
  }

  void buildPetal(Surface surface) {
    surface.push();

    surface.beginClip(invert: true);
    surface.circle(
      0,
      0,
      config.generatePetalRing
          ? config.diskConfig.radius + config.petalDiskDistance
          : config.diskConfig.radius,
    );
    surface.endClip();

    if (config.petalStyle == .narrowSpikes) {
      surface.fillOn(style);
    } else {
      surface.fillOff(style);
    }

    if (config.petalStyle == .narrowSpikes) {
      surface.strokeOff(style);
    } else {
      surface.strokeOn(style, .thick);

      if (config.petalStyle == .spikes && config.petalCount >= 8) {
        surface.strokeJoin(.round);
      } else {
        surface.strokeJoin(.miter);
      }
    }

    buildPetalShape(surface);

    if (config.generatePetalRing) {
      surface.setStroke(style, .thick);
      surface.circle(0, 0, config.diskConfig.radius + config.petalDiskDistance);
    }

    surface.pop();
  }

  void buildPetalShape(Surface surface) {
    surface.beginShape();
    for (int i = 0; i < config.petalCount; i++) {
      final angleDelta =
          math.pi * 2 / config.petalCount / (config.petalStyle == .narrowSpikes ? 3 : 2);
      final angle = (math.pi * 2 / config.petalCount) * i + config.petalAngle;

      switch (config.petalStyle) {
        case .spikes:
        case .narrowSpikes:
          final topAnglePoint = Offset.fromDirection(angle, config.petalOuterRadius);
          final rightAnglePoint = Offset.fromDirection(angle + angleDelta, config.starInnerRadius);
          final leftAnglePoint = Offset.fromDirection(angle - angleDelta, config.starInnerRadius);

          surface.vertex(leftAnglePoint.dx, leftAnglePoint.dy);
          surface.vertex(topAnglePoint.dx, topAnglePoint.dy);
          surface.vertex(rightAnglePoint.dx, rightAnglePoint.dy);
        case .sharp:
          for (int j = 0; j < petalResolution; j++) {
            final p = petalBuilder(
              surface,
              ((angleDelta * 2) / petalResolution) * j,
              sharpPetals,
              config.petalCount,
              angle - angleDelta / 2,
              config.petalOuterRadius,
              config.starInnerRadius,
            );
            surface.vertex(p.dx, p.dy);
          }
      }
    }

    surface.endShape(close: true);
  }

  void buildSepal(Surface surface) {
    surface.push();

    if (config.sepalStyle != .none) {
      surface.beginClip(invert: true);
      buildPetalShape(surface);
      surface.endClip();
    }

    surface.setStroke(style, .thin);
    surface.strokeJoin(.miter);

    buildSepalShape(surface);

    if (config.sepalStyle == .mandala && config.petalStyle != .narrowSpikes) {
      surface.push();

      surface.beginClip();
      buildSepalShape(surface);
      surface.endClip();

      surface.setStroke(style, .thinner);
      final resolution = 12 * config.petalCount;
      for (int i = 0; i < resolution; i++) {
        final rangeMin = (config.petalOuterRadius - config.starInnerRadius) / 2;
        var p = Offset.fromDirection(
          config.petalAngle + math.pi * 2 / resolution * i,
          rangeMin * config.sepalDistanceOffset + config.starInnerRadius + rangeMin,
        );
        surface.line(p.dx, p.dy, 0, 0);
      }

      surface.pop();
    }

    surface.pop();
  }

  void buildSepalShape(Surface surface) {
    if (config.sepalStyle == .mandala) {
      surface.beginShape();
    }

    for (int i = 0; i < config.petalCount; i++) {
      final angleDelta = math.pi * 2 / config.petalCount / 2;
      final angle = (math.pi * 2 / config.petalCount) * i + config.petalAngle;
      var topAnglePoint = Offset.fromDirection(angle);
      var leftAnglePoint = Offset.fromDirection(angle - angleDelta);

      final rangeMin = (config.petalOuterRadius - config.starInnerRadius) / 2;
      switch (config.sepalStyle) {
        case .none:
          break;
        case .dots:
          leftAnglePoint *=
              rangeMin * config.sepalDistanceOffset + config.starInnerRadius + rangeMin;

          surface.circle(leftAnglePoint.dx, leftAnglePoint.dy, config.sepalDotsSize);
          surface.circle(leftAnglePoint.dx, leftAnglePoint.dy, config.sepalDotsSize / 3);
        case .mandala:
          switch (config.petalStyle) {
            case .spikes:
            case .narrowSpikes:
              topAnglePoint *= config.starInnerRadius;
              leftAnglePoint *=
                  rangeMin * config.sepalDistanceOffset + config.starInnerRadius + rangeMin;

              surface.vertex(leftAnglePoint.dx, leftAnglePoint.dy);
              surface.vertex(topAnglePoint.dx, topAnglePoint.dy);
            case .sharp:
              for (int j = 0; j < petalResolution; j++) {
                final p = petalBuilder(
                  surface,
                  ((angleDelta * 2) / petalResolution) * j,
                  sharpPetals,
                  config.petalCount,
                  angle + angleDelta / 2,
                  rangeMin * config.sepalDistanceOffset + config.starInnerRadius + rangeMin,
                  config.starInnerRadius,
                );
                surface.vertex(p.dx, p.dy);
              }
          }
      }
    }

    if (config.sepalStyle == .mandala) {
      surface.endShape(close: true);
    }
  }

  void buildHalo(Surface surface) {
    surface.push();

    surface.setStroke(style, .thin);
    surface.strokeJoin(config.haloStyle == .contraPetal ? .round : .miter);

    if (config.haloStyle == .contraPetal) {
      surface.beginClip();
      surface.circle(0, 0, 275 + (style.strokeClasses[StrokeClass.thin]! / 2));
      surface.endClip();
    }

    buildHaloShape(surface);

    surface.pop();
  }

  void buildHaloShape(Surface surface) {
    if (config.haloStyle == .hatching) {
      surface.beginShape(.lines);
    } else {
      surface.beginShape();
    }

    switch (config.haloStyle) {
      case .ring:
        for (int i = 0; i < 240; i++) {
          final p1 = Offset.fromDirection(config.haloRotation + math.pi * 2 / 240 * i, 275);
          final p2 = Offset.fromDirection(
            config.haloRotation + math.pi * 2 / 480 + math.pi * 2 / 240 * i,
            270,
          );
          final p3 = Offset.fromDirection(config.haloRotation + math.pi * 2 / 240 * i, 265);
          final p4 = Offset.fromDirection(
            config.haloRotation + math.pi * 2 / 480 + math.pi * 2 / 240 * i,
            260,
          );
          final p5 = Offset.fromDirection(config.haloRotation + math.pi * 2 / 240 * i, 255);
          surface.setStroke(style, .thinner);
          surface.point(p1.dx, p1.dy);
          surface.setStroke(style, .thin);
          surface.point(p2.dx, p2.dy);
          surface.setStroke(style, .thinner);
          surface.point(p3.dx, p3.dy);
          surface.setStroke(style, .thin);
          surface.point(p4.dx, p4.dy);
          surface.setStroke(style, .thinner);
          surface.point(p5.dx, p5.dy);
        }
      case .gear:
        for (int i = 0; i < config.haloElementCount; i++) {
          final step = math.pi * 2 / config.haloElementCount / 4;
          final angle = (math.pi * 2 / config.haloElementCount * i) + config.haloRotation;

          surface.arc(0, 0, 275, 275, angle, angle + step * 3);
          surface.arc(0, 0, 240, 240, angle + step * 2, angle + step * 4);

          for (int i = 0; i <= 4; i++) {
            final intra = (275 - 240) / 4 * i;
            surface.arc(0, 0, 240 + intra, 240 + intra, angle, angle + step);
            surface.arc(0, 0, 240 + intra, 240 + intra, angle + step * 2, angle + step * 3);
          }
        }
      case .contraPetal:
        surface.circle(0, 0, 275);

        final res = 64 * config.haloElementCount;
        for (int i = 0; i < res; i++) {
          final p = petalBuilder(
            surface,
            (math.pi * 2 / res) * i,
            circlePetals,
            config.haloElementCount,
            config.haloRotation,
            240,
            275,
          );
          surface.vertex(p.dx, p.dy);
        }
      case .hatching:
        final angleDelta = math.pi * 2 / config.haloElementCount;
        final parts = (angleDelta * 180 / math.pi) ~/ 2;
        for (int i = 0; i < config.haloElementCount; i++) {
          for (int j = 0; j < parts; j++) {
            final progress = j / parts;
            final pointA = Offset.fromDirection(
              config.haloRotation + angleDelta * i + angleDelta / parts * j,
              275,
            );
            final amplitude = parts >= 5
                ? math.sin(progress * 2 * math.pi + math.pi / 2) / 2 + 1 / 2
                : math.asin(math.sin(progress * 2 * math.pi + math.pi / 2)) / math.pi + 1 / 2;
            final pointB = Offset.fromDirection(
              config.haloRotation + angleDelta * i + angleDelta / parts * j,
              265 - (25 * amplitude),
            );
            surface.vertex(pointA.dx, pointA.dy);
            surface.vertex(pointB.dx, pointB.dy);
          }
        }
    }

    surface.endShape(close: true);
  }
}

Offset petalBuilder(
  Surface surface,
  double x,
  double Function(double x) petalFun,
  int petalCount,
  double baseAngle,
  double outerRadius,
  double innerRadius,
) {
  final unit = petalFun(petalCount * x) * (outerRadius - innerRadius) + innerRadius + 1;
  return Offset.fromDirection(x + baseAngle, unit);
}

double sharpPetals(double x) {
  return (2 * math.asin(math.sin(x))) / (2 * math.pi) + 0.5;
}

double roundPetals(double x) {
  return (math.sin(x / 2 + math.pi / 4)).abs();
}

double circlePetals(double x) {
  double f(double x) => math.sqrt(-math.pow(x - math.pi, 2) + math.pi * math.pi) / math.pi;
  double g(double x) => f(x % (2 * math.pi));

  return g(x + math.pi / 2);
}
