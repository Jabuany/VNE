import 'dart:io';

import '../lib/src/detection/html5_detector.dart';

Future<void> main() async {
  final directory = await Directory.systemTemp.createTemp('vne_detection_');
  final entry = File.fromUri(directory.uri.resolve('index.html'));
  final detector = Html5Detector();
  try {
    final absent = await detector.inspect(directory);
    if (absent.confidence != DetectionConfidence.inconclusive ||
        absent.entryPoint != null) {
      throw StateError('A missing file must be inconclusive');
    }

    await entry.writeAsString('This is not an HTML document.');
    final plainText = await detector.inspect(directory);
    if (plainText.confidence != DetectionConfidence.inconclusive ||
        plainText.entryPoint != null) {
      throw StateError('The filename alone must be inconclusive');
    }

    await entry.writeAsString('\uFEFF\n<!-- VNE fixture -->\n<!DOCTYPE html>');
    final html = await detector.inspect(directory);
    if (html.confidence != DetectionConfidence.candidate ||
        html.entryPoint != 'index.html' ||
        html.evidence.isEmpty) {
      throw StateError('An HTML header must produce a candidate with evidence');
    }
    stdout.writeln('HTML5 detection checks passed.');
  } finally {
    await directory.delete(recursive: true);
  }
}
