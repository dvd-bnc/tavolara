import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:tavolara/config.dart';
import 'package:tavolara/mark.dart';
import 'package:tavolara/surface.dart';
import 'package:web/web.dart' as web;

abstract interface class _MarkControllerPlug {
  void onSave(String name);
  void onRefresh();
}

class MarkController {
  _MarkControllerPlug? _plug;

  void _setPlug(_MarkControllerPlug plug) {
    _plug = plug;
  }

  void dispose() {
    _plug = null;
  }

  void save(String name) => _plug?.onSave(name);
  void refresh() => _plug?.onRefresh();
}

enum MarkFormat { basicPng, svg }

Future<void> saveMark({
  required String name,
  required MarkFormat format,
  required Configuration configuration,
  required Style style,
}) async {
  switch (format) {
    case .svg:
      final parent = web.document.createElement('div') as web.HTMLDivElement;
      parent.style.display = "none";
      final sketch = TavolaraSketch(size: 600, parent: parent);
      sketch.bootstrap(configuration, style);

      sketch.save(name);

      parent.remove();
    case .basicPng:
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, 600, 600));
      final mark = TavolaraMark(style: style, config: configuration);
      mark.buildDefaultMark(CanvasSurface(canvas), 0, 0, 600);
      final picture = recorder.endRecording();
      final image = await picture.toImage(600, 600);
      final png = await image.toByteData(format: .png);
      final pngBytes = png!.buffer.asUint8List();

      await FileSaver.instance.saveFile(
        name: name.trim().isEmpty ? "untitled" : name,
        bytes: pngBytes,
        fileExtension: "png",
        mimeType: .png,
      );
  }
}

enum MarkRenderer { canvas, p5 }

class MarkWidget extends StatelessWidget {
  final Configuration configuration;
  final Style style;
  final MarkRenderer renderer;
  final MarkController? controller;

  const MarkWidget({
    required this.configuration,
    required this.style,
    this.renderer = .canvas,
    this.controller,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: switch (renderer) {
        .canvas => _CanvasMarkWidget(
          configuration: configuration,
          style: style,
          controller: controller,
        ),
        .p5 => _P5MarkWidget(configuration: configuration, style: style, controller: controller),
      },
    );
  }
}

class _P5MarkWidget extends StatefulWidget {
  final Configuration configuration;
  final Style style;
  final MarkController? controller;

  const _P5MarkWidget({required this.configuration, required this.style, this.controller});

  @override
  State<_P5MarkWidget> createState() => _P5MarkWidgetState();
}

class _P5MarkWidgetState extends State<_P5MarkWidget> implements _MarkControllerPlug {
  late TavolaraSketch sketch;

  @override
  void onRefresh() {
    sketch.p5.redraw();
  }

  @override
  void onSave(String name) {
    sketch.save(name);
  }

  @override
  void initState() {
    super.initState();
    widget.controller?._setPlug(this);
  }

  @override
  void dispose() {
    widget.controller?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _P5MarkWidget old) {
    super.didUpdateWidget(old);

    if (widget.controller != old.controller) {
      widget.controller?._setPlug(this);
    }

    if (widget.configuration != old.configuration) {
      sketch.updateConfiguration(widget.configuration);
    }

    if (widget.style != old.style) {
      sketch.updateStyle(widget.style);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Transform.scale(
          scale: math.min(math.min(constraints.maxWidth, constraints.maxHeight), 600) / 600,
          child: OverflowBox(
            fit: .deferToChild,
            maxWidth: .infinity,
            maxHeight: .infinity,
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
                  sketch.bootstrap(widget.configuration, widget.style);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CanvasMarkWidget extends StatefulWidget {
  final Configuration configuration;
  final Style style;
  final MarkController? controller;

  const _CanvasMarkWidget({required this.configuration, required this.style, this.controller});

  @override
  State<_CanvasMarkWidget> createState() => _CanvasMarkWidgetState();
}

class _CanvasMarkWidgetState extends State<_CanvasMarkWidget> implements _MarkControllerPlug {
  @override
  void onRefresh() {
    setState(() {});
  }

  @override
  void onSave(String name) {
    // TODO: implement onSave
  }

  @override
  void initState() {
    super.initState();
    widget.controller?._setPlug(this);
  }

  @override
  void didUpdateWidget(covariant _CanvasMarkWidget old) {
    super.didUpdateWidget(old);

    if (widget.controller != old.controller) {
      widget.controller?._setPlug(this);
    }
  }

  @override
  void dispose() {
    widget.controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MarkPainter(widget.configuration, widget.style),
      child: SizedBox.expand(),
    );
  }
}

class _MarkPainter extends CustomPainter {
  final Configuration configuration;
  final Style style;

  const _MarkPainter(this.configuration, this.style);

  @override
  void paint(Canvas canvas, Size size) {
    // canvas.scale(size.width / 600 * scale);
    final mark = TavolaraMark(style: style, config: configuration);
    mark.buildDefaultMark(CanvasSurface(canvas), 0, 0, size.width);
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) {
    return configuration != old.configuration || style != old.style;
  }
}
