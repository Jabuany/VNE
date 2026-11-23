import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:vne/src/core/game.dart';
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
