import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vne/main.dart';
import 'package:vne/src/core/game.dart';

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
}
