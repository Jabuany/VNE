import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vne/main.dart';
import 'package:vne/src/core/game.dart';
import 'package:vne/src/detection/game_detector.dart';
import 'package:vne/src/detection/web_game_detector.dart';
import 'package:vne/src/import/game_importer.dart';

void main() {
  testWidgets('shows an empty library at launch', (tester) async {
    await tester.pumpWidget(VneApp(loadGames: () async => []));
    await tester.pumpAndSettle();

    expect(find.text('Biblioteca'), findsOneWidget);
    expect(find.text('Aún no hay juegos en la biblioteca.'), findsOneWidget);
  });

  testWidgets('filters titles and opens game details', (tester) async {
    final Game game = (
      id: 'one',
      title: 'Árbol',
      source: (uri: Uri.directory('/local'), storage: GameStorage.managedCopy),
      engineId: 'html5',
      entryPoint: 'index.html',
    );
    await tester.pumpWidget(VneApp(loadGames: () async => [game]));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'otro');
    await tester.pumpAndSettle();
    expect(find.text('No hay juegos que coincidan.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ÁRB');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Árbol'));
    await tester.pumpAndSettle();
    expect(find.text('html5'), findsOneWidget);
    expect(find.text('index.html'), findsOneWidget);
    expect(find.text('Copia administrada'), findsOneWidget);
  });

  testWidgets('can retry after the database fails to open', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      VneApp(
        loadGames: () async {
          attempts++;
          if (attempts == 1) throw StateError('Database unavailable');
          return [];
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No se pudo abrir la biblioteca.'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Aún no hay juegos en la biblioteca.'), findsOneWidget);
  });

  testWidgets('import offers both modes and reloads the library on success', (
    tester,
  ) async {
    GameStorage? selected;
    final games = <Game>[];
    await tester.pumpWidget(
      VneApp(
        loadGames: () async => List.of(games),
        importFolder: (storage, cancellation, onProgress) async {
          selected = storage;
          final Game game = (
            id: 'imported',
            title: 'Novela local',
            source: (uri: Uri.directory('/novela'), storage: storage),
            engineId: 'html5',
            entryPoint: 'index.html',
          );
          games.add(game);
          return GameImported(game);
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Importar carpeta'));
    await tester.pumpAndSettle();
    expect(find.text('Copiar a VNE'), findsOneWidget);
    await tester.tap(find.text('Referenciar carpeta'));
    await tester.pumpAndSettle();

    expect(selected, GameStorage.externalReference);
    expect(find.text('Novela local'), findsOneWidget);
  });

  testWidgets('details preserve detection evidence while changing motor', (
    tester,
  ) async {
    Game game = (
      id: 'detection',
      title: 'Inicio',
      source: (uri: Uri.directory('/local'), storage: GameStorage.managedCopy),
      engineId: null,
      entryPoint: null,
    );
    final report = WebDetection(
      version: 1,
      kind: WebContentKind.genericHtml,
      confidence: DetectionConfidence.inconclusive,
      suggestedEngineId: null,
      entryPoint: null,
      htmlEntries: ['inicio.htm', 'menu.html'],
      evidence: ['Hay varias entradas HTML.'],
    );
    await tester.pumpWidget(
      VneApp(
        loadGames: () async => [game],
        loadDetection: (_) async => (report: report, manual: false),
        changeEngine: (_, choice) async {
          expect(choice.automatic, isFalse);
          expect(choice.entryPoint, 'inicio.htm');
          game = (
            id: game.id,
            title: game.title,
            source: game.source,
            engineId: 'html5',
            entryPoint: choice.entryPoint,
          );
          return game;
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();
    expect(find.text('HTML genérico'), findsOneWidget);
    expect(find.text('Hay varias entradas HTML.'), findsOneWidget);
    await tester.tap(find.text('Cambiar motor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('HTML5 · inicio.htm'));
    await tester.pumpAndSettle();
    expect(find.text('inicio.htm'), findsOneWidget);
    expect(
      find.text('Detector v1 · Inconcluso · Selección manual'),
      findsOneWidget,
    );
    expect(find.text('Hay varias entradas HTML.'), findsOneWidget);
  });
}
