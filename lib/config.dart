import 'dart:math';
import 'dart:ui';

import 'package:tavolara/bindings.dart';

enum StrokeClass { thinner, thin, thick, thicker, thickest }

class Style {
  final P5Color backgroundColor;
  final P5Color color;
  final Map<StrokeClass, double> strokeClasses;

  const Style({required this.backgroundColor, required this.color, required this.strokeClasses});
}

enum PetalStyle { spikes, narrowSpikes, round, sharp /* circular */ }

enum SepalStyle { none, dots, mandala }

enum HaloStyle { ring, gear, petal, contraPetal, hatching }

class Configuration {
  final double size;

  final DiskConfiguration diskConfig;

  final PetalStyle petalStyle;
  final int petalCount;
  final double petalOuterRadius;
  final double petalDiskDistance;
  final double petalAngle;
  final bool generatePetalRing;
  final bool doubleOutline;
  final double doubleOutlineSpacing;

  final SepalStyle sepalStyle;
  final double sepalDistanceOffset;
  final double sepalDotsSize;

  final HaloStyle haloStyle;
  final int haloElementCount;
  final double haloRotation;

  const Configuration({
    required this.size,

    required this.diskConfig,

    required this.petalStyle,
    required this.petalCount,
    required this.petalOuterRadius,
    required this.petalDiskDistance,
    required this.petalAngle,
    required this.generatePetalRing,
    required this.doubleOutline,
    required this.doubleOutlineSpacing,

    required this.sepalStyle,
    required this.sepalDistanceOffset,
    required this.sepalDotsSize,

    required this.haloStyle,
    required this.haloElementCount,
    required this.haloRotation,
  });

  factory Configuration.fromRandom({
    required Random random,
    required double size,
    ConfigurationOverride? override,
  }) {
    final coreStyle = random.nextInt(3);
    final diskConfig = switch (coreStyle) {
      0 => ConcentricDiskConfiguration.fromRandom(random, override),
      1 => SimpleDiskConfiguration.fromRandom(random, override),
      2 => FaceDiskConfiguration.fromRandom(random, override),
      _ => throw UnimplementedError(),
    };

    final petalStyle = withOverride(
      PetalStyle.values[random.nextInt(PetalStyle.values.length)],
      override?.petalStyle,
    );
    final doubleOutline = false; //withOverride(random.nextDouble() > 0.7, override?.doubleOutline);
    final doubleOutlineSpacing = 0.0;
    // withOverride(random.nextDoubleRange(50, 80), override?.doubleOutlineSpacing);
    final generateStarRing = withOverride(
      petalStyle == .narrowSpikes || random.nextDouble() > 0.8,
      override?.generateStarRing,
    );
    final sepalStyle = withOverride(
      SepalStyle.values[random.nextInt(SepalStyle.values.length)],
      override?.sepalStyle,
    );
    final ringDotsVariance = withOverride(random.nextDouble(), override?.sepalDistanceOffset);
    final ringDotsSize = withOverride(random.nextDoubleRange(8, 16), override?.sepalDotsSize);

    final starPoints = withOverride(random.nextIntRange(8, 13), override?.petalCount);
    final starOuterRadius = withOverride(
      /* doubleOutline ? size - doubleOutlineSpacing : */ size,
      override?.petalOuterRadius,
    );
    final starSpacing = withOverride(
      petalStyle != .narrowSpikes && (diskConfig.radius < 40 || random.nextDouble() > 0.5)
          ? random.nextDoubleRange(20, starOuterRadius - diskConfig.radius - 60)
          : 0.0,
      override?.petalDiskDistance,
    );
    final starAngle = withOverride(
      random.nextDoubleRange(0, (pi * 2) / starPoints),
      override?.petalAngle,
    );

    final haloStyle = withOverride(
      HaloStyle.values[random.nextInt(HaloStyle.values.length)],
      override?.haloStyle,
    );
    final haloElementCount = withOverride(random.nextIntRange(10, 32), override?.haloElementCount);
    final haloRotation = withOverride(
      random.nextDoubleRange(0, pi * 2 / haloElementCount),
      override?.haloRotation,
    );

    return Configuration(
      size: size,
      diskConfig: diskConfig,
      petalStyle: petalStyle,
      doubleOutline: doubleOutline,
      doubleOutlineSpacing: doubleOutlineSpacing,
      generatePetalRing: generateStarRing,
      petalCount: starPoints,
      petalOuterRadius: starOuterRadius,
      petalDiskDistance: starSpacing,
      petalAngle: starAngle,
      sepalStyle: sepalStyle,
      sepalDistanceOffset: ringDotsVariance,
      sepalDotsSize: ringDotsSize,
      haloStyle: haloStyle,
      haloElementCount: haloElementCount,
      haloRotation: haloRotation,
    );
  }

  Map<String, Object> describe() {
    return {
      'size': size,
      'diskConfig': diskConfig,
      'petalStyle': petalStyle,
      'starPoints': petalCount,
      'starOuterRadius': petalOuterRadius,
      'starSpacing': petalDiskDistance,
      'starAngle': petalAngle,
      'doubleOutline': doubleOutline,
      'doubleOutlineSpacing': doubleOutlineSpacing,
      'generateStarRing': generatePetalRing,
      'sepalStyle': sepalStyle,
      'sepalDistanceOffset': sepalDistanceOffset,
      'sepalDotsSize': sepalDotsSize,
      'haloStyle': haloStyle,
      'haloElementCount': haloElementCount,
      'haloRotation': haloRotation,
    };
  }

  double get starInnerRadius => diskConfig.radius + petalDiskDistance;
}

enum OverrideMode { none, override, patch }

sealed class OverridePropertyOptions<T extends Object> {
  const OverridePropertyOptions();
}

class RangedDoubleOverridePropertyOptions extends OverridePropertyOptions<double> {
  final double min;
  final double max;

  const RangedDoubleOverridePropertyOptions({required this.min, required this.max});
}

class RangedIntOverridePropertyOptions extends OverridePropertyOptions<int> {
  final int min;
  final int max;

  const RangedIntOverridePropertyOptions({required this.min, required this.max});
}

class ChoiceOverridePropertyOptions<T extends Enum> extends OverridePropertyOptions<T> {
  final List<({T option, String title})> options;

  const ChoiceOverridePropertyOptions({required this.options});
}

class FlagOverridePropertyOptions extends OverridePropertyOptions<bool> {
  const FlagOverridePropertyOptions();
}

class OverrideProperty<T extends Object> {
  final OverridePropertyOptions<T> options;
  OverrideMode mode;
  T value;

  OverrideProperty({required this.options, this.mode = .none, required this.value});
}

class ConfigurationOverride {
  // final OverrideProperty<CoreConfiguration> coreConfig;
  final OverrideProperty<double> outerRadius;
  final OverrideProperty<PetalStyle> petalStyle;
  final OverrideProperty<bool> doubleOutline;
  final OverrideProperty<double> doubleOutlineSpacing;
  final OverrideProperty<bool> generateStarRing;
  final OverrideProperty<int> petalCount;
  final OverrideProperty<double> petalOuterRadius;
  final OverrideProperty<double> petalDiskDistance;
  final OverrideProperty<double> petalAngle;

  final OverrideProperty<SepalStyle> sepalStyle;
  final OverrideProperty<double> sepalDistanceOffset;
  final OverrideProperty<double> sepalDotsSize;

  final OverrideProperty<HaloStyle> haloStyle;
  final OverrideProperty<int> haloElementCount;
  final OverrideProperty<double> haloRotation;

  ConfigurationOverride({
    // OverrideProperty<CoreConfiguration>? coreConfig,
    OverrideProperty<double>? outerRadius,
    OverrideProperty<PetalStyle>? petalStyle,
    OverrideProperty<bool>? doubleOutline,
    OverrideProperty<double>? doubleOutlineSpacing,
    OverrideProperty<bool>? generateStarRing,
    OverrideProperty<int>? starPoints,
    OverrideProperty<double>? starOuterRadius,
    OverrideProperty<double>? starSpacing,
    OverrideProperty<double>? starAngle,
    OverrideProperty<SepalStyle>? sepalStyle,
    OverrideProperty<double>? sepalDistanceOffset,
    OverrideProperty<double>? sepalDotsSize,
    OverrideProperty<HaloStyle>? haloStyle,
    OverrideProperty<int>? haloElementCount,
    OverrideProperty<double>? haloRotation,
  }) : outerRadius =
           outerRadius ??
           .new(options: RangedDoubleOverridePropertyOptions(min: 0, max: 200), value: 0),
       petalStyle =
           petalStyle ??
           .new(
             options: ChoiceOverridePropertyOptions(
               options: [
                 (option: .spikes, title: "Spikes"),
                 (option: .narrowSpikes, title: "Narrow spikes"),
                 (option: .sharp, title: "Petals (sharp)"),
                 (option: .round, title: "Petals (round)"),
                 //  (option: .circular, title: "Petals (circular)"),
               ],
             ),
             value: .spikes,
           ),
       doubleOutline = doubleOutline ?? .new(options: FlagOverridePropertyOptions(), value: false),
       doubleOutlineSpacing =
           doubleOutlineSpacing ??
           .new(options: RangedDoubleOverridePropertyOptions(min: 0, max: 200), value: 0),
       generateStarRing =
           generateStarRing ?? .new(options: FlagOverridePropertyOptions(), value: false),
       petalCount =
           starPoints ?? .new(options: RangedIntOverridePropertyOptions(min: 3, max: 16), value: 3),
       petalOuterRadius =
           starOuterRadius ??
           .new(options: RangedDoubleOverridePropertyOptions(min: 0, max: 200), value: 0),
       petalDiskDistance =
           starSpacing ??
           .new(options: RangedDoubleOverridePropertyOptions(min: 0, max: 200), value: 0),
       petalAngle =
           starAngle ??
           .new(options: RangedDoubleOverridePropertyOptions(min: 0, max: pi * 2), value: 0),
       sepalStyle =
           sepalStyle ??
           .new(
             options: ChoiceOverridePropertyOptions(
               options: [
                 (option: .none, title: "None"),
                 (option: .dots, title: "Dots"),
                 (option: .mandala, title: "Mandala"),
               ],
             ),
             value: .none,
           ),
       sepalDistanceOffset =
           sepalDistanceOffset ??
           .new(options: RangedDoubleOverridePropertyOptions(min: 0, max: 1), value: 0),
       sepalDotsSize =
           sepalDotsSize ??
           .new(options: RangedDoubleOverridePropertyOptions(min: 0, max: 50), value: 0),
       haloStyle =
           haloStyle ??
           .new(
             options: ChoiceOverridePropertyOptions(
               options: [
                 (option: .ring, title: "Ring"),
                 (option: .petal, title: "Petal"),
                 (option: .contraPetal, title: "Contrapetal"),
                 (option: .gear, title: "Gear"),
                 (option: .hatching, title: "Hatching"),
               ],
             ),
             value: .ring,
           ),
       haloElementCount =
           haloElementCount ??
           .new(options: RangedIntOverridePropertyOptions(min: 4, max: 32), value: 4),
       haloRotation =
           haloRotation ??
           .new(options: RangedDoubleOverridePropertyOptions(min: 0, max: pi * 2), value: 0);

  Configuration patch(Configuration other) {
    return Configuration(
      size: /* size.mode == .patch ? size.value :  */ other.size,
      diskConfig: /* coreConfig.mode == .patch ? coreConfig.value :  */ other.diskConfig,
      petalStyle: petalStyle.mode == .patch ? petalStyle.value : other.petalStyle,
      doubleOutline: doubleOutline.mode == .patch ? doubleOutline.value : other.doubleOutline,
      doubleOutlineSpacing: doubleOutlineSpacing.mode == .patch
          ? doubleOutlineSpacing.value
          : other.doubleOutlineSpacing,
      generatePetalRing: generateStarRing.mode == .patch
          ? generateStarRing.value
          : other.generatePetalRing,
      petalCount: petalCount.mode == .patch ? petalCount.value : other.petalCount,
      petalOuterRadius: petalOuterRadius.mode == .patch
          ? petalOuterRadius.value
          : other.petalOuterRadius,
      petalDiskDistance: petalDiskDistance.mode == .patch
          ? petalDiskDistance.value
          : other.petalDiskDistance,
      petalAngle: petalAngle.mode == .patch ? petalAngle.value : other.petalAngle,
      sepalStyle: sepalStyle.mode == .patch ? sepalStyle.value : other.sepalStyle,
      sepalDistanceOffset: sepalDistanceOffset.mode == .patch
          ? sepalDistanceOffset.value
          : other.sepalDistanceOffset,
      sepalDotsSize: sepalDotsSize.mode == .patch ? sepalDotsSize.value : other.sepalDotsSize,
      haloStyle: haloStyle.mode == .patch ? haloStyle.value : other.haloStyle,
      haloElementCount: haloElementCount.mode == .patch
          ? haloElementCount.value
          : other.haloElementCount,
      haloRotation: haloRotation.mode == .patch ? haloRotation.value : other.haloRotation,
    );
  }

  OverrideProperty? byName(String name) {
    return switch (name) {
      'diskConfig' => null,
      'petalStyle' => petalStyle,
      'starPoints' => petalCount,
      'starOuterRadius' => petalOuterRadius,
      'starSpacing' => petalDiskDistance,
      'starAngle' => petalAngle,
      'doubleOutline' => doubleOutline,
      'doubleOutlineSpacing' => doubleOutlineSpacing,
      'generateStarRing' => generateStarRing,
      'sepalStyle' => sepalStyle,
      'sepalDistanceOffset' => sepalDistanceOffset,
      'sepalDotsSize' => sepalDotsSize,
      _ => null,
    };
  }
}

sealed class DiskConfiguration {
  final double radius;

  const DiskConfiguration({required this.radius});
}

enum ConcentricDecorationStyle { none, lines, dots }

class ConcentricDiskConfiguration extends DiskConfiguration {
  final double innerRadius;
  final ConcentricDecorationStyle decoration;
  final int elementAmount;
  final double rotation;

  const ConcentricDiskConfiguration({
    required super.radius,
    required this.innerRadius,
    required this.decoration,
    required this.elementAmount,
    required this.rotation,
  });

  factory ConcentricDiskConfiguration.fromRandom(Random random, [ConfigurationOverride? override]) {
    final outerRadius = withOverride(random.nextDoubleRange(30, 80), override?.outerRadius);
    final innerRadius = random.nextDoubleRange(5, outerRadius - 15);
    final intraSpace = outerRadius - innerRadius;
    final decoration =
        ConcentricDecorationStyle.values[intraSpace > 15
            ? random.nextInt(ConcentricDecorationStyle.values.length)
            : random.nextInt(ConcentricDecorationStyle.values.length - 1)];
    final elementAmount =
        (random.nextDoubleRange(0, (intraSpace / 50) * 5) + 4).floor() +
        ((intraSpace / 50) * 4).floor() +
        5;
    final rotation = random.nextDoubleRange(0, pi / 2 / elementAmount);

    return ConcentricDiskConfiguration(
      radius: outerRadius,
      innerRadius: innerRadius,
      decoration: decoration,
      elementAmount: elementAmount,
      rotation: rotation,
    );
  }
}

class SimpleDiskConfiguration extends DiskConfiguration {
  const SimpleDiskConfiguration({required super.radius});

  factory SimpleDiskConfiguration.fromRandom(Random random, [ConfigurationOverride? override]) {
    return SimpleDiskConfiguration(
      radius: withOverride(random.nextDoubleRange(30, 50), override?.outerRadius),
    );
  }
}

enum FaceDiskEyeStyle { almond, concentric, dot }

enum FaceDiskMouthStyle { elliptical, rectangular, line, concentric, smiling }

enum FaceDiskNoseStyle { eagled, straight, rounded, wide, winking }

class FaceDiskCheekStyle {
  final int value;

  const FaceDiskCheekStyle._(this.value);

  static const FaceDiskCheekStyle none = FaceDiskCheekStyle._(1);
  static const FaceDiskCheekStyle circular = FaceDiskCheekStyle._(2);

  factory FaceDiskCheekStyle.polygonal(int faces) => FaceDiskCheekStyle._(faces);
}

class FaceDiskConfiguration extends DiskConfiguration {
  final FaceDiskEyeStyle eyeStyle;
  final FaceDiskMouthStyle mouthStyle;
  final FaceDiskNoseStyle noseStyle;
  final FaceDiskCheekStyle cheekStyle;
  final Offset cheekVariance;
  final Offset eyeVariance;

  const FaceDiskConfiguration({
    required super.radius,
    required this.eyeStyle,
    required this.mouthStyle,
    required this.noseStyle,
    required this.cheekStyle,
    required this.cheekVariance,
    required this.eyeVariance,
  });

  factory FaceDiskConfiguration.fromRandom(Random random, [ConfigurationOverride? override]) {
    final outerRadius = withOverride(random.nextDoubleRange(80, 90), override?.outerRadius);
    final eyeStyle = FaceDiskEyeStyle.values[random.nextInt(FaceDiskEyeStyle.values.length)];
    final mouthStyle = FaceDiskMouthStyle.values[random.nextInt(FaceDiskMouthStyle.values.length)];
    final noseStyle = FaceDiskNoseStyle.values[random.nextInt(FaceDiskNoseStyle.values.length)];
    final cheekStyle = FaceDiskCheekStyle._(random.nextIntRange(1, 8));
    final cheekVariance = Offset(
      random.nextDoubleRange(0, pi * 2 / cheekStyle.value),
      random.nextDoubleRange(0, pi * 2 / cheekStyle.value),
    );

    final eyeVariance = Offset(random.nextDoubleRange(-6, 12), random.nextDoubleRange(-6, 6));

    return FaceDiskConfiguration(
      radius: outerRadius,
      eyeStyle: eyeStyle,
      mouthStyle: mouthStyle,
      noseStyle: noseStyle,
      cheekStyle: cheekStyle,
      cheekVariance: cheekVariance,
      eyeVariance: eyeVariance,
    );
  }
}

extension on Random {
  int nextIntRange(int min, int max) {
    return nextInt(max - min) + min;
  }

  double nextDoubleRange(num min, num max) {
    return nextDouble() * (max - min) + min;
  }
}

extension StyledSketch on P5 {
  void fillOn(Style style) {
    fill(style.color);
  }

  void fillOff(Style style) {
    noFill();
  }

  void strokeOn(Style style, StrokeClass strokeCls) {
    strokeWeight(style.strokeClasses[strokeCls]!);
    stroke(style.color);
  }

  void strokeOff(Style style) {
    noStroke();
  }

  void setFill(Style style) {
    fillOn(style);
    strokeOff(style);
  }

  void setStroke(Style style, StrokeClass strokeCls) {
    fillOff(style);
    strokeOn(style, strokeCls);
  }
}

T withOverride<T extends Object>(T value, OverrideProperty<T>? override) {
  if (override == null) return value;

  return override.mode == .override ? override.value : value;
}
