import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tavolara/config.dart';
import 'package:tavolara/mark.dart';
import 'package:tavolara/widgets.dart';

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  String? _validPass;
  _SurveyFormData? _data;

  @override
  Widget build(BuildContext context) {
    if (_validPass == null || !_validHashes.contains(_computeHash(_validPass!))) {
      return _SurveyGatePage(onPassSuccess: (pass) => setState(() => _validPass = pass));
    }

    if (_data == null) {
      return _SurveyFormPage(
        onFormSubmit: (data) {
          final feedback = SentryFeedback(
            name: _computeHash(_validPass!),
            message:
                "selectedMarks: \"${data.selectedMarks.map((e) => '"$e"').join(",")}\"\nfavoriteMark: \"${data.favoriteMark}\"\nmessage:\n${data.comment}",
          );
          Sentry.captureFeedback(feedback);
          setState(() => _data = data);
        },
      );
    }

    return _SurveyThankYouPage();
  }
}

String _computeHash(String str) {
  return base64Encode(sha256.convert(utf8.encode(str)).bytes);
}

const _validHashes = [
  "i99TJdTf9LRCrENM4zRt/lEc1ZM2smgL3h+fb4yp7cs=",
  "3MJn6Dlwgn4xRyWQBa6kcKf1ScplJDj5cIpoG19XLb8=",
  "gCseu0Dcjo78O/Enqjvat4g8sPsjSmcC7U3h3hsh+Yg=",
  "e6yAUjCMnA25roPYr80dG8SnTShl1CRYPfRJPeqTLX4=",
  "XduXbdx4f012No+W5mmGibxOA6bLyKP15QhHnLBfkZw=",
  "KY1dcPC/qoeSOtp5COOEB4p54Mbg+LfTFKTJrHWHcNM=",
  "TdLT3yiAD0j1K5y69moQ8SrXlPuu9mlJV0voBBozWZk=",
  "PpJfiSw6l9sLyYd2gXQLL+MYJXM74EYiJ3qqKYrCnfo=",
  "1ufYZLMf6AJUzKm/McNG5r7oP3DEdeVqpqu3m7KAQMU=",
  "DDrAa+PqRIJR+9rP7Uuox9PHDk23obQGCGIRCjoXGtM=",
  "Q1HAA2oycFKheNGCeWr1PBa3ihoUbm0L6N4/dBRgV2w=",
  "ddg3o/WEfjI0cRIgvrroFo509XgQr7H3fXDjiCD6ok8=",
  "MFlTsEtbaqfXryp+3pBOCPmk47beVYZrsvipUsCVXcM=",
  "32dxYqOLXa72KMven02517k0fcuNPp0AB/FKyeTMGRE=",
  "wM3OGIH02Y2Ev1+gHtsolCxhS29YZEkBi9bPRMlHd4c=",
  "DbotRdoCkB/WQ1tpNfBvt0KpF8+taw1O+VOpyAaCboI=",
  "brTg6e7gWNv/5UlkLW8Sihk747MInpL3xJVki9toMLo=",
];

class _SurveyGatePage extends StatefulWidget {
  final void Function(String) onPassSuccess;

  const _SurveyGatePage({required this.onPassSuccess});

  @override
  State<_SurveyGatePage> createState() => _SurveyGatePageState();
}

class _SurveyGatePageState extends State<_SurveyGatePage> {
  bool _error = false;
  final _passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Title(
      title: "survey gate",
      color: Colors.black,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(title: Text("Survey gate"), backgroundColor: Colors.transparent),
        backgroundColor: Colors.grey.shade900,
        body: _GridBackground(
          child: SizedBox.expand(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                spacing: 8,
                crossAxisAlignment: .start,
                mainAxisAlignment: .center,
                children: [
                  Text("Enter the key you were given"),
                  TextField(
                    controller: _passController,
                    decoration: InputDecoration(errorText: _error ? "That did not work" : null),
                    onChanged: (value) => setState(() => _error = false),
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            final hash = _computeHash(_passController.text);
            if (!_validHashes.contains(hash)) {
              setState(() => _error = true);
              _passController.text = "";
              return;
            }

            widget.onPassSuccess(_passController.text);
          },
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          icon: Icon(Icons.key),
          label: Text("Submit"),
        ),
      ),
    );
  }
}

typedef _SurveyFormData = ({List<String> selectedMarks, String favoriteMark, String comment});

class _SurveyFormPage extends StatefulWidget {
  final void Function(_SurveyFormData data) onFormSubmit;

  const _SurveyFormPage({required this.onFormSubmit});

  @override
  State<_SurveyFormPage> createState() => _SurveyFormPageState();
}

enum _SurveyStep { first, second, third }

class _SurveyFormPageState extends State<_SurveyFormPage> {
  static const firstStepMaxSelection = 9;

  _SurveyStep _step = .first;

  final _style = Style(
    backgroundColor: Colors.transparent,
    color: Colors.white,
    strokeClasses: {.thinner: 3, .thin: 4, .thick: 6, .thicker: 8, .thickest: 10},
  );

  List<String> get _seeds => [
    '7pwi7djAvWwGR2SVLhUBBGH8JxJd3xGg',
    'F0o6sPixNfaF0CS1eBIwAfTx0QqQdFuX',
    'GTkWfrfjJeiGeBhtIY7qV7w0WDoDElDH',
    'jBrIahC6y0CDS4JEWXAcCkGsjv0in4jj',
    'dea20TgdceSCyORM0LtyAyu3RCrKX3mA',
    'ayX78yc8BpTq38203tufviNJjE8atvdR',
    '8U3q3oL3UOgklbbYBpDNJn8LfxdCGsSP',
    'jpT4Bb3LfUW1g7ymX7FiHGyJPI3ttBAa',
    '04OFolFPh4lsn0Jm31wWnDtbTtQFNtPV',
    'riryN4mShOCb1r8rbLU6piEQNSsPommg',
    'pvXwVTGHHi45FbnOSQCd1xEuqMCldYQq',
    'BwJy5nABx4A3wvvOb46dkIiO8VEivfXR',
    'BQrObMmG1LWYbARc7eqB3qaFLKKBIOfI',
    'bxYhBFM64uq5N1wOtOWuKHB5An80gucT',
    'cXT3ou56sHcUtHR1BVUMGDhHasxpgsv2',
    'ndSKpTRIwaoYfLJXKLNLE1rw2Evhue4c',
  ];

  final List<int> _firstStepSelection = [];
  int? _secondStepSelection;
  final _thirdStepController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Title(
      title: "survey program",
      color: Colors.black,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(switch (_step) {
            .first => "Select 9 marks",
            .second => "Select your preferred mark",
            .third => "Add a comment (optional)",
          }),
          backgroundColor: Colors.transparent,
        ),
        backgroundColor: Colors.grey.shade900,
        body: _GridBackground(
          child: switch (_step) {
            .first => buildFirstStepWidget(context),
            .second => buildSecondStepWidget(context),
            .third => buildThirdStepWidget(context),
          },
        ),
        bottomNavigationBar: SizedBox(
          height: 56 + 16,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 800),
                child: Row(
                  children: [
                    FilledButton(
                      onPressed: switch (_step) {
                        .first => null,
                        .second => () => setState(() => _step = .first),
                        .third => () => setState(() => _step = .second),
                      },
                      child: Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: switch (_step) {
                        .first => Text(
                          "${_firstStepSelection.length}/$firstStepMaxSelection",
                          textAlign: .center,
                          style: TextStyle(fontSize: 16),
                        ),
                        _ => SizedBox(),
                      },
                    ),
                    FilledButton.icon(
                      onPressed: switch (_step) {
                        .first when _firstStepSelection.length == firstStepMaxSelection => () {
                          _secondStepSelection = null;
                          setState(() => _step = .second);
                        },
                        .second when _secondStepSelection != null => () {
                          setState(() => _step = .third);
                        },
                        .third => () {
                          widget.onFormSubmit((
                            selectedMarks: _firstStepSelection.map((e) => _seeds[e]).toList(),
                            favoriteMark: _seeds[_secondStepSelection!],
                            comment: _thirdStepController.text,
                          ));
                        },
                        _ => null,
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _firstStepSelection.length == firstStepMaxSelection
                            ? Colors.white
                            : Colors.black,
                        foregroundColor: _firstStepSelection.length == firstStepMaxSelection
                            ? Colors.black
                            : Colors.white,
                      ),
                      icon: switch (_step) {
                        .first || .second => Icon(Icons.arrow_forward),
                        .third => Icon(Icons.done),
                      },
                      label: switch (_step) {
                        .first || .second => Text("Next"),
                        .third => Text("Submit"),
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildFirstStepWidget(BuildContext context) {
    final breakpoints = ResponsiveBreakpoints.of(context);
    final double padding = breakpoints.isDesktop ? 16 : 0;

    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          padding: .all(padding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisSpacing: padding,
            mainAxisSpacing: padding,
            crossAxisCount: 4,
          ),
          itemCount: _seeds.length,
          itemBuilder: (context, index) => Material(
            color: _firstStepSelection.contains(index) ? Colors.white : Colors.black,
            elevation: 8,
            child: InkWell(
              onTap:
                  _firstStepSelection.length < firstStepMaxSelection ||
                      _firstStepSelection.contains(index)
                  ? () {
                      if (_firstStepSelection.contains(index)) {
                        _firstStepSelection.remove(index);
                      } else {
                        _firstStepSelection.add(index);
                      }
                      setState(() {});
                    }
                  : null,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      Opacity(
                        opacity:
                            _firstStepSelection.length >= firstStepMaxSelection &&
                                !_firstStepSelection.contains(index)
                            ? 0.4
                            : 1,
                        child: MarkWidget(
                          configuration: Configuration.fromRandom(
                            random: Random(stringToSeed(_seeds[index])),
                            size: 200,
                            // override: _overrides[index],
                          ),
                          style: Style(
                            backgroundColor: _style.backgroundColor,
                            color: _firstStepSelection.contains(index)
                                ? Colors.black
                                : Colors.white,
                            strokeClasses: _style.strokeClasses,
                          ),
                        ),
                      ),
                      if (_firstStepSelection.contains(index))
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
    );
  }

  Widget buildSecondStepWidget(BuildContext context) {
    final breakpoints = ResponsiveBreakpoints.of(context);
    final double padding = breakpoints.isDesktop ? 16 : 0;

    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          padding: .all(padding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisSpacing: padding,
            mainAxisSpacing: padding,
            crossAxisCount: 3,
          ),
          itemCount: firstStepMaxSelection,
          itemBuilder: (context, index) => Material(
            color: _secondStepSelection == _firstStepSelection[index] ? Colors.white : Colors.black,
            elevation: 8,
            child: InkWell(
              onTap: () {
                if (_secondStepSelection == _firstStepSelection[index]) {
                  _secondStepSelection = null;
                } else {
                  _secondStepSelection = _firstStepSelection[index];
                }
                setState(() {});
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      MarkWidget(
                        configuration: Configuration.fromRandom(
                          random: Random(stringToSeed(_seeds[_firstStepSelection[index]])),
                          size: 200,
                        ),
                        style: Style(
                          backgroundColor: _style.backgroundColor,
                          color: _secondStepSelection == _firstStepSelection[index]
                              ? Colors.black
                              : Colors.white,
                          strokeClasses: _style.strokeClasses,
                        ),
                      ),
                      if (_secondStepSelection == _firstStepSelection[index])
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
    );
  }

  Widget buildThirdStepWidget(BuildContext context) {
    return Center(
      child: Padding(
        padding: .all(8),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 800),
          child: SizedBox.expand(
            child: TextField(
              controller: _thirdStepController,
              decoration: InputDecoration(
                label: Text("Comment (optional)"),
                alignLabelWithHint: true,
              ),
              maxLength: 600,
              maxLines: null,
              expands: true,
              textAlignVertical: .top,
            ),
          ),
        ),
      ),
    );
  }
}

class _GridBackground extends StatelessWidget {
  final Widget child;

  const _GridBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: .expand,
      children: [
        Positioned.fill(
          child: ClipRect(
            clipBehavior: .none,
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
        Positioned.fill(child: child),
      ],
    );
  }
}

class _SurveyThankYouPage extends StatelessWidget {
  const _SurveyThankYouPage();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade900,
      child: _GridBackground(
        child: SizedBox.expand(
          child: Center(
            child: Text(
              "Thank you, survey submitted",
              style: TextStyle(fontSize: 32),
              textAlign: .center,
            ),
          ),
        ),
      ),
    );
  }
}
