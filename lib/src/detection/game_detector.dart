import '../core/diagnostics.dart';

enum DetectionConfidence { inconclusive, candidate }

final class EngineDetection {
  EngineDetection.candidate({
    required String engineId,
    required this.entryPoint,
    required Iterable<String> evidence,
  }) : engineId = engineId,
       confidence = DetectionConfidence.candidate,
       evidence = List.unmodifiable(evidence);

  EngineDetection.inconclusive({required Iterable<String> evidence})
    : engineId = null,
      entryPoint = null,
      confidence = DetectionConfidence.inconclusive,
      evidence = List.unmodifiable(evidence);

  final String? engineId;
  final String? entryPoint;
  final DetectionConfidence confidence;
  final List<String> evidence;
}

abstract interface class GameDetector {
  /// Inspects a staged or referenced source without executing its contents.
  /// Multiple candidates require a selection by the caller.
  Future<({List<EngineDetection> findings, List<Diagnostic> diagnostics})>
  inspect(Uri source);
}
