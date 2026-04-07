import 'dart:math' as math;

import 'package:tavolara/bindings.dart';
import 'package:tavolara/config.dart';
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
    // canvas.setStyle("visibility", "visible");
    p5.noLoop();
  }

  void _draw() {
    if (mark == null) return;

    p5.clear();

    mark!.buildDefaultMark(p5, 0, 0, p5.width);
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

  TavolaraMark({required this.style, required this.config, this.petalResolution = 32});

  void buildDefaultMark(P5 sketch, num x, num y, num size) {
    sketch.push();

    sketch.beginClip();
    sketch.circle(size / 2, size / 2, size);
    sketch.endClip();

    sketch.ellipseMode(sketch.RADIUS);
    sketch.translate(x + size / 2, y + size / 2);

    sketch.fill(style.backgroundColor);
    sketch.noStroke();
    sketch.circle(0, 0, size / 2);

    final scaleFactor = (size / 600);
    sketch.scale(scaleFactor);

    buildMark(sketch);

    sketch.pop();
  }

  void buildMark(P5 sketch) {
    sketch.push();

    buildHalo(sketch);
    buildSepal(sketch);
    buildPetals(sketch);
    buildDisk(sketch);

    // sketch.setFill(style);
    // sketch.fill(sketch.colorGrayscale(255));
    // sketch.circle(0, 0, 300);

    // sketch.beginClip(invert: true);
    // sketch.circle(0, 0, config.diskConfig.radius);
    // sketch.endClip();

    // sketch.setFill(style);
    // sketch.fill(sketch.colorRGB(255, 0, 0));
    // sketch.circle(0, 0, 300);

    sketch.pop();
  }

  void buildHalo(P5 sketch) {
    sketch.push();

    sketch.setStroke(style, .thin);
    sketch.strokeJoin(sketch.MITER);

    switch (config.haloStyle) {
      case .ring:
        sketch.circle(0, 0, 275);
      case .polygon:
        sketch.beginShape();
        for (int i = 0; i < config.haloElementCount; i++) {
          final angle = math.pi * 2 / config.haloElementCount * i + config.haloRotation;
          final p = sketch.createVector(math.cos(angle), math.sin(angle));
          p.mult(275);
          sketch.vertex(p.x, p.y);
        }
        sketch.endShape(sketch.CLOSE);
      case .gear:
        sketch.beginShape(1);
        for (int i = 0; i < config.haloElementCount; i++) {
          final step = math.pi * 2 / config.haloElementCount / 4;
          final angle = (math.pi * 2 / config.haloElementCount * i) + config.haloRotation;
          final p1 = sketch.createVector(math.cos(angle), math.sin(angle));
          final p2 = sketch.createVector(math.cos(angle), math.sin(angle));
          final p3 = sketch.createVector(math.cos(angle + step * 2), math.sin(angle + step * 2));
          final p4 = sketch.createVector(math.cos(angle + step * 2), math.sin(angle + step * 2));
          p1.mult(250);
          p2.mult(275);
          p3.mult(275);
          p4.mult(250);
          sketch.vertex(p1.x, p1.y);
          sketch.vertex(p2.x, p2.y);
          sketch.arc(0, 0, 275, 275, angle, angle + step * 2);
          sketch.arc(0, 0, 250, 250, angle + step * 2, angle + step * 4);
          sketch.vertex(p3.x, p3.y);
          sketch.vertex(p4.x, p4.y);
        }
        sketch.endShape(sketch.CLOSE);
      case .petal:
        sketch.beginShape();
        final res = 64 * config.haloElementCount;
        for (int i = 0; i < res; i++) {
          final p = petalBuilder(
            sketch,
            (math.pi * 2 / res) * i,
            roundPetals,
            config.haloElementCount,
            config.haloRotation,
            275,
            250,
          );
          sketch.vertex(p.x, p.y);
        }
        sketch.endShape(sketch.CLOSE);
    }
    sketch.pop();
  }

  void buildDisk(P5 sketch) {
    switch (config.diskConfig) {
      case ConcentricDiskConfiguration concentricConfig:
        final intraSpace = config.diskConfig.radius - concentricConfig.innerRadius;

        if (concentricConfig.innerRadius < 8) {
          sketch.setFill(style);
          sketch.circle(0, 0, concentricConfig.innerRadius);
        }

        sketch.setStroke(style, .thin);
        sketch.circle(0, 0, concentricConfig.innerRadius);

        switch (concentricConfig.decoration) {
          case .none:
            break;
          case .lines:
            final spaceFromEdge = intraSpace > 20;

            sketch.setStroke(style, .thinner);
            for (int i = 0; i < concentricConfig.elementAmount; i++) {
              final angleOffset = 0; //ccConfig.elementVariance[i];
              final angle =
                  ((math.pi * 2) / concentricConfig.elementAmount) * i +
                  concentricConfig.rotation +
                  angleOffset;

              final rotationPoint = sketch.createVector(math.cos(angle), math.sin(angle));
              final a = rotationPoint.copy();
              if (spaceFromEdge) {
                a.mult(concentricConfig.innerRadius + intraSpace / 2 - 8);
              } else {
                a.mult(config.diskConfig.radius);
              }

              final b = rotationPoint.copy();
              if (spaceFromEdge) {
                b.mult(concentricConfig.innerRadius + intraSpace / 2 + 8);
              } else {
                b.mult(config.diskConfig.radius);
              }

              sketch.line(a.x, a.y, b.x, b.y);
            }
            break;
          case .dots:
            sketch.push();

            sketch.setStroke(style, .thin);
            sketch.rotate(concentricConfig.rotation);
            for (int i = 0; i < concentricConfig.elementAmount; i++) {
              final variance = sketch.createVector(0, 0); //ccConfig.elementVariance[i];

              sketch.point(variance.x, concentricConfig.innerRadius + intraSpace / 2 + variance.y);
              sketch.rotate((math.pi * 2) / concentricConfig.elementAmount);
            }

            sketch.pop();
            break;
        }

        sketch.setStroke(style, .thicker);
        sketch.circle(0, 0, config.diskConfig.radius);

        break;
      case SimpleDiskConfiguration _:
        sketch.setStroke(style, .thicker);
        sketch.circle(0, 0, config.diskConfig.radius);

        break;
      case FaceDiskConfiguration faceConfig:
        sketch.setStroke(style, .thicker);
        sketch.circle(0, 0, config.diskConfig.radius);

        sketch.push();

        sketch.beginClip();
        sketch.circle(0, 0, config.diskConfig.radius);
        sketch.endClip();

        buildEye(
          sketch,
          faceConfig.eyeStyle,
          -42 - faceConfig.eyeVariance.dx,
          -20 + faceConfig.eyeVariance.dy,
        );
        buildEye(
          sketch,
          faceConfig.eyeStyle,
          42 + faceConfig.eyeVariance.dx,
          -20 + faceConfig.eyeVariance.dy,
        );
        buildMouth(sketch, faceConfig.mouthStyle, 0, 44);
        buildNose(sketch, faceConfig.noseStyle, 0, -12);

        buildCheek(sketch, faceConfig.cheekStyle, faceConfig.cheekVariance.dx, -54, 25);
        buildCheek(sketch, faceConfig.cheekStyle, faceConfig.cheekVariance.dy, 54, 25);

        sketch.pop();

        break;
    }
  }

  void buildEye(P5 sketch, int eyeStyle, num x, num y) {
    sketch.push();

    sketch.translate(x, y);

    switch (eyeStyle) {
      case 0:
        sketch.setStroke(style, .thick);

        sketch.beginShape();
        sketch.vertex(-14, 0);
        sketch.bezierVertex(-14, 0, -7.58, -7, 0, -7);
        sketch.bezierVertex(7.58, -7, 14, 0, 14, 0);
        sketch.bezierVertex(14, 0, 7.58, 7, 0, 7);
        sketch.bezierVertex(-7.58, 7, -14, 0, -14, 0);
        sketch.endShape(sketch.CLOSE);

        break;
      case 1:
        sketch.setStroke(style, .thick);
        sketch.circle(0, 0, 6);
        sketch.circle(0, 0, 15);
        break;
      case 2:
        sketch.setStroke(style, .thick);
        sketch.strokeWeight(16);
        sketch.point(0, 0);
        break;
    }

    sketch.pop();
  }

  void buildMouth(P5 sketch, int mouthStyle, num x, num y) {
    sketch.push();
    sketch.translate(x, y);

    sketch.setStroke(style, .thin);

    switch (mouthStyle) {
      case 0:
        sketch.beginShape();
        sketch.vertex(-22, 0);
        sketch.bezierVertex(-22, 0, -14, -9, 0, -9);
        sketch.bezierVertex(14, -9, 22, 0, 22, 0);
        sketch.bezierVertex(22, 0, 14, 9, 0, 9);
        sketch.bezierVertex(-14, 9, -22, 0, -22, 0);
        sketch.endShape(sketch.CLOSE);

        sketch.line(-22, 0, 22, 0);
        break;
      case 1:
        sketch.beginShape();
        sketch.vertex(-26, -9);
        sketch.vertex(26, -9);
        sketch.vertex(26, 9);
        sketch.vertex(-26, 9);
        sketch.endShape(sketch.CLOSE);

        sketch.line(-26, 0, 26, 0);
        break;
      case 2:
        sketch.beginShape();
        sketch.vertex(-18, 0);
        sketch.vertex(18, 0);
        sketch.endShape();

        break;
      case 3:
        sketch.circle(0, 0, 5);
        sketch.circle(0, 0, 13);
        break;
    }

    sketch.pop();
  }

  void buildNose(P5 sketch, int noseStyle, num x, num y) {
    sketch.push();
    sketch.translate(x, y);

    sketch.beginShape();

    sketch.setStroke(style, .thicker);

    switch (noseStyle) {
      case 0:
        sketch.vertex(-41, -32);
        sketch.bezierVertex(-2, -23.5, -7, 32, -7, 32);
        sketch.vertex(7, 32);
        sketch.bezierVertex(7, 32, 2, -23.5, 41, -32);
        break;
      case 1:
        sketch.vertex(-35, -32);
        sketch.bezierVertex(-11, -33.5, -6.5, -16, -9, 32);
        sketch.vertex(9, 32);
        sketch.bezierVertex(6.5, -16, 11, -33.5, 35, -32);
        break;
      case 2:
        sketch.vertex(-35, -32);
        sketch.bezierVertex(-15, -45.5, 9.57, -13.5, -19, 32);
        sketch.vertex(19, 32);
        sketch.bezierVertex(-9.57, -13.5, 15, -45.5, 35, -32);
        break;
      case 3:
        sketch.vertex(-10, -2);
        sketch.vertex(-19, 32);
        sketch.vertex(19, 32);
        sketch.vertex(10, -2);
        break;
    }

    sketch.endShape();

    sketch.pop();
  }

  void buildCheek(P5 sketch, int cheekStyle, double variance, num x, num y) {
    sketch.push();
    sketch.translate(x, y);

    sketch.setStroke(style, .thinner);

    switch (cheekStyle) {
      case 1:
        break;
      case 2:
        sketch.circle(0, 0, 8);
        sketch.circle(0, 0, 19);
        break;
      default:
        sketch.beginShape();

        for (int i = 0; i < cheekStyle; i++) {
          final angle = (math.pi * 2 / cheekStyle) * i + variance;
          final p = sketch.createVector(math.cos(angle) * 11, math.sin(angle) * 11);
          sketch.vertex(p.x, p.y);
        }

        sketch.endShape(sketch.CLOSE);

        sketch.beginShape();

        for (int i = 0; i < cheekStyle; i++) {
          final angle = (math.pi * 2 / cheekStyle) * i + variance;
          final p = sketch.createVector(math.cos(angle) * 24, math.sin(angle) * 24);
          sketch.vertex(p.x, p.y);
        }

        sketch.endShape(sketch.CLOSE);
    }

    sketch.pop();
  }

  void buildPetals(P5 sketch) {
    sketch.push();

    sketch.beginClip(invert: true);
    sketch.circle(
      0,
      0,
      config.generatePetalRing
          ? config.diskConfig.radius + config.petalDiskDistance
          : config.diskConfig.radius,
    );
    sketch.endClip();

    if (config.doubleOutline) buildDoubleOutline(sketch);

    buildPrimaryOutline(sketch);

    if (config.generatePetalRing) {
      sketch.setStroke(style, .thick);
      sketch.circle(0, 0, config.diskConfig.radius + config.petalDiskDistance);
    }

    sketch.pop();
  }

  void buildPrimaryOutline(P5 sketch, [bool? fillShape]) {
    if (fillShape == true || config.petalStyle == .narrowSpikes) {
      sketch.fillOn(style);
    } else {
      sketch.fillOff(style);
    }

    if (config.petalStyle != .narrowSpikes) {
      sketch.strokeOn(style, .thicker);
      sketch.strokeJoin(config.petalStyle == .narrowSpikes ? sketch.ROUND : sketch.MITER);
    } else {
      sketch.strokeOff(style);
    }

    if (config.petalStyle != .narrowSpikes) {
      sketch.beginShape();
    }
    for (int i = 0; i < config.petalCount; i++) {
      final angleDelta =
          math.pi * 2 / config.petalCount / (config.petalStyle == .narrowSpikes ? 3 : 2);
      final angle = (math.pi * 2 / config.petalCount) * i + config.petalAngle;

      switch (config.petalStyle) {
        case .spikes:
          final topAnglePoint = sketch.createVector(math.cos(angle), math.sin(angle));
          final rightAnglePoint = sketch.createVector(
            math.cos(angle + angleDelta),
            math.sin(angle + angleDelta),
          );
          final leftAnglePoint = sketch.createVector(
            math.cos(angle - angleDelta),
            math.sin(angle - angleDelta),
          );
          topAnglePoint.mult(config.petalOuterRadius);
          leftAnglePoint.mult(config.starInnerRadius);
          rightAnglePoint.mult(config.starInnerRadius);

          sketch.vertex(leftAnglePoint.x, leftAnglePoint.y);
          sketch.vertex(topAnglePoint.x, topAnglePoint.y);
          sketch.vertex(rightAnglePoint.x, rightAnglePoint.y);
          break;
        case .narrowSpikes:
          final topAnglePoint = sketch.createVector(math.cos(angle), math.sin(angle));
          final rightAnglePoint = sketch.createVector(
            math.cos(angle + angleDelta),
            math.sin(angle + angleDelta),
          );
          final leftAnglePoint = sketch.createVector(
            math.cos(angle - angleDelta),
            math.sin(angle - angleDelta),
          );
          topAnglePoint.mult(config.petalOuterRadius);
          leftAnglePoint.mult(config.starInnerRadius);
          rightAnglePoint.mult(config.starInnerRadius);

          sketch.beginShape();
          sketch.vertex(leftAnglePoint.x, leftAnglePoint.y);
          sketch.vertex(topAnglePoint.x, topAnglePoint.y);
          sketch.vertex(rightAnglePoint.x, rightAnglePoint.y);

          sketch.endShape();
          break;
        case .round:
        case .sharp:
          for (int j = 0; j < petalResolution; j++) {
            final p = petalBuilder(
              sketch,
              ((angleDelta * 2) / petalResolution) * j,
              config.petalStyle == .sharp ? sharpPetals : roundPetals,
              config.petalCount,
              angle - angleDelta / 2,
              config.petalOuterRadius,
              config.starInnerRadius,
            );
            sketch.vertex(p.x, p.y);
          }
      }
    }

    if (config.petalStyle != .narrowSpikes) {
      sketch.endShape(sketch.CLOSE);
    }
  }

  void buildDoubleOutline(P5 sketch, [bool? fillShape]) {
    if (fillShape == true) {
      sketch.fillOn(style);
    } else {
      sketch.fillOff(style);
    }
    sketch.strokeOn(style, config.sepalStyle == .mandala ? .thin : .thinner);
    sketch.strokeJoin(sketch.MITER);

    sketch.beginShape();
    switch (config.petalStyle) {
      case .spikes:
      case .narrowSpikes:
        for (int i = 0; i < config.petalCount; i++) {
          final angleDelta = math.pi * 2 / config.petalCount / 2;
          final angle = (math.pi * 2 / config.petalCount) * i + config.petalAngle;
          final topAnglePoint = sketch.createVector(math.cos(angle), math.sin(angle));
          final leftAnglePoint = sketch.createVector(
            math.cos(angle - angleDelta),
            math.sin(angle - angleDelta),
          );

          topAnglePoint.mult(config.size);
          leftAnglePoint.mult(
            config.diskConfig.radius + config.petalDiskDistance + config.doubleOutlineSpacing / 2,
          );

          sketch.vertex(leftAnglePoint.x, leftAnglePoint.y);
          sketch.vertex(topAnglePoint.x, topAnglePoint.y);
        }
        break;
      case .round:
      case .sharp:
        final res = petalResolution * config.petalCount;
        for (int i = 0; i < res; i++) {
          final p = petalBuilder(
            sketch,
            (math.pi * 2 / res) * i,
            config.petalStyle == .sharp ? sharpPetals : roundPetals,
            config.petalCount,
            config.petalAngle - math.pi * 2 / config.petalCount / 4,
            config.size,
            config.diskConfig.radius + config.petalDiskDistance + config.doubleOutlineSpacing / 2,
          );
          sketch.vertex(p.x, p.y);
        }
        break;
    }
    sketch.endShape(sketch.CLOSE);
  }

  void buildSepal(P5 sketch) {
    final innerRadius = config.doubleOutline
        ? config.diskConfig.radius + config.petalDiskDistance + config.doubleOutlineSpacing
        : config.starInnerRadius;
    final outerRadius = config.doubleOutline ? config.size : config.petalOuterRadius;

    sketch.push();

    if (config.sepalStyle != .none) {
      sketch.beginClip(invert: true);
      if (config.doubleOutline) {
        buildDoubleOutline(sketch, true);
      } else {
        buildPrimaryOutline(sketch, true);
      }
      sketch.endClip();
    }

    if (config.sepalStyle == .mandala) {
      sketch.setStroke(style, config.doubleOutline ? .thinner : .thin);
      sketch.strokeJoin(sketch.MITER);
      sketch.beginShape();
    }

    for (int i = 0; i < config.petalCount; i++) {
      final angleDelta = math.pi * 2 / config.petalCount / 2;
      final angle = (math.pi * 2 / config.petalCount) * i + config.petalAngle;
      final topAnglePoint = sketch.createVector(math.cos(angle), math.sin(angle));
      final leftAnglePoint = sketch.createVector(
        math.cos(angle - angleDelta),
        math.sin(angle - angleDelta),
      );

      final rangeMin = (outerRadius - innerRadius) / 2;
      switch (config.sepalStyle) {
        case .none:
          break;
        case .dots:
          leftAnglePoint.mult(rangeMin * config.sepalDistanceOffset + innerRadius + rangeMin);

          sketch.setFill(style);
          // sketch.setStroke(style);s
          // sketch.strokeWeight(config.sepalDotsSize * 2 + style.strokeWidth);
          // sketch.point(leftAnglePoint.x, leftAnglePoint.y);
          sketch.circle(leftAnglePoint.x, leftAnglePoint.y, config.sepalDotsSize);
          break;
        case .mandala:
          switch (config.petalStyle) {
            case .spikes:
            case .narrowSpikes:
              topAnglePoint.mult(innerRadius);
              leftAnglePoint.mult(rangeMin * config.sepalDistanceOffset + innerRadius + rangeMin);

              sketch.vertex(leftAnglePoint.x, leftAnglePoint.y);
              sketch.vertex(topAnglePoint.x, topAnglePoint.y);
              break;
            case .round:
            case .sharp:
              for (int j = 0; j < petalResolution; j++) {
                final p = petalBuilder(
                  sketch,
                  ((angleDelta * 2) / petalResolution) * j,
                  config.petalStyle == .sharp ? sharpPetals : roundPetals,
                  config.petalCount,
                  angle + angleDelta / 2,
                  rangeMin * config.sepalDistanceOffset + innerRadius + rangeMin,
                  innerRadius,
                );
                sketch.vertex(p.x, p.y);
              }
          }
          break;
      }
    }

    if (config.sepalStyle == .mandala) {
      sketch.endShape(sketch.CLOSE);
    }
    sketch.pop();
  }
}

P5Vector petalBuilder(
  P5 sketch,
  double x,
  double Function(double x) petalFun,
  int petalCount,
  double baseAngle,
  double outerRadius,
  double innerRadius,
) {
  final unit = petalFun(petalCount * x) * (outerRadius - innerRadius) + innerRadius + 1;
  return sketch.createVector(unit * math.cos(x + baseAngle), unit * math.sin(x + baseAngle));
}

double sharpPetals(double x) {
  return (2 * math.asin(math.sin(x))) / (2 * math.pi) + 0.5;
}

double roundPetals(double x) {
  return (math.sin(x / 2 + math.pi / 4)).abs();
}
