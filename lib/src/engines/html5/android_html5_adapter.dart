import 'dart:async';

import 'package:flutter/services.dart';

import '../../core/diagnostics.dart';
import '../../core/game.dart';
import '../../engine_api/engine.dart';

final class AndroidHtml5Adapter implements RuntimeAdapter {
  AndroidHtml5Adapter() {
    _channel.setMethodCallHandler(_onEvent);
  }

  static const _channel = MethodChannel('org.vne.vne/html5');
  _AndroidHtml5Session? _active;
  int _nextToken = 0;

  @override
  EngineDescriptor get descriptor => (
    id: 'html5',
    name: 'HTML5',
    api: currentEngineApi,
    backend: RuntimeBackend.webView,
  );

  @override
  Future<RuntimeSession> launch(RuntimeLaunch request) async {
    if (_active != null) {
      throw _failure('busy', 'Ya hay una partida abierta.');
    }
    final game = request.game;
    final entry = game.entryPoint;
    if (game.engineId != descriptor.id || entry == null) {
      throw _failure('invalid_game', 'El juego requiere una entrada HTML5.');
    }
    final session = _AndroidHtml5Session(++_nextToken);
    _active = session;
    try {
      await _channel.invokeMethod<void>('launch', {
        'token': session.token,
        'gameId': game.id,
        'source': game.source.uri.toString(),
        'entryPoint': entry,
        'managed': game.source.storage == GameStorage.managedCopy,
        'fullscreen': request.settings.fullscreen,
      });
      return session;
    } on PlatformException catch (error) {
      _release(session);
      throw _failure(error.code, error.message ?? 'No se pudo iniciar HTML5.');
    } on MissingPluginException {
      _release(session);
      throw _failure(
        'runtime_unavailable',
        'El runtime HTML5 no está disponible.',
      );
    }
  }

  Future<void> _onEvent(MethodCall call) async {
    final active = _active;
    if (active == null || call.arguments is! Map) return;
    final data = call.arguments as Map;
    if (data['token'] != active.token) return;
    switch (call.method) {
      case 'diagnostic':
        active._events.add((
          kind: RuntimeEventKind.diagnostic,
          diagnostic: (
            severity: data['error'] == true
                ? DiagnosticSeverity.error
                : DiagnosticSeverity.warning,
            code: data['code'] as String,
            message: data['message'] as String,
          ),
        ));
      case 'closed':
        _release(active);
    }
  }

  void _release(_AndroidHtml5Session session) {
    if (_active != session) return;
    _active = null;
    session._finish();
  }
}

final class _AndroidHtml5Session implements RuntimeSession, PauseControl {
  _AndroidHtml5Session(this.token);

  final int token;
  final _events = StreamController<RuntimeEvent>();
  final _closed = Completer<void>();
  Future<void>? _closing;

  @override
  Stream<RuntimeEvent> get events => _events.stream;

  @override
  PauseControl get pauseControl => this;

  @override
  SaveControl? get saveControl => null;

  @override
  Future<void> pause() => _command('pause');

  @override
  Future<void> resume() => _command('resume');

  Future<void> _command(String method) async {
    if (_closed.isCompleted) return;
    await AndroidHtml5Adapter._channel.invokeMethod<void>(method, {
      'token': token,
    });
  }

  @override
  Future<void> close() => _closing ??= _requestClose();

  Future<void> _requestClose() async {
    await _command('close');
    await _closed.future;
  }

  void _finish() {
    _events.add((kind: RuntimeEventKind.closed, diagnostic: null));
    unawaited(_events.close());
    _closed.complete();
  }
}

RuntimeFailure _failure(String code, String message) => RuntimeFailure((
  severity: DiagnosticSeverity.error,
  code: code,
  message: message,
));
