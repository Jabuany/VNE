import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vne/src/detection/game_detector.dart';
import 'package:vne/src/detection/web_game_detector.dart';

void main() {
  final detector = WebGameDetector();
  final html = utf8.encode('<!doctype html><html>');

  test('HTML alone or with a generic script does not assign HTML5', () {
    final result = detector.inspect(
      htmlPrefixes: {'index.html': html},
      files: {'game.js'},
    );
    expect(result.kind, WebContentKind.genericHtml);
    expect(result.confidence, DetectionConfidence.inconclusive);
    expect(result.suggestedEngineId, isNull);
    expect(result.htmlEntries, ['index.html']);
  });

  test('a text file named index.html stays unknown even with web assets', () {
    final result = detector.inspect(
      htmlPrefixes: {'index.html': utf8.encode('text')},
      files: {'game.js', 'game.json'},
    );
    expect(result.kind, WebContentKind.unknown);
    expect(result.entryPoint, isNull);
  });

  test('a header beyond the inspection budget is not used', () {
    final result = detector.inspect(
      htmlPrefixes: {'index.html': utf8.encode('${' ' * 4096}<!doctype html>')},
      files: {'game.js', 'game.json'},
    );
    expect(result.kind, WebContentKind.unknown);
    expect(result.htmlEntries, isEmpty);
  });

  test('checks a custom HTML entry without forcing a game classification', () {
    final result = detector.inspect(
      htmlPrefixes: {'start.html': html, 'menu.HTM': html},
      files: {'game.js', 'game.wasm'},
    );
    expect(result.kind, WebContentKind.genericHtml);
    expect(result.entryPoint, isNull);
    expect(result.htmlEntries, ['menu.HTM', 'start.html']);
  });

  test('uses a case-preserving index.htm as the conventional entry', () {
    final result = detector.inspect(
      htmlPrefixes: {'Intro.html': html, 'INDEX.HTM': html},
      files: {'game.js', 'game.wasm'},
    );
    expect(result.kind, WebContentKind.possibleWebGame);
    expect(result.suggestedEngineId, 'html5');
    expect(result.entryPoint, 'INDEX.HTM');
  });

  test('specific TyranoScript evidence takes priority and stays separate', () {
    final result = detector.inspect(
      htmlPrefixes: {'index.html': html},
      files: {
        WebGameDetector.tyranoCore,
        WebGameDetector.tyranoKag,
        'game.js',
        'game.wasm',
      },
    );
    expect(result.kind, WebContentKind.identifiedWebEngine);
    expect(result.suggestedEngineId, 'tyranoscript');
    expect(result.evidence.join(' '), contains(WebGameDetector.tyranoKag));
  });

  test('a partial TyranoScript layout avoids generic motor assignment', () {
    final result = detector.inspect(
      htmlPrefixes: {'index.html': html},
      files: {WebGameDetector.tyranoCore, 'game.js', 'game.wasm'},
    );
    expect(result.kind, WebContentKind.genericHtml);
    expect(result.suggestedEngineId, isNull);
  });
}
