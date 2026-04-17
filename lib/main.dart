import 'dart:math';
import 'dart:ui' as ui;

import 'package:file_saver/file_saver.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tavolara/config.dart';
import 'package:tavolara/mark.dart';
import 'package:tavolara/surface.dart';
import 'package:tavolara/survey.dart';
import 'package:tavolara/widgets.dart';

void main() async {
  usePathUrlStrategy();
  await SentryFlutter.init((options) {
    options.dsn =
        'https://5e78b7b1d64cdfa3e420724f4f42fb2f@o4511235817078784.ingest.de.sentry.io/4511235818717265';
  }, appRunner: () => runApp(SentryWidget(child: MyApp())));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveBreakpoints.builder(
      breakpoints: [
        const Breakpoint(start: 0, end: 1000, name: MOBILE),
        const Breakpoint(start: 1001, end: double.infinity, name: DESKTOP),
      ],
      child: MaterialApp.router(
        title: 'giardini generativi',
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
        routerConfig: _router,
      ),
    );
  }
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        if (state.uri.queryParameters['sur_k'] case final surveyKey?) {
          return SurveyPage(pass: surveyKey);
        }

        return GeneratorPage();
      },
    ),
    GoRoute(path: '/survey', builder: (context, state) => SurveyPage()),
  ],
);

class GeneratorPage extends StatefulWidget {
  const GeneratorPage({super.key});

  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

enum SizeVariant {
  tiny(0.1),
  small(0.2),
  medium(0.5),
  full(1);

  final double size;

  const SizeVariant(this.size);
}

class _GeneratorPageState extends State<GeneratorPage> with TickerProviderStateMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  MarkRenderer renderer = .p5;

  SizeVariant sizeVariant = .full;
  final markController = MarkController();
  final seedController = TextEditingController();
  var backgroundColor = Colors.black;
  var foregroundColor = Colors.white;

  final configOverride = ConfigurationOverride();

  bool showConfigPane = false;
  bool showStylePane = false;
  late final configPaneController = AnimationController(
    vsync: this,
    duration: .new(milliseconds: 300),
    reverseDuration: .new(milliseconds: 300),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final breakpoints = ResponsiveBreakpoints.of(context);

    if (showConfigPane && breakpoints.isMobile) {
      toggleConfigurationDrawer(true);
    } else if (!showConfigPane && breakpoints.isDesktop) {
      toggleConfigurationDrawer(false);
    }
  }

  Style get style => Style(
    backgroundColor: backgroundColor,
    color: foregroundColor,
    strokeClasses: {.thinner: 3, .thin: 4, .thick: 6, .thicker: 8, .thickest: 10},
  );

  Configuration get config => configOverride.patch(
    Configuration.fromRandom(
      random: Random(stringToSeed(seedController.text)),
      size: 200,
      override: configOverride,
    ),
  );

  void toggleConfigurationDrawer([bool? state]) {
    setState(() => showConfigPane = state ?? !showConfigPane);
    if (showConfigPane) {
      configPaneController.forward();
      scaffoldKey.currentState!.openDrawer();
    } else {
      configPaneController.reverse();
      scaffoldKey.currentState!.closeDrawer();
    }
  }

  void toggleStyleDrawer([bool? state]) {
    setState(() => showStylePane = state ?? !showStylePane);
    if (showStylePane) {
      scaffoldKey.currentState!.openEndDrawer();
    } else {
      scaffoldKey.currentState!.closeEndDrawer();
    }
  }

  Widget buildModeTile<T extends Object>({
    required String title,
    required OverrideProperty<T> property,
    required OverridePropertyOptions<T> options,
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
              },
            ),
          ),
        ),
        switch (options) {
          RangedDoubleOverridePropertyOptions(:final min, :final max) => Slider(
            value: property.value as double,
            onChanged: property.mode != .none
                ? (v) {
                    setState(() => property.value = v as T);
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
                  }
                : null,
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
          ),
          ChoiceOverridePropertyOptions<Enum>(:final options) => RadioGroup<T>(
            onChanged: (v) {
              setState(() => property.value = v!);
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

  Widget get configurationDrawer {
    return ListView(
      padding: .fromLTRB(0, 16, 8, 16),
      children: [
        buildHeader("Configuration"),
        for (final entry in config.describe().entries)
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
        buildHeader("Renderer"),
        RadioGroup<MarkRenderer>(
          onChanged: (v) {
            setState(() => renderer = v!);
          },
          groupValue: renderer,
          child: Column(
            children: [
              for (final option in MarkRenderer.values)
                RadioListTile<MarkRenderer>(title: Text(option.name), value: option),
            ],
          ),
        ),
        buildHeader("Disk"),
        buildModeTile(
          title: "Disk style",
          property: configOverride.diskStyle,
          options: ChoiceOverridePropertyOptions<DiskStyle>(
            options: [
              (option: .concentric, title: "Concentric"),
              (option: .simple, title: "Simple"),
              (option: .face, title: "Face"),
            ],
          ),
        ),
        buildModeTile(
          title: "Outer radius",
          property: configOverride.outerRadius,
          options: RangedDoubleOverridePropertyOptions(min: 0, max: 200),
        ),
        buildHeader("Petal"),
        buildModeTile(
          title: "Petal style",
          property: configOverride.petalStyle,
          options: ChoiceOverridePropertyOptions<PetalStyle>(
            options: [
              (option: .spikes, title: "Spikes"),
              (option: .narrowSpikes, title: "Narrow spikes"),
              (option: .sharp, title: "Petals (sharp)"),
            ],
          ),
        ),
        buildModeTile(
          title: "Petal count",
          property: configOverride.petalCount,
          options: RangedIntOverridePropertyOptions(min: 3, max: 16),
        ),
        buildModeTile(
          title: "Petal outer radius",
          property: configOverride.petalOuterRadius,
          options: RangedDoubleOverridePropertyOptions(min: 0, max: 200),
        ),
        buildModeTile(
          title: "Petal disk distance",
          property: configOverride.petalDiskDistance,
          options: RangedDoubleOverridePropertyOptions(min: 0, max: 200),
        ),
        buildModeTile(
          title: "Petal rotation",
          property: configOverride.petalAngle,
          options: RangedDoubleOverridePropertyOptions(min: 0, max: pi * 2),
        ),
        buildModeTile(
          title: "Generate star ring",
          property: configOverride.generateStarRing,
          options: FlagOverridePropertyOptions(),
        ),
        buildHeader("Sepal"),
        buildModeTile(
          title: "Sepal style",
          property: configOverride.sepalStyle,
          options: ChoiceOverridePropertyOptions<SepalStyle>(
            options: [
              (option: .none, title: "None"),
              (option: .dots, title: "Dots"),
              (option: .mandala, title: "Mandala"),
            ],
          ),
        ),
        buildModeTile(
          title: "Sepal distance offset",
          property: configOverride.sepalDistanceOffset,
          options: RangedDoubleOverridePropertyOptions(min: 0, max: 1),
        ),
        buildModeTile(
          title: "Sepal dots size",
          property: configOverride.sepalDotsSize,
          options: RangedDoubleOverridePropertyOptions(min: 0, max: 50),
        ),
        buildHeader("Halo"),
        buildModeTile(
          title: "Halo style",
          property: configOverride.haloStyle,
          options: ChoiceOverridePropertyOptions<HaloStyle>(
            options: [
              (option: .ring, title: "Ring"),
              (option: .contraPetal, title: "Contrapetal"),
              (option: .gear, title: "Gear"),
              (option: .hatching, title: "Hatching"),
            ],
          ),
        ),
        buildModeTile(
          title: "Halo element count",
          property: configOverride.haloElementCount,
          options: RangedIntOverridePropertyOptions(min: 4, max: 32),
        ),
        buildModeTile(
          title: "Halo rotation",
          property: configOverride.haloRotation,
          options: RangedDoubleOverridePropertyOptions(min: 0, max: pi * 2),
        ),
      ],
    );
  }

  Widget get styleDrawer {
    return ListView(
      padding: .fromLTRB(0, 16, 8, 16),
      children: [
        buildHeader("Colors"),
        ListTile(
          title: Text("Background color"),
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
          },
          trailing: SizedBox.square(
            dimension: 32,
            child: Material(
              color: backgroundColor,
              animationDuration: .new(milliseconds: 150),
              shape: RoundedRectangleBorder(side: BorderSide(width: 2, color: Colors.white)),
            ),
          ),
        ),
        ListTile(
          title: Text("Foreground color"),
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
          },
          trailing: SizedBox.square(
            dimension: 32,
            child: Material(
              color: foregroundColor,
              animationDuration: .new(milliseconds: 150),
              shape: RoundedRectangleBorder(side: BorderSide(width: 2, color: Colors.white)),
            ),
          ),
        ),
        buildHeader("Scale"),
        RadioGroup<SizeVariant>(
          onChanged: (v) {
            setState(() => sizeVariant = v!);
          },
          groupValue: sizeVariant,
          child: Column(
            children: [
              for (final option in SizeVariant.values)
                RadioListTile(
                  title: Text("${option.name} (${(option.size * 100).toInt()}%)"),
                  value: option,
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final breakpoints = ResponsiveBreakpoints.of(context);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.grey.shade900,
      appBar: breakpoints.isMobile
          ? AppBar(
              leading: IconButton(
                tooltip: showConfigPane ? "Hide configuration pane" : "Show configuration pane",
                onPressed: toggleConfigurationDrawer,
                icon: const Icon(Icons.handyman),
              ),
              title: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'giardini ',
                      style: GoogleFonts.geist(fontWeight: FontWeight.w300),
                    ),
                    TextSpan(
                      text: 'generativi',
                      style: GoogleFonts.geist(fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
                style: TextStyle(fontSize: 28, letterSpacing: -0.6),
              ),
              actions: [
                IconButton(
                  tooltip: showConfigPane ? "Hide style pane" : "Show style pane",
                  onPressed: toggleStyleDrawer,
                  icon: const Icon(Icons.palette),
                ),
              ],
              centerTitle: true,
              backgroundColor: Colors.transparent,
            )
          : null,
      drawer: breakpoints.isMobile
          ? Drawer(width: min(360, MediaQuery.widthOf(context) / 5 * 4), child: configurationDrawer)
          : null,
      endDrawer: breakpoints.isMobile
          ? Drawer(width: min(360, MediaQuery.widthOf(context) / 5 * 4), child: styleDrawer)
          : null,
      onDrawerChanged: (isOpened) => toggleConfigurationDrawer(isOpened),
      onEndDrawerChanged: (isOpened) => toggleStyleDrawer(isOpened),
      body: Row(
        children: [
          if (breakpoints.isDesktop)
            SizeTransition(
              sizeFactor: CurvedAnimation(
                parent: configPaneController,
                curve: Easing.standardDecelerate,
                reverseCurve: Easing.emphasizedAccelerate,
              ),
              axisAlignment: 1,
              axis: .horizontal,
              child: Drawer(
                width: MediaQuery.of(context).size.width / 4,
                elevation: 48,
                shadowColor: Colors.black,
                child: configurationDrawer,
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRect(
                    clipBehavior: breakpoints.isDesktop ? .hardEdge : .none,
                    child: LayoutBuilder(
                      builder: (context, constraints) => OverflowBox(
                        alignment: .center,
                        fit: .deferToChild,
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        child: SizedBox(
                          width: constraints.maxWidth * 1.5,
                          height: constraints.maxHeight * 1.5,
                          child: GridPaper(color: Color(0xFF323232), divisions: 1),
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints.loose(Size.square(600 * sizeVariant.size)),
                    child: MarkWidget(
                      configuration: config,
                      style: style,
                      renderer: renderer,
                      controller: markController,
                    ),
                  ),
                ),
                if (breakpoints.isDesktop)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    height: 56,
                    child: Center(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'giardini ',
                              style: GoogleFonts.geist(fontWeight: FontWeight.w300),
                            ),
                            TextSpan(
                              text: 'generativi',
                              style: GoogleFonts.geist(fontWeight: FontWeight.normal),
                            ),
                          ],
                        ),
                        style: TextStyle(fontSize: 32, letterSpacing: -0.6),
                      ),
                    ),
                  ),
                if (breakpoints.isDesktop)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: FloatingActionButton.extended(
                      tooltip: showConfigPane
                          ? "Hide configuration pane"
                          : "Show configuration pane",
                      backgroundColor: showConfigPane ? Colors.white : Colors.black,
                      foregroundColor: showConfigPane ? Colors.black : Colors.white,
                      onPressed: toggleConfigurationDrawer,
                      icon: showConfigPane
                          ? const Icon(Icons.handyman)
                          : const Icon(Icons.arrow_right),
                      label: showConfigPane
                          ? const Icon(Icons.arrow_left)
                          : const Icon(Icons.handyman),
                    ),
                  ),
                if (breakpoints.isDesktop)
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
                                      pickersEnabled: {
                                        .primary: false,
                                        .accent: false,
                                        .wheel: true,
                                      },
                                      enableOpacity: false,
                                      enableShadesSelection: false,
                                      enableTonalPalette: false,
                                    );
                                    setState(() => backgroundColor = color);
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
                                      pickersEnabled: {
                                        .primary: false,
                                        .accent: false,
                                        .wheel: true,
                                      },
                                      enableOpacity: false,
                                      enableShadesSelection: false,
                                      enableTonalPalette: false,
                                    );
                                    setState(() => foregroundColor = color);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (breakpoints.isDesktop)
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
                if (breakpoints.isDesktop)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        color: Colors.black,
                        padding: const .all(8),
                        constraints: BoxConstraints(maxWidth: 480),
                        child: seedBar,
                      ),
                    ),
                  ),
                if (breakpoints.isDesktop) Positioned(bottom: 16, right: 16, child: actionButtons),
              ],
            ),
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      floatingActionButton: breakpoints.isMobile ? actionButtons : null,
      bottomNavigationBar: breakpoints.isMobile
          ? Container(color: Colors.black, padding: const .all(8), child: seedBar)
          : null,
    );
  }

  Widget get seedBar {
    return Row(
      spacing: 8,
      children: [
        Expanded(
          child: TextField(
            controller: seedController,
            decoration: InputDecoration(labelText: 'Phrase'),
            onChanged: (value) {
              setState(() {});
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
              for (int i = 0; i < 32; i++) alphabet[random.nextInt(alphabet.length)],
            ].join();

            setState(() => seedController.text = str);
          },
          icon: const Icon(Icons.casino),
        ),
      ],
    );
  }

  Widget get actionButtons {
    return Row(
      mainAxisSize: .min,
      spacing: 16,
      children: [
        if (kDebugMode)
          FloatingActionButton.small(
            tooltip: "Refresh sketch",
            onPressed: () => markController.refresh(),
            child: const Icon(Icons.refresh),
          ),
        if (kDebugMode)
          FloatingActionButton.small(
            tooltip: "Generate pattern",
            onPressed: () async {
              const width = 4096;
              const height = 2304;
              const size = 320;

              final recorder = ui.PictureRecorder();
              final canvas = Canvas(
                recorder,
                Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
              );

              canvas.drawColor(backgroundColor, .srcOver);

              final surface = CanvasSurface(canvas);

              final xCenterOffset =
                  ((size * (width / size).ceil() + 8 * ((width / size).ceil() - 1)) - width) / 2;

              final yCenterOffset = ((size * (height / size).ceil()) - height) / 2;

              for (int y = 0; y < (height / size); y++) {
                for (int x = 0; x < (width / size) + (y % 2 == 1 ? 1 : 0); x++) {
                  final mark = TavolaraMark(
                    style: style,
                    config: Configuration.fromRandom(
                      random: Random(stringToSeed(phraseGenerator())),
                      size: 200,
                    ),
                  );
                  mark.buildDefaultMark(
                    surface,
                    x * size +
                        (max(0, x - 1) * 8) -
                        (y % 2 == 1 ? size / 2 + 4 : 0) -
                        xCenterOffset,
                    y * size - yCenterOffset,
                    size,
                  );
                }
              }

              final picture = recorder.endRecording();
              final image = await picture.toImage(width, height);
              final png = await image.toByteData(format: .png);
              final pngBytes = png!.buffer.asUint8List();

              await FileSaver.instance.saveFile(
                name: "pattern",
                bytes: pngBytes,
                fileExtension: "png",
                mimeType: .png,
              );
            },
            child: const Icon(Icons.grid_4x4),
          ),
        FloatingActionButton(
          tooltip: "Download logo (SVG)",
          onPressed: () async {
            await saveMark(
              name: seedController.text,
              format: .basicPng,
              configuration: config,
              style: style,
            );
          },
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          child: const Icon(Icons.download),
        ),
      ],
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
        message: "${sizeVariant.name} (${(sizeVariant.size * 100).toInt()}%)",
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
