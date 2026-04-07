import 'dart:math';

import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tavolara/config.dart';
import 'package:tavolara/mark.dart';
import 'package:web/web.dart' as web;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.geistTextTheme(Typography.whiteMountainView),
        colorScheme: ColorScheme(
          brightness: .dark,
          primary: Colors.white,
          onPrimary: Colors.black,
          secondary: Colors.white,
          onSecondary: Colors.black,
          error: Colors.red,
          onError: Colors.white,
          surface: Colors.black,
          onSurface: Colors.white,
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: SegmentedButton.styleFrom(
            shape: RoundedRectangleBorder(),
            side: .new(color: Colors.white, width: 2),
            padding: .zero,
          ),
        ),
        drawerTheme: DrawerThemeData(shape: RoundedRectangleBorder()),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(),
        ),
        inputDecorationTheme: InputDecorationThemeData(
          border: OutlineInputBorder(borderRadius: .zero, borderSide: .new(width: 2)),
          outlineBorder: .new(width: 2),
        ),
        radioTheme: RadioThemeData(innerRadius: WidgetStatePropertyAll(7.1)),
        scrollbarTheme: ScrollbarThemeData(
          radius: .zero,
          crossAxisMargin: 0,
          mainAxisMargin: 0,
          thickness: WidgetStatePropertyAll(8),
          thumbColor: WidgetStatePropertyAll(Colors.white),
          thumbVisibility: WidgetStatePropertyAll(true),
          trackBorderColor: WidgetStatePropertyAll(Colors.white),
          trackVisibility: WidgetStatePropertyAll(true),
        ),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum SizeVariant {
  tiny(30),
  small(120),
  medium(300),
  full(600);

  final double size;

  const SizeVariant(this.size);
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  SizeVariant sizeVariant = .full;
  final seedController = TextEditingController();
  var backgroundColor = Colors.black;
  var foregroundColor = Colors.white;

  late TavolaraSketch sketch;
  final configOverride = ConfigurationOverride();

  bool showConfigPane = false;
  late final configPaneController = AnimationController(
    vsync: this,
    duration: .new(milliseconds: 300),
    reverseDuration: .new(milliseconds: 300),
  );

  Style get _style => Style(
    backgroundColor: sketch.p5.colorRGB(
      (backgroundColor.r * 255).toInt(),
      (backgroundColor.g * 255).toInt(),
      (backgroundColor.b * 255).toInt(),
    ),
    color: sketch.p5.colorRGB(
      (foregroundColor.r * 255).toInt(),
      (foregroundColor.g * 255).toInt(),
      (foregroundColor.b * 255).toInt(),
    ),
    strokeClasses: {.thinner: 2, .thin: 4, .thick: 6, .thicker: 8},
  );

  Configuration get _config => configOverride.patch(
    Configuration.fromRandom(
      random: Random(seedController.text.hashCode),
      size: 200,
      override: configOverride,
    ),
  );

  void _updateStyle() {
    sketch.updateStyle(_style);
  }

  void _updateConfiguration() {
    sketch.updateConfiguration(_config);
  }

  Widget buildModeTile<T extends Object>({
    required String title,
    required OverrideProperty<T> property,
  }) {
    return Column(
      children: [
        ListTile(
          title: Text(title),
          trailing: SizedBox(
            width: 32 * 3,
            child: SegmentedButton<OverrideMode>(
              segments: [
                ButtonSegment(value: .none, icon: const Icon(Icons.close), tooltip: "No override"),
                ButtonSegment(value: .override, icon: const Icon(Icons.done), tooltip: "Override"),
                ButtonSegment(value: .patch, icon: const Icon(Icons.healing), tooltip: "Patch"),
              ],
              showSelectedIcon: false,
              selected: {property.mode},
              onSelectionChanged: (p0) {
                setState(() => property.mode = p0.single);
                _updateConfiguration();
              },
            ),
          ),
        ),
        switch (property.options) {
          RangedDoubleOverridePropertyOptions(:final min, :final max) => Slider(
            value: property.value as double,
            onChanged: property.mode != .none
                ? (v) {
                    setState(() => property.value = v as T);
                    _updateConfiguration();
                  }
                : null,
            min: min,
            max: max,
          ),
          RangedIntOverridePropertyOptions(:final min, :final max) => Slider(
            value: (property.value as int).toDouble(),
            onChanged: property.mode != .none
                ? (v) {
                    setState(() => property.value = v.toInt() as T);
                    _updateConfiguration();
                  }
                : null,
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
          ),
          ChoiceOverridePropertyOptions<Enum>(:final options) => RadioGroup<T>(
            onChanged: (v) {
              setState(() => property.value = v!);
              _updateConfiguration();
            },
            groupValue: property.value,
            child: Column(
              children: [
                for (final option in options)
                  RadioListTile<T>(
                    title: Text(option.title),
                    value: option.option as T,
                    enabled: property.mode != .none,
                  ),
              ],
            ),
          ),
          FlagOverridePropertyOptions() => SwitchListTile(
            title: Text("Enabled"),
            value: property.value as bool,
            onChanged: property.mode != .none
                ? (v) {
                    setState(() => property.value = v as T);
                    _updateConfiguration();
                  }
                : null,
          ),
        },
      ],
    );
  }

  Widget buildHeader(String title) {
    return Container(
      height: 32,
      margin: .only(top: 12, bottom: 8),
      child: Row(
        crossAxisAlignment: .center,
        children: [
          const SizedBox(width: 8, child: Divider()),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 12, fontWeight: .bold)),
          const SizedBox(width: 8),
          Expanded(child: Divider()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: Row(
        children: [
          SizeTransition(
            sizeFactor: CurvedAnimation(
              parent: configPaneController,
              curve: Easing.standardDecelerate,
              reverseCurve: Easing.emphasizedAccelerate,
            ),
            alignment: .centerEnd,
            axis: .horizontal,
            child: Drawer(
              width: 480,
              elevation: 48,
              shadowColor: Colors.black,
              child: ListView(
                padding: .fromLTRB(0, 16, 8, 16),
                children: [
                  buildHeader("Configuration"),
                  for (final entry in _config.describe().entries)
                    Padding(
                      padding: .symmetric(horizontal: 16),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '${entry.key}: '),
                            TextSpan(
                              text: '${entry.value}',
                              style: TextStyle(
                                color: switch (configOverride.byName(entry.key)?.mode) {
                                  .override => Colors.red,
                                  .patch => Colors.purple.shade400,
                                  .none || null => null,
                                },
                                fontWeight: switch (configOverride.byName(entry.key)?.mode) {
                                  .override || .patch => .bold,
                                  .none || null => null,
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  buildHeader("Disk"),
                  buildModeTile(title: "Outer radius", property: configOverride.outerRadius),
                  buildHeader("Petal"),
                  buildModeTile(title: "Petal style", property: configOverride.petalStyle),
                  buildModeTile(title: "Star points", property: configOverride.starPoints),
                  buildModeTile(
                    title: "Star outer radius",
                    property: configOverride.starOuterRadius,
                  ),
                  buildModeTile(title: "Star spacing", property: configOverride.starSpacing),
                  buildModeTile(title: "Star rotation", property: configOverride.starAngle),
                  buildModeTile(
                    title: "Generate star ring",
                    property: configOverride.generateStarRing,
                  ),
                  buildModeTile(title: "Double outline", property: configOverride.doubleOutline),
                  buildModeTile(
                    title: "Double outline spacing",
                    property: configOverride.doubleOutlineSpacing,
                  ),
                  buildHeader("Sepal"),
                  buildModeTile(title: "Sepal style", property: configOverride.sepalStyle),
                  buildModeTile(
                    title: "Sepal distance offset",
                    property: configOverride.sepalDistanceOffset,
                  ),
                  buildModeTile(title: "Sepal dots size", property: configOverride.sepalDotsSize),
                  buildHeader("Halo"),
                  buildModeTile(title: "Halo style", property: configOverride.haloStyle),
                  buildModeTile(
                    title: "Halo element count",
                    property: configOverride.haloElementCount,
                  ),
                  buildModeTile(title: "Halo rotation", property: configOverride.haloRotation),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) => OverflowBox(
                      alignment: .center,
                      fit: .deferToChild,
                      child: Center(
                        child: SizedBox(
                          width: constraints.maxWidth * 1.2,
                          height: constraints.maxHeight * 1.2,
                          child: GridPaper(color: Color(0xFF323232), divisions: 1),
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Transform.scale(
                    scale: sizeVariant.size / 600,
                    child: SizedBox.square(
                      dimension: 600,
                      child: HtmlElementView.fromTagName(
                        tagName: 'div',
                        onElementCreated: (element) {
                          final div = element as web.HTMLDivElement;

                          div
                            ..style.width = '100%'
                            ..style.height = '100%';

                          sketch = TavolaraSketch(size: 600, parent: div);
                          sketch.bootstrap(_config, _style);
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: FloatingActionButton.extended(
                    tooltip: showConfigPane ? "Hide configuration pane" : "Show configuration pane",
                    backgroundColor: showConfigPane ? Colors.white : Colors.black,
                    foregroundColor: showConfigPane ? Colors.black : Colors.white,
                    onPressed: () {
                      setState(() => showConfigPane = !showConfigPane);
                      if (showConfigPane) {
                        configPaneController.forward();
                      } else {
                        configPaneController.reverse();
                      }
                    },
                    icon: showConfigPane
                        ? const Icon(Icons.handyman)
                        : const Icon(Icons.arrow_right),
                    label: showConfigPane
                        ? const Icon(Icons.arrow_left)
                        : const Icon(Icons.handyman),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: .all(8),
                    color: Colors.black,
                    child: Row(
                      mainAxisSize: .min,
                      spacing: 16,
                      children: [
                        SizedBox.square(
                          dimension: 40,
                          child: Tooltip(
                            message: "Background color",
                            child: Material(
                              color: backgroundColor,
                              animationDuration: .new(milliseconds: 150),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(width: 2, color: Colors.white),
                              ),
                              child: InkWell(
                                hoverColor: Colors.white,
                                onTap: () async {
                                  final color = await showColorPickerDialog(
                                    context,
                                    backgroundColor,
                                    pickersEnabled: {.primary: false, .accent: false, .wheel: true},
                                    enableOpacity: false,
                                    enableShadesSelection: false,
                                    enableTonalPalette: false,
                                  );
                                  setState(() => backgroundColor = color);
                                  _updateStyle();
                                },
                              ),
                            ),
                          ),
                        ),
                        SizedBox.square(
                          dimension: 40,
                          child: Tooltip(
                            message: "Foreground color",
                            child: Material(
                              color: foregroundColor,
                              animationDuration: .new(milliseconds: 150),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(width: 2, color: Colors.white),
                              ),
                              child: InkWell(
                                hoverColor: Colors.white,
                                onTap: () async {
                                  final color = await showColorPickerDialog(
                                    context,
                                    foregroundColor,
                                    pickersEnabled: {.primary: false, .accent: false, .wheel: true},
                                    enableOpacity: false,
                                    enableShadesSelection: false,
                                    enableTonalPalette: false,
                                  );
                                  setState(() => foregroundColor = color);
                                  _updateStyle();
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Row(
                    spacing: 8,
                    mainAxisSize: .min,
                    crossAxisAlignment: .end,
                    children: [
                      _ScaleBox(
                        size: 16,
                        sizeVariant: .tiny,
                        currentVariant: sizeVariant,
                        onTap: (variant) => setState(() => sizeVariant = variant),
                      ),
                      _ScaleBox(
                        size: 24,
                        sizeVariant: .small,
                        currentVariant: sizeVariant,
                        onTap: (variant) => setState(() => sizeVariant = variant),
                      ),
                      _ScaleBox(
                        size: 40,
                        sizeVariant: .medium,
                        currentVariant: sizeVariant,
                        onTap: (variant) => setState(() => sizeVariant = variant),
                      ),
                      _ScaleBox(
                        size: 56,
                        sizeVariant: .full,
                        currentVariant: sizeVariant,
                        onTap: (variant) => setState(() => sizeVariant = variant),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      color: Colors.black,
                      padding: const .all(8),
                      constraints: BoxConstraints(maxWidth: 480),
                      child: Row(
                        spacing: 8,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: seedController,
                              decoration: InputDecoration(labelText: 'Phrase'),
                              onChanged: (value) {
                                setState(() {});
                                _updateConfiguration();
                              },
                            ),
                          ),
                          IconButton(
                            tooltip: "Generate randomly",
                            onPressed: () {
                              final random = Random();
                              final alphabet = [
                                for (int i = 65; i < 90; i++) String.fromCharCode(i),
                                for (int i = 97; i < 122; i++) String.fromCharCode(i),
                                for (int i = 48; i < 57; i++) String.fromCharCode(i),
                              ];

                              final str = [
                                for (int i = 0; i < 32; i++)
                                  alphabet[random.nextInt(alphabet.length)],
                              ].join();

                              setState(() => seedController.text = str);
                              _updateConfiguration();
                            },
                            icon: const Icon(Icons.casino),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Row(
                    mainAxisSize: .min,
                    spacing: 16,
                    children: [
                      FloatingActionButton.small(
                        tooltip: "Refresh sketch",
                        onPressed: () => sketch.p5.redraw(),
                        child: const Icon(Icons.refresh),
                      ),
                      FloatingActionButton(
                        tooltip: "Download logo (SVG)",
                        onPressed: () => sketch.save(seedController.text),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        child: const Icon(Icons.download),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScaleBox extends StatelessWidget {
  final double size;
  final SizeVariant sizeVariant;
  final SizeVariant currentVariant;
  final void Function(SizeVariant) onTap;

  const _ScaleBox({
    required this.size,
    required this.sizeVariant,
    required this.currentVariant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Tooltip(
        message: "${sizeVariant.name} (${sizeVariant.size.toInt()}x${sizeVariant.size.toInt()})",
        child: Material(
          color: currentVariant == sizeVariant ? Colors.white : Colors.black,
          animationDuration: .new(milliseconds: 150),
          shape: RoundedRectangleBorder(side: BorderSide(width: 2, color: Colors.white)),
          child: InkWell(hoverColor: Colors.white, onTap: () => onTap(sizeVariant)),
        ),
      ),
    );
  }
}
