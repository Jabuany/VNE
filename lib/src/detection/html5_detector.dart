import 'dart:convert';
import 'dart:io';

import 'game_detector.dart';

export 'game_detector.dart' show DetectionConfidence;

typedef Html5Detection = ({
  DetectionConfidence confidence,
  String? entryPoint,
  List<String> evidence,
});

/// Inspects the conventional entry point without executing game content.
final class Html5Detector {
  static final _htmlStart = RegExp(
    r'^(?:\s|<!--[\s\S]*?-->)*(?:<!doctype\s+html\s*>|<html[\s>])',
    caseSensitive: false,
  );

  Future<Html5Detection> inspect(Directory directory) async {
    final entry = File.fromUri(directory.absolute.uri.resolve('index.html'));
    final type = await FileSystemEntity.type(entry.path, followLinks: false);
    if (type != FileSystemEntityType.file) {
      return (
        confidence: DetectionConfidence.inconclusive,
        entryPoint: null,
        evidence: const ['No regular index.html file at the root'],
      );
    }

    final handle = await entry.open();
    try {
      final bytes = await handle.read(4096);
      final hasUtf8Bom = bytes.length >= 3 &&
          bytes[0] == 0xef &&
          bytes[1] == 0xbb &&
          bytes[2] == 0xbf;
      final prefix = latin1.decode(hasUtf8Bom ? bytes.sublist(3) : bytes);
      if (!_htmlStart.hasMatch(prefix)) {
        return (
          confidence: DetectionConfidence.inconclusive,
          entryPoint: null,
          evidence: const ['index.html has no recognized HTML header'],
        );
      }

      return (
        confidence: DetectionConfidence.candidate,
        entryPoint: 'index.html',
        evidence: const ['Regular index.html file with a recognized HTML header'],
      );
    } finally {
      await handle.close();
    }
  }
}
