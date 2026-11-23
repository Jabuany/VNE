import 'package:flutter_test/flutter_test.dart';
import 'package:vne/src/core/game.dart';
import 'package:vne/src/detection/game_detector.dart';
import 'package:vne/src/engine_api/engine.dart';
import 'package:vne/src/engine_manager/runtime_manager.dart';
import 'package:vne/src/import/game_importer.dart';

void main() {
  test('a host supports equal and older minor revisions of its API', () {
    const host = (major: 1, minor: 2);

    expect(supportsEngineApi((major: 1, minor: 0), host: host), isTrue);
    expect(supportsEngineApi(host, host: host), isTrue);
    expect(supportsEngineApi((major: 1, minor: 3), host: host), isFalse);
    expect(supportsEngineApi((major: 2, minor: 0), host: host), isFalse);
    expect(supportsEngineApi((major: 1, minor: -1), host: host), isFalse);
  });

  test('a package must match the target and supported API', () {
    const target = (platform: RuntimePlatform.linux, architecture: 'x64');
    final RuntimePackage package = (
      engineId: 'test',
      version: '1',
      api: currentEngineApi,
      target: target,
      downloadUri: Uri(),
      sha256: '',
      downloadBytes: 0,
      installedBytes: 0,
      license: '',
    );

    expect(supportsRuntimePackage(package, target), isTrue);
    expect(
      supportsRuntimePackage(package, (
        platform: RuntimePlatform.android,
        architecture: 'x64',
      )),
      isFalse,
    );
    expect(
      supportsRuntimePackage(package, (
        platform: RuntimePlatform.linux,
        architecture: 'arm64',
      )),
      isFalse,
    );
    final RuntimePackage incompatible = (
      engineId: package.engineId,
      version: package.version,
      api: (major: 2, minor: 0),
      target: package.target,
      downloadUri: package.downloadUri,
      sha256: package.sha256,
      downloadBytes: package.downloadBytes,
      installedBytes: package.installedBytes,
      license: package.license,
    );
    expect(supportsRuntimePackage(incompatible, target), isFalse);
  });

  test('detection evidence is immutable and inconclusive has no engine', () {
    final evidence = ['HTML header'];
    final candidate = EngineDetection.candidate(
      engineId: 'html5',
      entryPoint: 'index.html',
      evidence: evidence,
    );
    final inconclusive = EngineDetection.inconclusive(evidence: const []);
    evidence.clear();

    expect(candidate.confidence, DetectionConfidence.candidate);
    expect(candidate.evidence, ['HTML header']);
    expect(() => candidate.evidence.clear(), throwsUnsupportedError);
    expect(inconclusive.confidence, DetectionConfidence.inconclusive);
    expect(inconclusive.engineId, isNull);
    expect(inconclusive.entryPoint, isNull);
  });

  test('engine selection retains findings independently of the caller', () {
    final findings = [
      EngineDetection.inconclusive(evidence: ['Unrecognized layout']),
    ];
    final result = EngineSelectionRequired(findings);
    findings.clear();

    expect(result.findings.single.evidence, ['Unrecognized layout']);
    expect(() => result.findings.clear(), throwsUnsupportedError);
  });

  test('an Android document URI remains an external reference', () {
    final uri = Uri.parse('content://example.invalid/document/game');
    final GameSource source = (
      uri: uri,
      storage: GameStorage.externalReference,
    );

    expect(source.uri.scheme, 'content');
    expect(source.storage, GameStorage.externalReference);
  });
}
