import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart';

import '../core/diagnostics.dart';
import 'html5_catalog.dart';
import 'runtime_manager.dart';

final class LocalRuntimeManager implements RuntimeManager {
  LocalRuntimeManager({
    required this.directory,
    required this.target,
    required Iterable<RuntimeCatalogItem> entries,
  }) : entries = List.unmodifiable(
         entries.where((item) => supportsRuntimePackage(item.package, target)),
       );

  final Future<Directory> Function() directory;
  final RuntimeTarget target;
  final List<RuntimeCatalogItem> entries;
  bool _working = false;
  bool _playing = false;

  @override
  Future<List<RuntimePackage>> catalog(RuntimeTarget target) async => [
    for (final item in entries)
      if (item.package.target == target) item.package,
  ];

  @override
  Future<List<InstalledRuntime>> installed() async => _read((db) {
    final active = _packageAt(db, 0);
    return active == null ? [] : [_installed(active)];
  });

  Future<InstalledRuntime?> previous() => _read((db) {
    final package = _packageAt(db, 1);
    return package == null ? null : _installed(package);
  });

  @override
  RuntimeInstallation install(RuntimePackage package) => _start(package, null);

  RuntimeInstallation installFromFile(RuntimePackage package, File file) =>
      _start(package, file);

  RuntimeInstallation _start(RuntimePackage package, File? file) {
    final operation = _Installation();
    final busy = _working || _playing;
    if (!busy) _working = true;
    operation.result = Future.microtask(() async {
      try {
        if (busy)
          throw _failure('busy', 'Hay otra operación de motor en curso.');
        final matches = entries.where((entry) => entry.package == package);
        if (matches.isEmpty) {
          throw _failure(
            'catalog',
            'El paquete no está en el catálogo de confianza.',
          );
        }
        final entry = matches.single;
        if (entry.needsFile != (file != null)) {
          throw _failure('source', 'Elige un origen válido para el paquete.');
        }
        final bytes = await operation.read(entry, file);
        operation.report(RuntimeInstallState.verifying, bytes.length);
        _verify(package, bytes);
        operation.check();
        final context = await _open();
        try {
          operation.check();
          operation.report(RuntimeInstallState.installing, bytes.length);
          _transaction(context.db, () {
            final db = context.db;
            final active = _row(db, 0);
            if (active == null ||
                active['digest'] != package.sha256 ||
                active['version'] != package.version) {
              db.execute('DELETE FROM packages WHERE slot = 1');
              db.execute('UPDATE packages SET slot = 1 WHERE slot = 0');
            }
            db.execute('INSERT OR REPLACE INTO packages VALUES (0, ?, ?, ?)', [
              package.version,
              package.sha256,
              bytes,
            ]);
          });
        } finally {
          context.db.close();
        }
        operation.report(RuntimeInstallState.installed, bytes.length);
        return _installed(package);
      } on RuntimeInstallFailure {
        rethrow;
      } on Exception {
        operation.check();
        throw _failure('io', 'No se pudo leer o guardar el paquete del motor.');
      } finally {
        if (!busy) _working = false;
        unawaited(operation.events.close());
      }
    });
    return operation;
  }

  Future<void> rollback() => _exclusive(() async {
    await _read(
      (db) => _transaction(db, () {
        final package = _packageAt(db, 1);
        final previous = _row(db, 1);
        if (package == null || previous == null) {
          throw _failure('rollback', 'No hay una versión anterior disponible.');
        }
        _verify(package, previous['payload'] as Uint8List);
        db.execute('UPDATE packages SET slot = 2 WHERE slot = 0');
        db.execute('UPDATE packages SET slot = 0 WHERE slot = 1');
        db.execute('UPDATE packages SET slot = 1 WHERE slot = 2');
      }),
    );
  });

  @override
  Future<void> uninstall(InstalledRuntime runtime) => _exclusive(() async {
    final context = await _open();
    try {
      _transaction(context.db, () {
        final active = _packageAt(context.db, 0);
        if (active == null || _installed(active) != runtime) {
          throw _failure(
            'stale',
            'La versión activa cambió. Vuelve a abrir el gestor.',
          );
        }
        context.db.execute('DELETE FROM packages');
      });
      // Reclaim empty pages from the runtime store only.
      try {
        context.db.execute('VACUUM');
      } on SqliteException {
        // The uninstall itself has already been committed.
      }
    } finally {
      context.db.close();
    }
  });

  /// Validates the persisted payload immediately before dispatch to an adapter.
  Future<T> withActive<T>(Future<T> Function(String? helperPath) run) async {
    if (_working || _playing) {
      throw _failure('busy', 'Hay otra operación de motor en curso.');
    }
    _playing = true;
    Directory? staging;
    try {
      final context = await _open();
      final Uint8List bytes;
      try {
        final row = _row(context.db, 0);
        final package = _known(row);
        if (package == null || row == null) {
          throw _failure(
            'unavailable',
            'Instala o activa HTML5 desde Motores.',
          );
        }
        bytes = row['payload'] as Uint8List;
        _verify(package, bytes);
      } finally {
        context.db.close();
      }
      if (target.platform == RuntimePlatform.android) return await run(null);
      staging = await context.root.createTemp('play-');
      final helper = File.fromUri(staging.uri.resolve('player.py'));
      await helper.writeAsBytes(bytes, flush: true);
      return await run(helper.path);
    } finally {
      _playing = false;
      if (staging != null) await staging.delete(recursive: true);
    }
  }

  Future<T> _exclusive<T>(Future<T> Function() operation) async {
    if (_working || _playing) {
      throw _failure('busy', 'Hay otra operación de motor en curso.');
    }
    _working = true;
    try {
      return await operation();
    } finally {
      _working = false;
    }
  }

  Future<({Database db, Directory root})> _open() async {
    final root = Directory.fromUri(
      (await directory()).uri.resolve('runtimes/'),
    );
    await root.create(recursive: true);
    final db = sqlite3.open(root.uri.resolve('html5.sqlite3').toFilePath());
    try {
      db.execute('PRAGMA busy_timeout = 1000');
      db.execute('''
        CREATE TABLE IF NOT EXISTS packages (
          slot INTEGER PRIMARY KEY CHECK (slot IN (0, 1, 2)),
          version TEXT NOT NULL, digest TEXT NOT NULL, payload BLOB NOT NULL
        ) STRICT
      ''');
      return (db: db, root: root);
    } catch (_) {
      db.close();
      rethrow;
    }
  }

  Future<T> _read<T>(T Function(Database) read) async {
    final context = await _open();
    try {
      return read(context.db);
    } finally {
      context.db.close();
    }
  }

  static Row? _row(Database db, int slot) {
    final rows = db.select('SELECT * FROM packages WHERE slot = ?', [slot]);
    return rows.isEmpty ? null : rows.single;
  }

  RuntimePackage? _known(Row? row) {
    if (row == null) return null;
    for (final item in entries) {
      final package = item.package;
      if (package.version == row['version'] &&
          package.sha256 == row['digest']) {
        return package;
      }
    }
    return null;
  }

  RuntimePackage? _packageAt(Database db, int slot) => _known(_row(db, slot));

  static InstalledRuntime _installed(RuntimePackage package) => (
    engineId: package.engineId,
    version: package.version,
    target: package.target,
    installedBytes: package.installedBytes,
  );

  static void _transaction(Database db, void Function() operation) {
    db.execute('BEGIN IMMEDIATE');
    try {
      operation();
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }
}

final class _Installation implements RuntimeInstallation {
  final events = StreamController<RuntimeInstallProgress>();
  HttpClient? _client;
  bool _cancelled = false;
  bool _committing = false;

  @override
  late final Future<InstalledRuntime> result;

  @override
  Stream<RuntimeInstallProgress> get progress => events.stream;

  @override
  Future<void> cancel() async {
    if (_committing) return;
    _cancelled = true;
    _client?.close(force: true);
  }

  void check() {
    if (_cancelled) throw _failure('cancelled', 'Instalación cancelada.');
  }

  void report(RuntimeInstallState state, int bytes) {
    if (state == RuntimeInstallState.installing) _committing = true;
    events.add((state: state, downloadedBytes: bytes));
  }

  Future<Uint8List> read(RuntimeCatalogItem entry, File? file) async {
    final package = entry.package;
    if (package.downloadBytes <= 0 ||
        package.downloadBytes > 16 * 1024 * 1024) {
      throw _failure(
        'size',
        'El paquete supera el límite de tamaño del instalador.',
      );
    }
    final Stream<List<int>> stream;
    check();
    if (entry.bundledDescriptor case final descriptor?) {
      stream = Stream.value(utf8.encode(descriptor));
    } else if (file != null) {
      stream = file.openRead();
    } else {
      stream = await _https(package);
    }
    final bytes = BytesBuilder();
    try {
      report(RuntimeInstallState.downloading, 0);
      await for (final chunk in stream.timeout(const Duration(seconds: 20))) {
        check();
        if (bytes.length + chunk.length > package.downloadBytes) {
          throw _failure(
            'size',
            'El tamaño del archivo no coincide con el catálogo.',
          );
        }
        bytes.add(chunk);
        report(RuntimeInstallState.downloading, bytes.length);
      }
      check();
      return bytes.takeBytes();
    } finally {
      _client?.close(force: true);
      _client = null;
    }
  }

  Future<HttpClientResponse> _https(RuntimePackage package) async {
    if (!isSecureRuntimeUrl(package.downloadUri)) {
      throw _failure('source', 'La descarga requiere un origen HTTPS.');
    }
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15)
      ..autoUncompress = false;
    _client = client;
    try {
      final request = await client.getUrl(package.downloadUri);
      request.followRedirects = false;
      request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      final encoding = response.headers.value(
        HttpHeaders.contentEncodingHeader,
      );
      if (response.statusCode != HttpStatus.ok ||
          (encoding != null && encoding.toLowerCase() != 'identity') ||
          (response.contentLength != -1 &&
              response.contentLength != package.downloadBytes)) {
        throw _failure(
          'download',
          'El servidor no devolvió el paquete previsto.',
        );
      }
      return response;
    } catch (_) {
      client.close(force: true);
      _client = null;
      rethrow;
    }
  }
}

void _verify(RuntimePackage package, Uint8List bytes) {
  if (bytes.length != package.downloadBytes) {
    throw _failure(
      'size',
      'El tamaño del archivo no coincide con el catálogo.',
    );
  }
  if (sha256.convert(bytes).toString() != package.sha256) {
    throw _failure(
      'integrity',
      'El SHA-256 del paquete no coincide con el catálogo.',
    );
  }
}

RuntimeInstallFailure _failure(String code, String message) =>
    RuntimeInstallFailure((
      code: code,
      message: message,
      severity: DiagnosticSeverity.error,
    ));
