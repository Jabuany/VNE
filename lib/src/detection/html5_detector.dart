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
    r'(?:<!doctype\s+html\s*>|<html[\s>])',
    caseSensitive: false,
  );
  static final _space = RegExp(r'\s');

  static const prefixLimit = 4096;

  /// Inspects an already-opened source supplied by the import layer.
  Html5Detection inspectPrefix(List<int> bytes) {
    final end = bytes.length > prefixLimit ? prefixLimit : bytes.length;
    final hasUtf8Bom =
        end >= 3 && bytes[0] == 0xef && bytes[1] == 0xbb && bytes[2] == 0xbf;
    final prefix = latin1.decode(bytes.sublist(hasUtf8Bom ? 3 : 0, end));
    var offset = 0;
    while (offset < prefix.length) {
      if (_space.matchAsPrefix(prefix, offset) != null) {
        offset++;
      } else if (prefix.startsWith('<!--', offset)) {
        final endOfComment = prefix.indexOf('-->', offset + 4);
        if (endOfComment < 0) break;
        offset = endOfComment + 3;
      } else {
        break;
      }
    }
    if (_htmlStart.matchAsPrefix(prefix, offset) == null) {
      return (
        confidence: DetectionConfidence.inconclusive,
        entryPoint: null,
        evidence: const ['index.html has no recognized HTML header'],
      );
    }
    return (
      confidence: DetectionConfidence.candidate,
      entryPoint: 'index.html',
      evidence: const ['index.html with a recognized HTML header'],
    );
  }

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
      return inspectPrefix(await handle.read(prefixLimit));
    } finally {
      await handle.close();
    }
  }
}
