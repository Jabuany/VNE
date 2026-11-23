import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../core/diagnostics.dart';
import '../core/game.dart';
import '../detection/html5_detector.dart';
import '../detection/web_game_detector.dart';
import 'game_importer.dart';
import 'import_tree.dart';

enum ImportPhase { scanning, copying, publishing }

typedef ImportProgress = ({ImportPhase phase, int entries, int bytes});

final class ImportCancellation {
  bool _cancelled = false;

  void cancel() => _cancelled = true;

  void check() {
    if (_cancelled) throw const _Cancelled();
  }
}

final class FolderGameImporter implements GameImporter {
  FolderGameImporter({
    required this.managedRoot,
    required this.openTree,
    required this.publish,
    required this.cancellation,
    required this.onProgress,
    this.maxEntries = 10000,
    this.maxBytes = 1024 * 1024 * 1024,
    this.maxDepth = 32,
  });

  final Directory managedRoot;
  final Future<ImportTree> Function(Uri source) openTree;
  final Future<void> Function(Game game, WebDetection detection) publish;
  final ImportCancellation cancellation;
  final void Function(ImportProgress progress) onProgress;
  final int maxEntries;
  final int maxBytes;
  final int maxDepth;

  @override
  Future<ImportResult> importGame(ImportRequest request) async {
    Directory? staging;
    final ImportResult result;
    try {
      cancellation.check();
      await managedRoot.create(recursive: true);
      final tree = await openTree(request.source);
      final Game game;
      final WebDetection detection;
      try {
        if (request.storage == GameStorage.managedCopy) {
          staging = await managedRoot.createTemp('game-');
        }
        final scan = _FolderScan(this, tree);
        await scan.walk(tree.root, staging, 0);
        detection = await scan.detect(staging);
        cancellation.check();
        if (request.storage == GameStorage.externalReference) {
          await tree.retainReference();
        }
        game = (
          id: _newId(),
          title: tree.title,
          source: (
            uri: staging?.uri ?? request.source,
            storage: request.storage,
          ),
          engineId: request.selectedEngineId ?? detection.suggestedEngineId,
          entryPoint: detection.entryPoint,
        );
      } finally {
        await tree.close();
      }
      cancellation.check();
      onProgress((phase: ImportPhase.publishing, entries: 0, bytes: 0));
      await publish(game, detection);
      return GameImported(game);
    } on _Cancelled {
      result = const ImportCancelled();
    } on _InvalidFolder catch (error) {
      result = _failure('invalid_folder', error.message);
    } on Exception {
      result = _failure(
        'import_failed',
        'No se pudo leer la carpeta o guardar el juego. Comprueba el acceso al origen y el espacio disponible.',
      );
    } on UnsupportedError {
      result = _failure(
        'unsupported_origin',
        'La plataforma no puede abrir este origen.',
      );
    }
    if (staging != null) {
      try {
        await staging.delete(recursive: true);
      } on FileSystemException {
        return _failure(
          'cleanup_failed',
          'No se pudo completar la importación ni limpiar la copia temporal.',
        );
      }
    }
    return result;
  }

  static ImportFailed _failure(String code, String message) => ImportFailed((
    severity: DiagnosticSeverity.error,
    code: code,
    message: message,
  ));

  static String _newId() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}

final class _FolderScan {
  _FolderScan(this.importer, this.tree);

  final FolderGameImporter importer;
  final ImportTree tree;
  final Set<String> _directories = {};
  int _entries = 0;
  int _bytes = 0;
  final List<TreeEntry> _html = [];
  final Set<String> _markers = {};

  Future<void> walk(
    String id,
    Directory? output,
    int depth, [
    String path = '',
  ]) async {
    if (depth > importer.maxDepth || !_directories.add(id)) {
      throw const _InvalidFolder(
        'La carpeta es demasiado profunda o se repite.',
      );
    }
    final names = <String>{};
    await for (final entry in tree.children(id)) {
      importer.cancellation.check();
      final name = entry.name;
      if (!_safeName(name) || !names.add(name.toLowerCase())) {
        throw const _InvalidFolder(
          'La carpeta contiene nombres inválidos o duplicados.',
        );
      }
      if (++_entries > importer.maxEntries) {
        throw const _InvalidFolder('La carpeta contiene demasiadas entradas.');
      }
      importer.onProgress((
        phase: output == null ? ImportPhase.scanning : ImportPhase.copying,
        entries: _entries,
        bytes: _bytes,
      ));
      importer.cancellation.check();
      final destination = output?.uri.resolveUri(Uri(pathSegments: [name]));
      final relative = '$path$name';
      if (entry.isDirectory) {
        final child = destination == null
            ? null
            : Directory.fromUri(destination);
        await child?.create();
        await walk(entry.id, child, depth + 1, '$relative/');
      } else {
        if (depth == 0 && WebGameDetector.isHtmlName(name)) _html.add(entry);
        if (WebGameDetector.markers.contains(relative)) _markers.add(relative);
        final size = entry.size;
        if (size != null && (size < 0 || size > importer.maxBytes - _bytes)) {
          throw const _InvalidFolder('La carpeta supera el límite de tamaño.');
        }
        if (destination == null) {
          if (size == null) {
            throw const _InvalidFolder(
              'No se pudo verificar el tamaño del origen. Prueba con una copia.',
            );
          }
          _bytes += size;
        } else {
          await _copy(entry.id, File.fromUri(destination));
        }
      }
    }
  }

  Future<void> _copy(String id, File file) async {
    final output = await file.open(mode: FileMode.write);
    var previousProgress = _bytes;
    try {
      await for (final chunk in tree.read(id)) {
        importer.cancellation.check();
        _bytes += chunk.length;
        if (_bytes > importer.maxBytes) {
          throw const _InvalidFolder('La carpeta supera el límite de tamaño.');
        }
        await output.writeFrom(chunk);
        if (_bytes - previousProgress >= 1024 * 1024) {
          previousProgress = _bytes;
          importer.onProgress((
            phase: ImportPhase.copying,
            entries: _entries,
            bytes: _bytes,
          ));
        }
      }
    } finally {
      await output.close();
    }
  }

  Future<WebDetection> detect(Directory? staging) async {
    importer.cancellation.check();
    _html.sort((a, b) {
      final rank = WebGameDetector.entryRank(a.name)
          .compareTo(WebGameDetector.entryRank(b.name));
      return rank == 0 ? a.name.compareTo(b.name) : rank;
    });
    final prefixes = <String, List<int>>{};
    for (final entry in _html.take(WebGameDetector.maxHtmlEntries)) {
      prefixes[entry.name] = await _readPrefix(entry, staging);
    }
    return WebGameDetector().inspect(
      htmlPrefixes: prefixes,
      files: _markers,
      truncated: _html.length > WebGameDetector.maxHtmlEntries,
    );
  }

  Future<List<int>> _readPrefix(TreeEntry entry, Directory? staging) async {
    const limit = Html5Detector.prefixLimit;
    final chunks = staging == null
        ? tree.read(entry.id, limit: limit)
        : File.fromUri(staging.uri.resolveUri(Uri(pathSegments: [entry.name])))
              .openRead(0, limit);
    final prefix = <int>[];
    await for (final chunk in chunks) {
      importer.cancellation.check();
      prefix.addAll(chunk.take(limit - prefix.length));
      if (prefix.length == limit) break;
    }
    return prefix;
  }

  static bool _safeName(String name) =>
      name.isNotEmpty &&
      name != '.' &&
      name != '..' &&
      utf8.encode(name).length <= 255 &&
      !name.contains(RegExp(r'[\\/:\x00-\x1f]'));
}

final class _InvalidFolder implements Exception {
  const _InvalidFolder(this.message);
  final String message;
}

final class _Cancelled implements Exception {
  const _Cancelled();
}
