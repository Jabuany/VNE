import '../core/diagnostics.dart';
import '../core/game.dart';

typedef EngineApiVersion = ({int major, int minor});

const EngineApiVersion currentEngineApi = (major: 1, minor: 0);

/// Minor revisions can add backward-compatible features. Each breaking
/// revision uses a new major number and requires an explicit adapter.
bool supportsEngineApi(
  EngineApiVersion required, {
  EngineApiVersion host = currentEngineApi,
}) =>
    required.major > 0 &&
    required.major == host.major &&
    required.minor >= 0 &&
    required.minor <= host.minor;

enum RuntimeBackend { webView, externalProcess, nativeComponent }

typedef EngineDescriptor = ({
  String id,
  String name,
  EngineApiVersion api,
  RuntimeBackend backend,
});

typedef RuntimeLaunch = ({
  Game game,
  GameSettings settings,
  Uri privateDataDirectory,
});

enum RuntimeEventKind { diagnostic, closed }

typedef RuntimeEvent = ({RuntimeEventKind kind, Diagnostic? diagnostic});

abstract interface class RuntimeAdapter {
  EngineDescriptor get descriptor;

  /// Returns once the game is running. Startup failures release any resources
  /// acquired during launch and report a [RuntimeFailure].
  Future<RuntimeSession> launch(RuntimeLaunch request);
}

abstract interface class RuntimeSession {
  /// Subscribe immediately after launch. Closed is terminal and ends the feed.
  Stream<RuntimeEvent> get events;

  PauseControl? get pauseControl;
  SaveControl? get saveControl;

  /// Releases the resources for this session. Repeated calls are safe.
  Future<void> close();
}

abstract interface class PauseControl {
  Future<void> pause();
  Future<void> resume();
}

abstract interface class SaveControl {
  Future<List<GameSave>> listSaves();
  Future<GameSave> save(String slotId);
  Future<void> load(String slotId);
}

final class RuntimeFailure implements Exception {
  const RuntimeFailure(this.diagnostic);

  final Diagnostic diagnostic;
}
