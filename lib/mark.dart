import 'dart:math' as math;
import 'dart:ui';

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

  TavolaraMark({required this.style, required this.config, this.petalResolution = 36});

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

    // sketch.push();

    // sketch.beginClip();
    // buildHaloShape(sketch);
    // sketch.endClip();

    // sketch.beginClip(invert: true);
    // buildPetalsShape(sketch);
    // sketch.endClip();

    // sketch.beginClip(invert: true);
    // buildSepalShape(sketch);
    // sketch.endClip();

    // sketch.fill(sketch.colorRGB(255, 0, 0));
    // sketch.noStroke();
    // sketch.circle(0, 0, 300);

    // sketch.pop();

    // sketch.push();

    // sketch.beginClip();
    // buildPetalsShape(sketch);
    // buildSepalShape(sketch);
    // sketch.endClip();

    // sketch.beginClip(invert: true);
    // sketch.circle(
    //   0,
    //   0,
    //   config.generatePetalRing
    //       ? config.diskConfig.radius + config.petalDiskDistance
    //       : config.diskConfig.radius,
    // );
    // sketch.endClip();

    // sketch.fill(sketch.colorRGB(0, 0, 255));
    // sketch.noStroke();
    // sketch.circle(0, 0, 300);

    // sketch.pop();

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
        sketch.setStroke(style, .thin);
        sketch.circle(0, 0, config.diskConfig.radius / 3);
        sketch.setFill(style);
        sketch.circle(0, 0, config.diskConfig.radius / 6);

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
        if (faceConfig.noseStyle != .winking) {
          buildEye(
            sketch,
            faceConfig.eyeStyle,
            42 + faceConfig.eyeVariance.dx,
            -20 + faceConfig.eyeVariance.dy,
          );
        }
        buildMouth(sketch, faceConfig.mouthStyle, 0, 48);
        buildNose(sketch, faceConfig.noseStyle, 0, -12);

        buildCheek(sketch, faceConfig.cheekStyle, faceConfig.cheekVariance.dx, -54, 25);
        buildCheek(sketch, faceConfig.cheekStyle, faceConfig.cheekVariance.dy, 54, 25);

        sketch.pop();

        break;
    }
  }

  void buildEye(P5 sketch, FaceDiskEyeStyle eyeStyle, num x, num y) {
    sketch.push();

    sketch.translate(x, y);

    switch (eyeStyle) {
      case .almond:
        sketch.setStroke(style, .thick);

        sketch.beginShape();
        sketch.vertex(-14, 0);
        sketch.bezierVertex(-14, 0, -7.58, -7, 0, -7);
        sketch.bezierVertex(7.58, -7, 14, 0, 14, 0);
        sketch.bezierVertex(14, 0, 7.58, 7, 0, 7);
        sketch.bezierVertex(-7.58, 7, -14, 0, -14, 0);
        sketch.endShape(sketch.CLOSE);
      case .concentric:
        sketch.setStroke(style, .thick);
        sketch.circle(0, 0, 6);
        sketch.circle(0, 0, 15);
      case .dot:
        sketch.setStroke(style, .thickest);
        sketch.point(0, 0);
    }

    sketch.pop();
  }

  void buildMouth(P5 sketch, FaceDiskMouthStyle mouthStyle, num x, num y) {
    sketch.push();
    sketch.translate(x, y);

    sketch.setStroke(style, .thin);

    switch (mouthStyle) {
      case .elliptical:
        sketch.beginShape();
        sketch.vertex(-22, 0);
        sketch.bezierVertex(-22, 0, -14, -9, 0, -9);
        sketch.bezierVertex(14, -9, 22, 0, 22, 0);
        sketch.bezierVertex(22, 0, 14, 9, 0, 9);
        sketch.bezierVertex(-14, 9, -22, 0, -22, 0);
        sketch.endShape(sketch.CLOSE);

        sketch.line(-22, 0, 22, 0);
      case .rectangular:
        sketch.beginShape();
        sketch.vertex(-26, -9);
        sketch.vertex(26, -9);
        sketch.vertex(26, 9);
        sketch.vertex(-26, 9);
        sketch.endShape(sketch.CLOSE);

        sketch.line(-26, 0, 26, 0);
      case .line:
        sketch.beginShape();
        sketch.vertex(-18, 0);
        sketch.vertex(18, 0);
        sketch.endShape();
      case .concentric:
        sketch.circle(0, 0, 5);
        sketch.circle(0, 0, 13);
      case .smiling:
        sketch.beginShape();
        sketch.vertex(-26, -8);
        sketch.bezierVertex(-25.67, -1.33, -22.14, 4.76, -17, 8);
        sketch.vertex(17, 8);
        sketch.bezierVertex(22.14, 4.76, 25.67, -1.33, 26, -8);
        sketch.endShape(sketch.CLOSE);

        sketch.line(-23.97, 0, 23.97, 0);
    }

    sketch.pop();
  }

  void buildNose(P5 sketch, FaceDiskNoseStyle noseStyle, num x, num y) {
    sketch.push();
    sketch.translate(x, y);

    sketch.beginShape();

    sketch.setStroke(style, .thicker);

    switch (noseStyle) {
      case .eagled:
        sketch.vertex(-41, -32);
        sketch.bezierVertex(-2, -23.5, -7, 32, -7, 32);
        sketch.vertex(7, 32);
        sketch.bezierVertex(7, 32, 2, -23.5, 41, -32);
      case .straight:
        sketch.vertex(-35, -32);
        sketch.bezierVertex(-11, -33.5, -6.5, -16, -9, 32);
        sketch.vertex(9, 32);
        sketch.bezierVertex(6.5, -16, 11, -33.5, 35, -32);
      case .rounded:
        sketch.vertex(-35, -32);
        sketch.bezierVertex(-15, -45.5, 9.57, -13.5, -19, 32);
        sketch.vertex(19, 32);
        sketch.bezierVertex(-9.57, -13.5, 15, -45.5, 35, -32);
      case .wide:
        sketch.vertex(-10, -2);
        sketch.vertex(-19, 32);
        sketch.vertex(19, 32);
        sketch.vertex(10, -2);
      case .winking:
        sketch.vertex(-9, 32);
        sketch.vertex(9, 32);
        sketch.bezierVertex(7, -7, 16.37, -17, 34.87, -17);
        sketch.vertex(48.87, -17);
        break;
    }

    sketch.endShape();

    sketch.pop();
  }

  void buildCheek(P5 sketch, FaceDiskCheekStyle cheekStyle, double variance, num x, num y) {
    sketch.push();
    sketch.translate(x, y);

    sketch.setStroke(style, .thinner);

    switch (cheekStyle.value) {
      case 1:
        break;
      case 2:
        sketch.circle(0, 0, 8);
        sketch.circle(0, 0, 19);
      default:
        sketch.beginShape();

        for (int i = 0; i < cheekStyle.value; i++) {
          final angle = (math.pi * 2 / cheekStyle.value) * i + variance;
          final p = sketch.createVector(math.cos(angle) * 11, math.sin(angle) * 11);
          sketch.vertex(p.x, p.y);
        }

        sketch.endShape(sketch.CLOSE);

        sketch.beginShape();

        for (int i = 0; i < cheekStyle.value; i++) {
          final angle = (math.pi * 2 / cheekStyle.value) * i + variance;
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

    if (config.petalStyle == .round) {
      sketch.strokeOn(style, .thick);
      sketch.strokeJoin(sketch.ROUND);
    } else if (config.petalStyle == .narrowSpikes) {
      sketch.strokeOff(style);
    } else {
      sketch.strokeOn(style, .thick);

      if (config.petalStyle == .spikes && config.petalCount >= 8) {
        sketch.strokeJoin(sketch.ROUND);
      } else {
        sketch.strokeJoin(sketch.MITER);
      }
    }

    buildPetalsShape(sketch);
  }

  void buildPetalsShape(P5 sketch) {
    sketch.beginShape();
    for (int i = 0; i < config.petalCount; i++) {
      final angleDelta =
          math.pi * 2 / config.petalCount / (config.petalStyle == .narrowSpikes ? 3 : 2);
      final angle = (math.pi * 2 / config.petalCount) * i + config.petalAngle;

      switch (config.petalStyle) {
        case .spikes:
        case .narrowSpikes:
          final topAnglePoint = Offset(math.cos(angle), math.sin(angle)) * config.petalOuterRadius;
          final rightAnglePoint =
              Offset(math.cos(angle + angleDelta), math.sin(angle + angleDelta)) *
              config.starInnerRadius;
          final leftAnglePoint =
              Offset(math.cos(angle - angleDelta), math.sin(angle - angleDelta)) *
              config.starInnerRadius;

          sketch.vertex(leftAnglePoint.dx, leftAnglePoint.dy);
          sketch.vertex(topAnglePoint.dx, topAnglePoint.dy);
          sketch.vertex(rightAnglePoint.dx, rightAnglePoint.dy);
        case .round:
        case .sharp:
          // case .circular:
          for (int j = 0; j < petalResolution; j++) {
            final p = petalBuilder(
              sketch,
              ((angleDelta * 2) / petalResolution) * j,
              switch (config.petalStyle) {
                .sharp => sharpPetals,
                .round => config.petalCount > 6 ? roundPetals : circlePetals,
                // .circular => circlePetals,
                _ => throw UnimplementedError(),
              },
              config.petalCount,
              angle - angleDelta / 2,
              config.petalOuterRadius,
              config.starInnerRadius,
            );
            sketch.vertex(p.dx, p.dy);
          }
      }
    }

    sketch.endShape(sketch.CLOSE);
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
        // case .circular:
        final res = petalResolution * config.petalCount;
        for (int i = 0; i < res; i++) {
          final p = petalBuilder(
            sketch,
            (math.pi * 2 / res) * i,
            switch (config.petalStyle) {
              .sharp => sharpPetals,
              .round => circlePetals,
              // .circular => circlePetals,
              _ => throw UnimplementedError(),
            },
            config.petalCount,
            config.petalAngle - math.pi * 2 / config.petalCount / 4,
            config.size,
            config.diskConfig.radius + config.petalDiskDistance + config.doubleOutlineSpacing / 2,
          );
          sketch.vertex(p.dx, p.dy);
        }
        break;
    }
    sketch.endShape(sketch.CLOSE);
  }

  void buildSepal(P5 sketch) {
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
    } else if (config.sepalStyle == .dots) {
      sketch.setStroke(style, config.doubleOutline ? .thinner : .thin);
      sketch.strokeJoin(sketch.MITER);
      // sketch.setFill(style);
    }

    buildSepalShape(sketch);

    if (config.sepalStyle == .mandala && config.petalStyle != .narrowSpikes) {
      sketch.push();

      sketch.beginClip();
      buildSepalShape(sketch);
      sketch.endClip();

      sketch.setStroke(style, .thinner);
      final resolution = 12 * config.petalCount;
      for (int i = 0; i < resolution; i++) {
        final innerRadius = config.doubleOutline
            ? config.diskConfig.radius + config.petalDiskDistance + config.doubleOutlineSpacing
            : config.starInnerRadius;
        final outerRadius = config.doubleOutline ? config.size : config.petalOuterRadius;
        final rangeMin = (outerRadius - innerRadius) / 2;
        var p = Offset.fromDirection(
          config.petalAngle + math.pi * 2 / resolution * i,
          rangeMin * config.sepalDistanceOffset + innerRadius + rangeMin,
        );
        sketch.line(p.dx, p.dy, 0, 0);
      }

      sketch.pop();
    }

    sketch.pop();
  }

  void buildSepalShape(P5 sketch) {
    final innerRadius = config.doubleOutline
        ? config.diskConfig.radius + config.petalDiskDistance + config.doubleOutlineSpacing
        : config.starInnerRadius;
    final outerRadius = config.doubleOutline ? config.size : config.petalOuterRadius;

    if (config.sepalStyle == .mandala) {
      sketch.beginShape();
    }

    for (int i = 0; i < config.petalCount; i++) {
      final angleDelta = math.pi * 2 / config.petalCount / 2;
      final angle = (math.pi * 2 / config.petalCount) * i + config.petalAngle;
      var topAnglePoint = Offset.fromDirection(angle);
      var leftAnglePoint = Offset.fromDirection(angle - angleDelta);

      final rangeMin = (outerRadius - innerRadius) / 2;
      switch (config.sepalStyle) {
        case .none:
          break;
        case .dots:
          leftAnglePoint *= rangeMin * config.sepalDistanceOffset + innerRadius + rangeMin;

          // sketch.setStroke(style);s
          // sketch.strokeWeight(config.sepalDotsSize * 2 + style.strokeWidth);
          // sketch.point(leftAnglePoint.x, leftAnglePoint.y);
          sketch.circle(leftAnglePoint.dx, leftAnglePoint.dy, config.sepalDotsSize);
          sketch.circle(leftAnglePoint.dx, leftAnglePoint.dy, config.sepalDotsSize / 3);
          // sketch.point(leftAnglePoint.x, leftAnglePoint.y);
          break;
        case .mandala:
          switch (config.petalStyle) {
            case .spikes:
            case .narrowSpikes:
              topAnglePoint *= innerRadius;
              leftAnglePoint *= rangeMin * config.sepalDistanceOffset + innerRadius + rangeMin;

              sketch.vertex(leftAnglePoint.dx, leftAnglePoint.dy);
              sketch.vertex(topAnglePoint.dx, topAnglePoint.dy);

              // sketch.push();
              // sketch.setStroke(style, .thinner);
              // for (int i = 0; i < 12; i++) {
              //   print(math.asin(math.sin(i / 12 * math.pi)) / (math.pi / 2));
              //   var p = Offset.fromDirection(
              //     angle - angleDelta * 2 + angleDelta * 2 / 12 * i,
              //     // rangeMin * config.sepalDistanceOffset + innerRadius + rangeMin,
              //     lerpDouble(
              //       innerRadius,
              //       rangeMin * config.sepalDistanceOffset + innerRadius + rangeMin,
              //       math.asin(math.sin(i / 12 * math.pi)) / (math.pi / 2),
              //     )!,
              //   );
              //   sketch.line(p.dx, p.dy, 0, 0);
              // }
              // sketch.pop();
              break;
            case .round:
            case .sharp:
              // case .circular:
              for (int j = 0; j < petalResolution; j++) {
                final p = petalBuilder(
                  sketch,
                  ((angleDelta * 2) / petalResolution) * j,
                  switch (config.petalStyle) {
                    .sharp => sharpPetals,
                    .round => circlePetals,
                    // .circular => circlePetals,
                    _ => throw UnimplementedError(),
                  },
                  config.petalCount,
                  angle + angleDelta / 2,
                  rangeMin * config.sepalDistanceOffset + innerRadius + rangeMin,
                  innerRadius,
                );
                // sketch.push();
                // sketch.setStroke(style, .thinner);
                // if (j % 3 == 0) sketch.line(p.dx, p.dy, 0, 0);
                // sketch.pop();
                sketch.vertex(p.dx, p.dy);
              }
          }
          break;
      }
    }

    if (config.sepalStyle == .mandala) {
      sketch.endShape(sketch.CLOSE);
    }
  }

  void buildHalo(P5 sketch) {
    sketch.push();

    sketch.setStroke(style, .thin);
    sketch.strokeJoin(
      config.haloStyle == .petal || config.haloStyle == .contraPetal ? sketch.ROUND : sketch.MITER,
    );

    if (config.haloStyle == .contraPetal) {
      sketch.beginClip();
      sketch.circle(0, 0, 275 + (style.strokeClasses[StrokeClass.thin]! / 2));
      sketch.endClip();
    }

    buildHaloShape(sketch);

    sketch.pop();
  }

  void buildHaloShape(P5 sketch) {
    if (config.haloStyle == .hatching) {
      sketch.beginShape(1);
    } else {
      sketch.beginShape();
    }

    switch (config.haloStyle) {
      case .ring:
        // sketch.circle(0, 0, 275);
        for (int i = 0; i < 240; i++) {
          final p1 = Offset.fromDirection(config.haloRotation + math.pi * 2 / 240 * i, 275);
          final p2 = Offset.fromDirection(
            config.haloRotation + math.pi * 2 / 480 + math.pi * 2 / 240 * i,
            270,
          );
          sketch.point(p1.dx, p1.dy);
          sketch.point(p2.dx, p2.dy);
        }
      // case .polygon:
      //   for (int i = 0; i < config.haloElementCount; i++) {
      //     final angle = math.pi * 2 / config.haloElementCount * i + config.haloRotation;
      //     final p = Offset(math.cos(angle), math.sin(angle)) * 275;
      //     sketch.vertex(p.dx, p.dy);
      //   }
      case .gear:
        for (int i = 0; i < config.haloElementCount; i++) {
          final step = math.pi * 2 / config.haloElementCount / 4;
          final angle = (math.pi * 2 / config.haloElementCount * i) + config.haloRotation;
          final p1 = Offset(math.cos(angle), math.sin(angle)) * 240;
          final p2 = Offset(math.cos(angle), math.sin(angle)) * 275;
          final p3 = Offset(math.cos(angle + step * 2), math.sin(angle + step * 2)) * 275;
          final p4 = Offset(math.cos(angle + step * 2), math.sin(angle + step * 2)) * 240;
          sketch.vertex(p1.dx, p1.dy);
          sketch.vertex(p2.dx, p2.dy);

          for (int j = 0; j < petalResolution; j++) {
            final angleStep = step * 2 / petalResolution * j;
            final pO = Offset(math.cos(angle + angleStep), math.sin(angle + angleStep)) * 275;
            sketch.vertex(pO.dx, pO.dy);
          }

          sketch.vertex(p3.dx, p3.dy);
          sketch.vertex(p4.dx, p4.dy);

          for (int j = 0; j < petalResolution; j++) {
            final angleStep = step * 2 / petalResolution * j;
            final pI =
                Offset(
                  math.cos(angle + step * 2 + angleStep),
                  math.sin(angle + step * 2 + angleStep),
                ) *
                240;
            sketch.vertex(pI.dx, pI.dy);
          }
        }
      case .petal:
        final res = 64 * config.haloElementCount;
        for (int i = 0; i < res; i++) {
          final p = petalBuilder(
            sketch,
            (math.pi * 2 / res) * i,
            circlePetals,
            config.haloElementCount,
            config.haloRotation,
            275,
            240,
          );
          sketch.vertex(p.dx, p.dy);
        }
      case .contraPetal:
        sketch.circle(0, 0, 275);

        final res = 64 * config.haloElementCount;
        for (int i = 0; i < res; i++) {
          final p = petalBuilder(
            sketch,
            (math.pi * 2 / res) * i,
            circlePetals,
            config.haloElementCount,
            config.haloRotation,
            240,
            275,
          );
          sketch.vertex(p.dx, p.dy);
        }
      case .hatching:
        // sketch.circle(0, 0, 275);

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
            sketch.vertex(pointA.dx, pointA.dy);
            sketch.vertex(pointB.dx, pointB.dy);
          }
        }
    }

    sketch.endShape(sketch.CLOSE);
  }
}

Offset petalBuilder(
  P5 sketch,
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
