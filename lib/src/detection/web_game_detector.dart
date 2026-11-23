import 'html5_detector.dart';

enum WebContentKind {
  unknown,
  genericHtml,
  possibleWebGame,
  identifiedWebEngine,
}

final class WebDetection {
  WebDetection({
    required this.version,
    required this.kind,
    required this.confidence,
    required this.suggestedEngineId,
    required this.entryPoint,
    required Iterable<String> htmlEntries,
    required Iterable<String> evidence,
  }) : htmlEntries = List.unmodifiable(htmlEntries),
       evidence = List.unmodifiable(evidence);

  final int version;
  final WebContentKind kind;
  final DetectionConfidence confidence;
  final String? suggestedEngineId;
  final String? entryPoint;
  final List<String> htmlEntries;
  final List<String> evidence;
}

/// Classifies evidence supplied by the confined import reader.
final class WebGameDetector {
  static const version = 1;
  static const maxHtmlEntries = 16;
  static const tyranoCore = 'tyrano/tyrano.js';
  static const tyranoKag = 'tyrano/plugins/kag/kag.js';
  static const markers = {
    tyranoCore,
    tyranoKag,
    'game.js',
    'game.json',
    'game.wasm',
  };

  static bool isHtmlName(String path) =>
      path.toLowerCase().endsWith('.html') ||
      path.toLowerCase().endsWith('.htm');

  static int entryRank(String name) => switch (name.toLowerCase()) {
    'index.html' => 0,
    'index.htm' => 1,
    _ => 2,
  };

  WebDetection inspect({
    required Map<String, List<int>> htmlPrefixes,
    required Set<String> files,
    bool truncated = false,
  }) {
    final recognizer = Html5Detector();
    final entries =
        htmlPrefixes.entries
            .where(
              (file) =>
                  recognizer.inspectPrefix(file.value).confidence ==
                  DetectionConfidence.candidate,
            )
            .map((file) => file.key)
            .toList()
          ..sort((a, b) {
            final rank = entryRank(a).compareTo(entryRank(b));
            return rank == 0 ? a.compareTo(b) : rank;
          });
    final preferred = entries.isEmpty ? null : entries.first;
    final conventional = preferred != null && entryRank(preferred) < 2;
    final entry = conventional || entries.length == 1 ? preferred : null;
    final hasCore = files.contains(tyranoCore);
    final hasKag = files.contains(tyranoKag);
    final webAsset = files.contains('game.wasm') ? 'game.wasm' : 'game.json';

    final kind = switch ((entry, hasCore, hasKag)) {
      (null, _, _) when entries.isEmpty => WebContentKind.unknown,
      (_, true, true) when conventional => WebContentKind.identifiedWebEngine,
      (final String _, false, false)
          when files.contains('game.js') && files.contains(webAsset) =>
        WebContentKind.possibleWebGame,
      _ => WebContentKind.genericHtml,
    };
    final evidence = <String>[
      if (entries.isEmpty)
        'No se encontró una cabecera HTML reconocible en la raíz.',
      if (preferred != null) 'Cabecera HTML reconocida en $preferred.',
      if (entry == null && entries.isNotEmpty)
        'Hay varias entradas HTML y ninguna tiene prioridad automática.',
      if (hasCore) 'Se encontró $tyranoCore.',
      if (hasKag) 'Se encontró $tyranoKag.',
      if (kind == WebContentKind.possibleWebGame)
        'Se encontraron game.js y $webAsset junto a la entrada.',
      if (truncated)
        'Se alcanzó el límite de $maxHtmlEntries entradas inspeccionadas.',
    ];
    return WebDetection(
      version: version,
      kind: kind,
      confidence: switch (kind) {
        WebContentKind.unknown ||
        WebContentKind.genericHtml => DetectionConfidence.inconclusive,
        WebContentKind.possibleWebGame ||
        WebContentKind.identifiedWebEngine => DetectionConfidence.candidate,
      },
      suggestedEngineId: switch (kind) {
        WebContentKind.possibleWebGame => 'html5',
        WebContentKind.identifiedWebEngine => 'tyranoscript',
        _ => null,
      },
      entryPoint: entry,
      htmlEntries: entries,
      evidence: evidence,
    );
  }
}
