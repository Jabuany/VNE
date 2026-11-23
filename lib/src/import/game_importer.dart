import '../core/diagnostics.dart';
import '../core/game.dart';
import '../detection/game_detector.dart';

typedef ImportRequest = ({
  Uri source,
  GameStorage storage,
  String? selectedEngineId,
});

sealed class ImportResult {
  const ImportResult();
}

final class GameImported extends ImportResult {
  const GameImported(this.game);

  final Game game;
}

final class EngineSelectionRequired extends ImportResult {
  EngineSelectionRequired(Iterable<EngineDetection> findings)
    : findings = List.unmodifiable(findings);

  final List<EngineDetection> findings;
}

final class ImportFailed extends ImportResult {
  const ImportFailed(this.diagnostic);

  final Diagnostic diagnostic;
}

final class ImportCancelled extends ImportResult {
  const ImportCancelled();
}

abstract interface class GameImporter {
  /// Imports without launching a game. Returns a selection request before
  /// publishing a library entry when the engine choice is ambiguous.
  Future<ImportResult> importGame(ImportRequest request);
}
