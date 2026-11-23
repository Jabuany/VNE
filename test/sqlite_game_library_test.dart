import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:vne/src/core/game.dart';
import 'package:vne/src/detection/game_detector.dart';
import 'package:vne/src/detection/web_game_detector.dart';
import 'package:vne/src/storage/sqlite_game_library.dart';

void main() {
  late String path;
  final Game game = (
    id: 'game-1',
    title: "Árbol de O'Brien",
    source: (
      uri: Uri.parse('content://example.invalid/document/novela%20local'),
      storage: GameStorage.externalReference,
    ),
    engineId: 'html5',
    entryPoint: 'index.html',
  );

  setUp(() async {
    final directory = await Directory.systemTemp.createTemp('vne_library_');
    addTearDown(() => directory.delete(recursive: true));
    path = directory.uri.resolve('test.sqlite3').toFilePath();
  });

  test('game and settings survive close and reopen, and support CRUD', () {
    final original = SqliteGameLibrary.open(path);
    try {
      expect(original.listGames(), isEmpty);
      original.saveGame(game);
      original.saveSettings(game.id, (fullscreen: true, preferredLocale: 'es'));
    } finally {
      original.close();
    }

    final reopened = SqliteGameLibrary.open(path);
    try {
      expect(reopened.listGames(), [game]);
      expect(reopened.findGame(game.id), game);
      expect(reopened.findSettings(game.id), (
        fullscreen: true,
        preferredLocale: 'es',
      ));
      final Game updated = (
        id: game.id,
        title: 'Otro título',
        source: game.source,
        engineId: null,
        entryPoint: null,
      );
      reopened.saveGame(updated);
      expect(reopened.findGame(game.id), updated);
      expect(reopened.findSettings(game.id)?.fullscreen, isTrue);
      reopened.saveSettings(game.id, (
        fullscreen: false,
        preferredLocale: null,
      ));
      expect(reopened.findSettings(game.id)?.fullscreen, isFalse);
      expect(reopened.removeGame(game.id), isTrue);
      expect(reopened.removeGame(game.id), isFalse);
      expect(reopened.findGame(game.id), isNull);
      expect(reopened.findSettings(game.id), isNull);
    } finally {
      reopened.close();
    }
  });

  test('settings require an existing game', () {
    final library = SqliteGameLibrary.open(path);
    addTearDown(library.close);
    expect(
      () => library.saveSettings(game.id, (
        fullscreen: false,
        preferredLocale: null,
      )),
      throwsA(isA<SqliteException>()),
    );
  });

  test('migrates a version 1 library without inventing evidence', () {
    final database = sqlite3.open(path);
    database.execute('''
      CREATE TABLE games (
        id TEXT PRIMARY KEY NOT NULL, title TEXT NOT NULL, source_uri TEXT NOT NULL,
        storage TEXT NOT NULL, engine_id TEXT, entry_point TEXT
      ) STRICT;
      CREATE TABLE game_settings (
        game_id TEXT PRIMARY KEY NOT NULL REFERENCES games(id) ON DELETE CASCADE,
        fullscreen INTEGER NOT NULL, preferred_locale TEXT
      ) STRICT;
      PRAGMA user_version = 1;
    ''');
    database.execute('INSERT INTO games VALUES (?, ?, ?, ?, ?, ?)', [
      game.id,
      game.title,
      game.source.uri.toString(),
      game.source.storage.name,
      game.engineId,
      game.entryPoint,
    ]);
    database.execute('INSERT INTO game_settings VALUES (?, ?, ?)', [
      game.id,
      1,
      'es',
    ]);
    database.close();

    final library = SqliteGameLibrary.open(path);
    addTearDown(library.close);
    expect(library.findGame(game.id), game);
    expect(library.findSettings(game.id), (
      fullscreen: true,
      preferredLocale: 'es',
    ));
    expect(library.findDetection(game.id), (report: null, manual: false));
    expect(library.selectEngine(game.id, automatic: false).engineId, isNull);
    expect(library.findDetection(game.id), (report: null, manual: true));
  });

  test('a manual selection persists without changing automatic evidence', () {
    final report = WebDetection(
      version: 1,
      kind: WebContentKind.identifiedWebEngine,
      confidence: DetectionConfidence.candidate,
      suggestedEngineId: 'tyranoscript',
      entryPoint: 'index.html',
      htmlEntries: ['index.html', 'intro.htm'],
      evidence: ['Structure marker'],
    );
    final library = SqliteGameLibrary.open(path);
    library.saveImportedGame((
      id: game.id,
      title: game.title,
      source: game.source,
      engineId: 'tyranoscript',
      entryPoint: 'index.html',
    ), report);
    expect(
      () => library.selectEngine(
        game.id,
        automatic: false,
        entryPoint: '../other.html',
      ),
      throwsArgumentError,
    );
    expect(
      library
          .selectEngine(game.id, automatic: false, entryPoint: 'intro.htm')
          .engineId,
      'html5',
    );
    library.close();

    final reopened = SqliteGameLibrary.open(path);
    addTearDown(reopened.close);
    expect(reopened.findGame(game.id)?.entryPoint, 'intro.htm');
    final stored = reopened.findDetection(game.id);
    expect(stored.manual, isTrue);
    expect(stored.report?.evidence, report.evidence);
    expect(stored.report?.suggestedEngineId, 'tyranoscript');
    expect(stored.report?.version, 1);
    expect(
      reopened.selectEngine(game.id, automatic: true).engineId,
      'tyranoscript',
    );
    expect(reopened.findGame(game.id)?.entryPoint, 'index.html');
    expect(reopened.findDetection(game.id).manual, isFalse);
    reopened.removeGame(game.id);
    expect(reopened.findDetection(game.id).report, isNull);
  });

  test('rolls back imported game when its detection report fails to save', () {
    final library = SqliteGameLibrary.open(path);
    addTearDown(library.close);
    final invalid = WebDetection(
      version: 0,
      kind: WebContentKind.unknown,
      confidence: DetectionConfidence.inconclusive,
      suggestedEngineId: null,
      entryPoint: null,
      htmlEntries: [],
      evidence: [],
    );
    expect(
      () => library.saveImportedGame(game, invalid),
      throwsA(isA<SqliteException>()),
    );
    expect(library.findGame(game.id), isNull);
  });

  test('does not rewrite a database created with a newer schema', () {
    final database = sqlite3.open(path);
    database.execute('PRAGMA user_version = 99');
    database.close();

    expect(() => SqliteGameLibrary.open(path), throwsUnsupportedError);

    final reopened = sqlite3.open(path);
    addTearDown(reopened.close);
    expect(reopened.select('PRAGMA user_version').single['user_version'], 99);
  });

  test('a failed migration does not leave a partial schema', () {
    final database = sqlite3.open(path);
    database.execute('CREATE TABLE game_settings (sentinel INTEGER)');
    database.close();

    expect(() => SqliteGameLibrary.open(path), throwsA(isA<SqliteException>()));

    final reopened = sqlite3.open(path);
    addTearDown(reopened.close);
    expect(reopened.select('PRAGMA user_version').single['user_version'], 0);
    expect(
      reopened.select("SELECT name FROM sqlite_schema WHERE name = 'games'"),
      isEmpty,
    );
    expect(
      reopened.select('PRAGMA table_info(game_settings)').single['name'],
      'sentinel',
    );
  });
}
