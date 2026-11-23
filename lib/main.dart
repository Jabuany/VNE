import 'dart:io';
import 'dart:isolate';

import 'package:file_selector_linux/file_selector_linux.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import 'src/app/library_page.dart';
import 'src/core/game.dart';
import 'src/detection/web_game_detector.dart';
import 'src/import/android_import_tree.dart';
import 'src/import/folder_game_importer.dart';
import 'src/import/game_importer.dart';
import 'src/import/linux_import_tree.dart';
import 'src/library/game_library.dart';
import 'src/storage/sqlite_game_library.dart';

void main() {
  runApp(
    VneApp(
      loadGames: _loadGames,
      importFolder: _importFolder,
      loadDetection: _loadDetection,
      changeEngine: _changeEngine,
    ),
  );
}

Future<ImportResult?> _importFolder(
  GameStorage storage,
  ImportCancellation cancellation,
  void Function(ImportProgress) onProgress,
) async {
  final Uri? source;
  if (Platform.isAndroid) {
    source = await AndroidImportTree.pick();
  } else {
    final path = await FileSelectorLinux().getDirectoryPath();
    source = path == null ? null : Uri.directory(path);
  }
  if (source == null) return null;
  final directory = await getApplicationSupportDirectory();
  final managedRoot = Directory.fromUri(directory.uri.resolve('games/'));
  final databasePath = directory.uri.resolve('library.sqlite3').toFilePath();
  final importer = FolderGameImporter(
    managedRoot: managedRoot,
    openTree: Platform.isAndroid
        ? AndroidImportTree.open
        : (uri) => LinuxImportTree.open(uri, managedRoot),
    publish: (game, detection) => _saveGame(databasePath, game, detection),
    cancellation: cancellation,
    onProgress: onProgress,
  );
  return importer.importGame((
    source: source,
    storage: storage,
    selectedEngineId: null,
  ));
}

Future<void> _saveGame(String path, Game game, WebDetection detection) =>
    _useLibrary(path, (library) => library.saveImportedGame(game, detection));

Future<String> _libraryPath() async {
  final directory = await getApplicationSupportDirectory();
  await directory.create(recursive: true);
  return directory.uri.resolve('library.sqlite3').toFilePath();
}

Future<List<Game>> _loadGames() async =>
    _useLibrary(await _libraryPath(), (library) => library.listGames());

Future<GameDetectionState> _loadDetection(String id) async =>
    _useLibrary(await _libraryPath(), (library) => library.findDetection(id));

Future<Game> _changeEngine(String id, EngineChoice choice) async => _useLibrary(
  await _libraryPath(),
  (library) => library.selectEngine(
    id,
    automatic: choice.automatic,
    entryPoint: choice.entryPoint,
  ),
);

Future<T> _useLibrary<T>(String path, T Function(GameLibrary) operation) =>
    Isolate.run(() {
      final library = SqliteGameLibrary.open(path);
      try {
        return operation(library);
      } finally {
        library.close();
      }
    });

class VneApp extends StatelessWidget {
  const VneApp({
    super.key,
    required this.loadGames,
    this.importFolder,
    this.loadDetection,
    this.changeEngine,
  });

  final Future<List<Game>> Function() loadGames;
  final FolderImportAction? importFolder;
  final LoadDetection? loadDetection;
  final ChangeEngine? changeEngine;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'VNE',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff8b85e8),
        brightness: Brightness.dark,
      ),
    ),
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    locale: const Locale('es'),
    supportedLocales: const [Locale('es')],
    home: LibraryPage(
      loadGames: loadGames,
      importFolder: importFolder,
      loadDetection: loadDetection,
      changeEngine: changeEngine,
    ),
  );
}
