import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../core/diagnostics.dart';
import '../../engine_api/engine.dart';

final class LinuxHtml5Adapter implements RuntimeAdapter {
  LinuxHtml5Adapter(this.helperPath);

  final String helperPath;
  bool _busy = false;

  @override
  EngineDescriptor get descriptor => (
    id: 'html5',
    name: 'HTML5',
    api: currentEngineApi,
    backend: RuntimeBackend.externalProcess,
  );

  @override
  Future<RuntimeSession> launch(RuntimeLaunch request) async {
    if (_busy) throw _failure('busy');
    final source = request.game.source.uri;
    final entry = request.game.entryPoint;
    if (request.game.engineId != 'html5' ||
        !RegExp(r'^[0-9a-f]{32}$').hasMatch(request.game.id) ||
        source.scheme != 'file' ||
        request.privateDataDirectory.scheme != 'file' ||
        entry == null ||
        !_safeEntry(entry)) {
      throw _failure('invalid_game');
    }
    final runtimeDir = Platform.environment['XDG_RUNTIME_DIR'];
    final display = Platform.environment['WAYLAND_DISPLAY'];
    if (runtimeDir == null ||
        !runtimeDir.startsWith('/') ||
        display == null ||
        !RegExp(r'^wayland-[0-9]+$').hasMatch(display) ||
        !helperPath.startsWith('/')) {
      throw _failure('runtime_unavailable');
    }

    _busy = true;
    try {
      final state = await Directory.fromUri(request.privateDataDirectory)
          .create(recursive: true);
      final helper = await File(helperPath).resolveSymbolicLinks();
      final process = await Process.start('/usr/bin/python3', [
        helper,
        '--launch',
        source.toFilePath(),
        ...sandboxArguments(
          state: await state.resolveSymbolicLinks(),
          helper: helper,
          runtimeDir: runtimeDir,
          display: display,
          withAudio:
              FileSystemEntity.typeSync('$runtimeDir/pulse/native') !=
              FileSystemEntityType.notFound,
          entry: entry,
          fullscreen: request.settings.fullscreen,
        ),
      ]);
      final session = _LinuxSession(process, () => _busy = false);
      try {
        await session.ready.future.timeout(const Duration(seconds: 20));
        return session;
      } on TimeoutException {
        await session.close();
        throw _failure('load_timeout');
      } on RuntimeFailure {
        await session.close();
        rethrow;
      }
    } on RuntimeFailure {
      _busy = false;
      rethrow;
    } catch (_) {
      _busy = false;
      throw _failure('runtime_unavailable');
    }
  }

  static List<String> sandboxArguments({
    required String state,
    required String helper,
    required String runtimeDir,
    required String display,
    required bool withAudio,
    required String entry,
    required bool fullscreen,
  }) => [
    '--unshare-net',
    '--unshare-pid',
    '--die-with-parent',
    '--new-session',
    '--ro-bind',
    '/usr',
    '/usr',
    '--symlink',
    'usr/bin',
    '/bin',
    '--symlink',
    'usr/lib',
    '/lib',
    '--symlink',
    'usr/lib64',
    '/lib64',
    '--proc',
    '/proc',
    '--dev',
    '/dev',
    '--tmpfs',
    '/tmp',
    '--tmpfs',
    '/run',
    '--ro-bind',
    '/sys',
    '/sys',
    '--dir',
    '/etc',
    '--ro-bind',
    '/etc/ld.so.cache',
    '/etc/ld.so.cache',
    '--ro-bind',
    '/etc/fonts',
    '/etc/fonts',
    '--ro-bind',
    '/etc/alternatives',
    '/etc/alternatives',
    '--ro-bind',
    '/etc/mime.types',
    '/etc/mime.types',
    '--ro-bind-fd',
    '@game',
    '/game',
    '--bind',
    state,
    '/state',
    '--ro-bind',
    helper,
    '/vne-player.py',
    '--ro-bind',
    '$runtimeDir/$display',
    '/run/vne/$display',
    '--clearenv',
    '--setenv',
    'PATH',
    '/usr/bin',
    '--setenv',
    'HOME',
    '/state',
    '--setenv',
    'XDG_RUNTIME_DIR',
    '/run/vne',
    '--setenv',
    'WAYLAND_DISPLAY',
    display,
    '--setenv',
    'GDK_BACKEND',
    'wayland',
    '--setenv',
    'LIBGL_ALWAYS_SOFTWARE',
    '1',
    if (withAudio) ...[
      '--ro-bind',
      '$runtimeDir/pulse/native',
      '/run/vne/pulse/native',
      '--setenv',
      'PULSE_SERVER',
      'unix:/run/vne/pulse/native',
    ],
    '--',
    '/usr/bin/python3',
    '/vne-player.py',
    '/${entry.split('/').map(Uri.encodeComponent).join('/')}',
    if (fullscreen) '--fullscreen',
  ];

  static bool _safeEntry(String entry) {
    final parts = entry.split('/');
    return parts.length <= 33 &&
        parts.every(
          (part) =>
              part.isNotEmpty &&
              part != '.' &&
              part != '..' &&
              utf8.encode(part).length <= 255 &&
              !part.contains(RegExp(r'[\\:\x00-\x1f]')),
        );
  }
}

final class _LinuxSession implements RuntimeSession {
  _LinuxSession(this.process, this.onExit) {
    unawaited(process.stderr.drain<void>());
    unawaited(process.stdin.done.then<void>((_) {}, onError: (_, _) {}));
    final lines = process.stdout
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .forEach(_onLine);
    unawaited(_observe(lines));
  }

  final Process process;
  final void Function() onExit;
  final ready = Completer<void>();
  final _exited = Completer<void>();
  final _events = StreamController<RuntimeEvent>();
  Future<void>? _closing;
  bool _reportedError = false;

  Future<void> _observe(Future<void> lines) async {
    final status = await process.exitCode;
    await lines;
    if (!ready.isCompleted) {
      ready.completeError(_failure('runtime_unavailable'));
    } else if (status != 0 && !_reportedError && _closing == null) {
      _diagnostic('renderer_stopped', error: true);
    }
    _events.add((kind: RuntimeEventKind.closed, diagnostic: null));
    unawaited(_events.close());
    onExit();
    _exited.complete();
  }

  void _onLine(String line) {
    final Map data;
    try {
      data = jsonDecode(line) as Map;
    } catch (_) {
      return;
    }
    final code = data['code'];
    switch (data['event']) {
      case 'ready':
        if (!ready.isCompleted) ready.complete();
      case 'warning' when code is String:
        _diagnostic(code, error: false);
      case 'error' when code is String:
        _reportedError = true;
        if (!ready.isCompleted) {
          ready.completeError(_failure(code));
        } else {
          _diagnostic(code, error: true);
        }
    }
  }

  void _diagnostic(String code, {required bool error}) => _events.add((
    kind: RuntimeEventKind.diagnostic,
    diagnostic: (
      code: code,
      message: _message(code),
      severity: error ? DiagnosticSeverity.error : DiagnosticSeverity.warning,
    ),
  ));

  @override
  Stream<RuntimeEvent> get events => _events.stream;
  @override
  PauseControl? get pauseControl => null;
  @override
  SaveControl? get saveControl => null;

  @override
  Future<void> close() => _closing ??= _requestClose();

  Future<void> _requestClose() async {
    if (_exited.isCompleted) return;
    try {
      process.stdin.writeln('close');
      await process.stdin.flush();
      await _exited.future.timeout(const Duration(seconds: 4));
    } catch (_) {
      process.kill(ProcessSignal.sigkill);
      await _exited.future;
    }
  }
}

RuntimeFailure _failure(String code) => RuntimeFailure((
  code: code,
  message: _message(code),
  severity: DiagnosticSeverity.error,
));

String _message(String code) => switch (code) {
  'busy' => 'Ya hay una partida abierta.',
  'invalid_game' => 'La entrada del juego no es válida.',
  'load_timeout' => 'El juego tardó demasiado en cargar.',
  'entry_load_failed' => 'No se pudo cargar la entrada HTML del juego.',
  'renderer_stopped' => 'El proceso de reproducción se detuvo.',
  'resource_unavailable' => 'No se pudo cargar un recurso del juego.',
  'navigation_blocked' => 'Se bloqueó una navegación fuera del juego.',
  'permission_blocked' => 'Se bloqueó un permiso web.',
  _ => 'No se pudo iniciar WebKitGTK con el aislamiento requerido.',
};
