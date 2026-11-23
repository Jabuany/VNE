import 'package:sqlite3/sqlite3.dart';

import '../core/game.dart';
import '../library/game_library.dart';

final class SqliteGameLibrary implements GameLibrary {
  SqliteGameLibrary._(this._database);

  static const schemaVersion = 1;

  final Database _database;

  static SqliteGameLibrary open(String path) {
    final database = sqlite3.open(path);
    try {
      database.execute('PRAGMA busy_timeout = 1000');
      database.execute('PRAGMA foreign_keys = ON');
      _migrate(database);
      return SqliteGameLibrary._(database);
    } catch (_) {
      database.close();
      rethrow;
    }
  }

  static void _migrate(Database database) {
    database.execute('BEGIN IMMEDIATE');
    try {
      final version = database
          .select('PRAGMA user_version')
          .single
          .values
          .first;
      switch (version) {
        case 0:
          database.execute('''
            CREATE TABLE games (
              id TEXT PRIMARY KEY NOT NULL,
              title TEXT NOT NULL,
              source_uri TEXT NOT NULL,
              storage TEXT NOT NULL CHECK (
                storage IN ('externalReference', 'managedCopy')
              ),
              engine_id TEXT,
              entry_point TEXT
            ) STRICT;
            CREATE INDEX games_by_title ON games (title COLLATE NOCASE, id);
            CREATE TABLE game_settings (
              game_id TEXT PRIMARY KEY NOT NULL
                REFERENCES games(id) ON DELETE CASCADE,
              fullscreen INTEGER NOT NULL CHECK (fullscreen IN (0, 1)),
              preferred_locale TEXT
            ) STRICT;
            PRAGMA user_version = 1;
          ''');
        case schemaVersion:
          break;
        default:
          throw UnsupportedError(
            'Unsupported library schema version: $version',
          );
      }
      database.execute('COMMIT');
    } catch (_) {
      database.execute('ROLLBACK');
      rethrow;
    }
  }

  @override
  List<Game> listGames() => _database
      .select('SELECT * FROM games ORDER BY title COLLATE NOCASE, id')
      .map(_readGame)
      .toList(growable: false);

  @override
  Game? findGame(String id) {
    final rows = _database.select('SELECT * FROM games WHERE id = ?', [id]);
    return rows.isEmpty ? null : _readGame(rows.single);
  }

  static Game _readGame(Row row) => (
    id: row['id'] as String,
    title: row['title'] as String,
    source: (
      uri: Uri.parse(row['source_uri'] as String),
      storage: GameStorage.values.byName(row['storage'] as String),
    ),
    engineId: row['engine_id'] as String?,
    entryPoint: row['entry_point'] as String?,
  );

  @override
  void saveGame(Game game) {
    _database.execute(
      '''
      INSERT INTO games (id, title, source_uri, storage, engine_id, entry_point)
      VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        title = excluded.title, source_uri = excluded.source_uri,
        storage = excluded.storage, engine_id = excluded.engine_id,
        entry_point = excluded.entry_point
      ''',
      [
        game.id,
        game.title,
        game.source.uri.toString(),
        game.source.storage.name,
        game.engineId,
        game.entryPoint,
      ],
    );
  }

  @override
  bool removeGame(String id) {
    _database.execute('DELETE FROM games WHERE id = ?', [id]);
    return _database.updatedRows > 0;
  }

  @override
  GameSettings? findSettings(String gameId) {
    final rows = _database.select(
      'SELECT fullscreen, preferred_locale FROM game_settings WHERE game_id = ?',
      [gameId],
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    return (
      fullscreen: row['fullscreen'] == 1,
      preferredLocale: row['preferred_locale'] as String?,
    );
  }

  @override
  void saveSettings(String gameId, GameSettings settings) {
    _database.execute(
      '''
      INSERT INTO game_settings (game_id, fullscreen, preferred_locale)
      VALUES (?, ?, ?)
      ON CONFLICT(game_id) DO UPDATE SET
        fullscreen = excluded.fullscreen,
        preferred_locale = excluded.preferred_locale
      ''',
      [gameId, settings.fullscreen ? 1 : 0, settings.preferredLocale],
    );
  }

  void close() => _database.close();
}
