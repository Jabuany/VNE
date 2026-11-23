import 'dart:isolate';

import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import 'src/app/library_page.dart';
import 'src/core/game.dart';
import 'src/storage/sqlite_game_library.dart';

void main() {
  runApp(VneApp(loadGames: _loadGames));
}

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
  const VneApp({super.key, required this.loadGames});

  final Future<List<Game>> Function() loadGames;

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
    home: LibraryPage(loadGames: loadGames),
  );
}
