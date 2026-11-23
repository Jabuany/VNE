import '../core/diagnostics.dart';
import '../engine_api/engine.dart';

enum RuntimePlatform { android, linux }

typedef RuntimeTarget = ({RuntimePlatform platform, String architecture});

typedef RuntimePackage = ({
  String engineId,
  String version,
  EngineApiVersion api,
  RuntimeTarget target,
  Uri downloadUri,
  String sha256,
  int downloadBytes,
  int installedBytes,
  String license,
});

bool supportsRuntimePackage(RuntimePackage package, RuntimeTarget target) =>
    package.target == target && supportsEngineApi(package.api);

typedef InstalledRuntime = ({
  String engineId,
  String version,
  RuntimeTarget target,
  int installedBytes,
});

enum RuntimeInstallState { downloading, verifying, installing, installed }

typedef RuntimeInstallProgress = ({
  RuntimeInstallState state,
  int downloadedBytes,
});

abstract interface class RuntimeInstallation {
  Stream<RuntimeInstallProgress> get progress;
  Future<InstalledRuntime> get result;
  Future<void> cancel();
}

final class RuntimeInstallFailure implements Exception {
  const RuntimeInstallFailure(this.diagnostic);

  final Diagnostic diagnostic;

  @override
  String toString() => '${diagnostic.code}: ${diagnostic.message}';
}

abstract interface class RuntimeManager {
  Future<List<RuntimePackage>> catalog(RuntimeTarget target);
  Future<List<InstalledRuntime>> installed();

  /// Call only after the user confirms the selected package. Verify the
  /// trusted manifest, HTTPS and digest before activation. An update replaces
  /// the prior version only after the new version is ready. Failure or
  /// cancellation before activation preserves the prior installation.
  RuntimeInstallation install(RuntimePackage package);

  /// Removes the installation without deleting games or saves.
  Future<void> uninstall(InstalledRuntime runtime);
}
