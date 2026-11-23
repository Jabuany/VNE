import 'dart:io';
import 'dart:isolate';

import 'package:file_selector_linux/file_selector_linux.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import 'src/app/library_page.dart';
import 'src/core/game.dart';
import 'src/import/android_import_tree.dart';
import 'src/import/folder_game_importer.dart';
import 'src/import/game_importer.dart';
import 'src/import/linux_import_tree.dart';
import 'src/storage/sqlite_game_library.dart';

void main() {
  runApp(VneApp(loadGames: _loadGames, importFolder: _importFolder));
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
    publish: (game) => _saveGame(databasePath, game),
    cancellation: cancellation,
    onProgress: onProgress,
  );
  return importer.importGame((
    source: source,
    storage: storage,
    selectedEngineId: null,
  ));
}

Future<void> _saveGame(String path, Game game) => Isolate.run(() {
  final library = SqliteGameLibrary.open(path);
  try {
    library.saveGame(game);
  } finally {
    library.close();
  }
});

Future<List<Game>> _loadGames() async {
  final directory = await getApplicationSupportDirectory();
  await directory.create(recursive: true);
  final path = directory.uri.resolve('library.sqlite3').toFilePath();
  return Isolate.run(() {
    final library = SqliteGameLibrary.open(path);
    try {
      return library.listGames();
    } finally {
      library.close();
    }
  });
}

class VneApp extends StatelessWidget {
  const VneApp({super.key, required this.loadGames, this.importFolder});

  final Future<List<Game>> Function() loadGames;
  final FolderImportAction? importFolder;

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
    home: LibraryPage(loadGames: loadGames, importFolder: importFolder),
  );
}
