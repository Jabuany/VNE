import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vne/src/core/game.dart';
import 'package:vne/src/detection/web_game_detector.dart';
import 'package:vne/src/import/folder_game_importer.dart';
import 'package:vne/src/import/game_importer.dart';
import 'package:vne/src/import/linux_import_tree.dart';
import 'package:vne/src/storage/sqlite_game_library.dart';

void main() {
  late Directory temporary;
  late Directory source;
  late Directory managed;
  late String databasePath;
  late File index;
  late ImportCancellation cancellation;
  const html = '<!doctype html><script>throw Error("must not run")</script>';

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('vne_folder_test');
    addTearDown(() => temporary.delete(recursive: true));
    source = await Directory.fromUri(
      temporary.uri.resolve('Juego%20%C3%81rbol/'),
    ).create();
    managed = Directory.fromUri(temporary.uri.resolve('managed/'));
    databasePath = temporary.uri.resolve('test.sqlite3').toFilePath();
    index = await File.fromUri(source.uri.resolve('index.html'))
        .writeAsString(html);
    cancellation = ImportCancellation();
  });

  Future<ImportResult> run(
    GameStorage storage, {
    int maxEntries = 10000,
    int maxBytes = 1024,
    int maxDepth = 32,
    void Function(ImportProgress)? onProgress,
    Future<void> Function(Game, WebDetection)? publish,
  }) {
    final importer = FolderGameImporter(
      managedRoot: managed,
      openTree: (uri) => LinuxImportTree.open(uri, managed),
      publish:
          publish ??
          (game, detection) async {
            final library = SqliteGameLibrary.open(databasePath);
            try {
              library.saveImportedGame(game, detection);
            } finally {
              library.close();
            }
          },
      cancellation: cancellation,
      onProgress: onProgress ?? (_) {},
      maxEntries: maxEntries,
      maxBytes: maxBytes,
      maxDepth: maxDepth,
    );
    return importer.importGame((
      source: source.uri,
      storage: storage,
      selectedEngineId: null,
    ));
  }

  test(
    'copies a tree, detects HTML and publishes a persistent entry',
    () async {
      final assets = await Directory.fromUri(source.uri.resolve('assets/'))
          .create();
      await File.fromUri(assets.uri.resolve('texto%20%C3%A1.txt'))
          .writeAsString('texto');
      await File.fromUri(source.uri.resolve('game.js'))
          .writeAsString('// test');
      await File.fromUri(source.uri.resolve('game.json')).writeAsString('{}');
      final result = await run(GameStorage.managedCopy);
      expect(result, isA<GameImported>());
      final game = (result as GameImported).game;
      expect(game.title, 'Juego Árbol');
      expect(game.engineId, 'html5');
      expect(game.entryPoint, 'index.html');
      expect(game.source.uri, isNot(source.uri));
      expect(await index.readAsString(), html);
      expect(
        await File.fromUri(game.source.uri.resolve('index.html'))
            .readAsString(),
        html,
      );
      expect(
        await File.fromUri(game.source.uri.resolve('assets/texto%20%C3%A1.txt'))
            .readAsString(),
        'texto',
      );
      final library = SqliteGameLibrary.open(databasePath);
      addTearDown(library.close);
      expect(library.findGame(game.id), game);
      final report = library.findDetection(game.id).report!;
      expect(report.kind, WebContentKind.possibleWebGame);
      expect(report.version, WebGameDetector.version);
      expect(report.evidence.join(' '), contains('game.json'));
    },
  );

  test(
    'references the original without copying and leaves unknown motor unset',
    () async {
      await index.writeAsString('plain text');
      final result = await run(GameStorage.externalReference);
      expect(result, isA<GameImported>());
      final game = (result as GameImported).game;
      expect(game.source.uri, source.uri);
      expect(game.engineId, isNull);
      expect(await managed.list().toList(), isEmpty);
      expect(await index.readAsString(), 'plain text');
    },
  );

  test('rejects a symbolic link and preserves the outside file', () async {
    final outside = await File.fromUri(temporary.uri.resolve('outside'))
        .writeAsString('outside');
    await Link.fromUri(source.uri.resolve('unsafe')).create(outside.path);
    expect(await run(GameStorage.managedCopy), isA<ImportFailed>());
    expect(await managed.list().toList(), isEmpty);
    expect(await outside.readAsString(), 'outside');
    expect(File(databasePath).existsSync(), isFalse);
  });

  test('rechecks a file replaced with a link after inspection', () async {
    final outside = await File.fromUri(temporary.uri.resolve('outside'))
        .writeAsString('outside');
    final result = await run(
      GameStorage.managedCopy,
      onProgress: (_) {
        index.renameSync(source.uri.resolve('original.html').toFilePath());
        Link(index.path).createSync(outside.path);
      },
    );
    expect(result, isA<ImportFailed>());
    expect(await managed.list().toList(), isEmpty);
    expect(await outside.readAsString(), 'outside');
  });

  test('limits bytes read when a file grows after metadata is read', () async {
    final result = await run(
      GameStorage.managedCopy,
      maxBytes: 1024,
      onProgress: (_) => index.writeAsStringSync('x' * 2048),
    );
    expect(result, isA<ImportFailed>());
    expect(await managed.list().toList(), isEmpty);
    expect(File(databasePath).existsSync(), isFalse);
  });

  test(
    'rejects duplicate names, absolute path syntax and traversal syntax',
    () async {
      for (final name in ['INDEX.HTML', r'..\outside', 'C:outside']) {
        final file = File('${source.path}/$name');
        await file.writeAsString('unsafe');
        expect(await run(GameStorage.managedCopy), isA<ImportFailed>());
        expect(await managed.list().toList(), isEmpty);
        await file.delete();
      }
    },
  );

  test('cleans the stage on entry, byte and depth limits', () async {
    await Directory.fromUri(source.uri.resolve('one/two/'))
        .create(recursive: true);
    expect(
      await run(GameStorage.managedCopy, maxEntries: 1),
      isA<ImportFailed>(),
    );
    expect(
      await run(GameStorage.managedCopy, maxBytes: 2),
      isA<ImportFailed>(),
    );
    expect(
      await run(GameStorage.managedCopy, maxDepth: 0),
      isA<ImportFailed>(),
    );
    expect(await managed.list().toList(), isEmpty);
    expect(await index.readAsString(), html);
  });

  test(
    'cancellation and a publication error both clean the staged copy',
    () async {
      final cancelled = await run(
        GameStorage.managedCopy,
        onProgress: (_) => cancellation.cancel(),
      );
      expect(cancelled, isA<ImportCancelled>());
      expect(await managed.list().toList(), isEmpty);
      cancellation = ImportCancellation();
      final failed = await run(
        GameStorage.managedCopy,
        publish: (_, _) async => throw const FileSystemException('Unavailable'),
      );
      expect(failed, isA<ImportFailed>());
      expect(await managed.list().toList(), isEmpty);
      expect(File(databasePath).existsSync(), isFalse);
    },
  );
}
