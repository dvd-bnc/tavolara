import 'dart:math';

import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:tavolara/config.dart';
import 'package:tavolara/main.dart';
import 'package:tavolara/mark.dart';

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  final seed = Random().nextInt(4294967296);
  final _style = Style(
    backgroundColor: Colors.transparent,
    color: Colors.white,
    strokeClasses: {.thinner: 3, .thin: 4, .thick: 6, .thicker: 8, .thickest: 10},
  );

  List<ConfigurationOverride> get _overrides => [
    ConfigurationOverride(
      diskStyle: OverrideProperty(value: .concentric, mode: .override),
    ),
    ConfigurationOverride(
      diskStyle: OverrideProperty(value: .simple, mode: .override),
    ),
    ConfigurationOverride(
      diskStyle: OverrideProperty(value: .face, mode: .override),
    ),
    ConfigurationOverride(),
    ConfigurationOverride(
      petalStyle: OverrideProperty(value: .narrowSpikes, mode: .override),
    ),
    ConfigurationOverride(
      petalStyle: OverrideProperty(value: .spikes, mode: .override),
    ),
    ConfigurationOverride(
      petalStyle: OverrideProperty(value: .sharp, mode: .override),
    ),
    ConfigurationOverride(),
    ConfigurationOverride(
      sepalStyle: OverrideProperty(value: .none, mode: .override),
    ),
    ConfigurationOverride(
      sepalStyle: OverrideProperty(value: .dots, mode: .override),
    ),
    ConfigurationOverride(
      sepalStyle: OverrideProperty(value: .mandala, mode: .override),
    ),
    ConfigurationOverride(),
    ConfigurationOverride(
      haloStyle: OverrideProperty(value: .ring, mode: .override),
    ),
    ConfigurationOverride(
      haloStyle: OverrideProperty(value: .contraPetal, mode: .override),
    ),
    ConfigurationOverride(
      haloStyle: OverrideProperty(value: .gear, mode: .override),
    ),
    ConfigurationOverride(
      haloStyle: OverrideProperty(value: .hatching, mode: .override),
    ),
  ];

  Set<int> _selection = {};

  static const markPadding = 0;

  @override
  Widget build(BuildContext context) {
    final breakpoints = ResponsiveBreakpoints.of(context);
    final random = Random(seed);

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: Row(
        children: [
          Stack(
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
              AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  padding: .all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    crossAxisCount: 4,
                  ),
                  itemCount: _overrides.length,
                  itemBuilder: (context, index) => Material(
                    color: Colors.black,
                    elevation: 8,
                    child: InkWell(
                      onTap: _selection.length < 9 || _selection.contains(index)
                          ? () {
                              if (_selection.contains(index)) {
                                _selection.remove(index);
                              } else {
                                _selection.add(index);
                              }
                              setState(() {});
                            }
                          : null,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              Opacity(
                                opacity: _selection.length >= 9 && !_selection.contains(index)
                                    ? 0.4
                                    : 1,
                                child: Transform.scale(
                                  scale:
                                      min(
                                        min(constraints.maxWidth, constraints.maxHeight) -
                                            markPadding * 2,
                                        600,
                                      ) /
                                      600,
                                  child: OverflowBox(
                                    fit: .deferToChild,
                                    maxWidth: .infinity,
                                    maxHeight: .infinity,
                                    child: SizedBox.square(
                                      dimension: 600,
                                      child: CustomPaint(
                                        painter: MarkPainter(
                                          TavolaraMark(
                                            config: Configuration.fromRandom(
                                              random: random,
                                              size: 200,
                                              override: _overrides[index],
                                            ),
                                            style: _style,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (_selection.contains(index))
                                Positioned.fill(
                                  child: Material(
                                    color: Colors.white54,
                                    child: const Icon(Icons.check, size: 48, color: Colors.black),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Material(color: Colors.black, child: SizedBox.expand()),
          ),
        ],
      ),
    );
  }
}
