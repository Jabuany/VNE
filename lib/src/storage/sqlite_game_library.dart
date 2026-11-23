import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import '../core/game.dart';
import '../detection/game_detector.dart';
import '../detection/web_game_detector.dart';
import '../library/game_library.dart';

final class SqliteGameLibrary implements GameLibrary {
  SqliteGameLibrary._(this._database);

  static const schemaVersion = 2;

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
    _transaction(database, () {
      final version =
          database.select('PRAGMA user_version').single['user_version'] as int;
      if (version < 0 || version > schemaVersion) {
        throw UnsupportedError('Unsupported library schema version: $version');
      }
      if (version == 0) {
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
          ''');
      }
      if (version < 2) {
        database.execute('''
          ALTER TABLE games ADD COLUMN engine_manual INTEGER NOT NULL DEFAULT 0
            CHECK (engine_manual IN (0, 1));
          CREATE TABLE game_detection (
            game_id TEXT PRIMARY KEY NOT NULL REFERENCES games(id) ON DELETE CASCADE,
            detector_version INTEGER NOT NULL CHECK (detector_version > 0),
            kind TEXT NOT NULL,
            confidence TEXT NOT NULL,
            suggested_engine_id TEXT,
            entry_point TEXT,
            html_entries TEXT NOT NULL,
            evidence TEXT NOT NULL
          ) STRICT;
          PRAGMA user_version = 2;
        ''');
      }
    });
  }

  static T _transaction<T>(Database database, T Function() operation) {
    database.execute('BEGIN IMMEDIATE');
    try {
      final value = operation();
      database.execute('COMMIT');
      return value;
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
  void saveImportedGame(Game game, WebDetection report) {
    _transaction(_database, () {
      saveGame(game);
      _database.execute(
        '''
        INSERT INTO game_detection (
          game_id, detector_version, kind, confidence, suggested_engine_id,
          entry_point, html_entries, evidence
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          game.id,
          report.version,
          report.kind.name,
          report.confidence.name,
          report.suggestedEngineId,
          report.entryPoint,
          jsonEncode(report.htmlEntries),
          jsonEncode(report.evidence),
        ],
      );
      if (game.engineId != report.suggestedEngineId) {
        _database.execute('UPDATE games SET engine_manual = 1 WHERE id = ?', [
          game.id,
        ]);
      }
    });
  }

  @override
  GameDetectionState findDetection(String gameId) {
    final rows = _database.select(
      '''
      SELECT games.engine_manual, game_detection.*
      FROM games LEFT JOIN game_detection ON games.id = game_detection.game_id
      WHERE games.id = ?
      ''',
      [gameId],
    );
    if (rows.isEmpty) return (report: null, manual: false);
    final row = rows.single;
    final version = row['detector_version'] as int?;
    return (
      manual: row['engine_manual'] == 1,
      report: version == null
          ? null
          : WebDetection(
              version: version,
              kind: WebContentKind.values.byName(row['kind'] as String),
              confidence: DetectionConfidence.values.byName(
                row['confidence'] as String,
              ),
              suggestedEngineId: row['suggested_engine_id'] as String?,
              entryPoint: row['entry_point'] as String?,
              htmlEntries: (jsonDecode(row['html_entries'] as String) as List)
                  .cast<String>(),
              evidence: (jsonDecode(row['evidence'] as String) as List)
                  .cast<String>(),
            ),
    );
  }

  @override
  Game selectEngine(
    String gameId, {
    required bool automatic,
    String? entryPoint,
  }) => _transaction(_database, () {
    final game = findGame(gameId);
    if (game == null)
      throw ArgumentError.value(gameId, 'gameId', 'Unknown game');
    final report = findDetection(gameId).report;
    if (automatic && report == null) {
      throw ArgumentError('Automatic selection requires a detection report');
    }
    final eligible =
        report?.htmlEntries ?? [if (game.entryPoint case final entry?) entry];
    if (entryPoint != null && !eligible.contains(entryPoint)) {
      throw ArgumentError('The selected entry was not detected');
    }
    final engine = automatic
        ? report!.suggestedEngineId
        : entryPoint == null
        ? null
        : 'html5';
    final entry = automatic
        ? report!.entryPoint
        : entryPoint ?? report?.entryPoint ?? game.entryPoint;
    _database.execute(
      'UPDATE games SET engine_id = ?, entry_point = ?, engine_manual = ? WHERE id = ?',
      [engine, entry, automatic ? 0 : 1, gameId],
    );
    return findGame(gameId)!;
  });

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
