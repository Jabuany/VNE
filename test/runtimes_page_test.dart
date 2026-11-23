import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vne/main.dart';
import 'package:vne/src/engine_manager/html5_catalog.dart';
import 'package:vne/src/engine_manager/local_runtime_manager.dart';
import 'package:vne/src/engine_manager/runtime_manager.dart';

void main() {
  testWidgets('shows package details and requires confirmation to activate', (
    tester,
  ) async {
    const target = (platform: RuntimePlatform.android, architecture: 'arm64');
    final directory = Directory.systemTemp.createTempSync('vne-engines-ui-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final manager = LocalRuntimeManager(
      target: target,
      directory: () async => directory,
      entries: html5Catalog(target),
    );
    await tester.pumpWidget(
      VneApp(
        loadGames: () async => [],
        runtimes: manager,
        canActivate: () async => true,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Motores'));
    await _waitFor(tester, find.text('Activar'));
    await tester.tap(find.text('Activar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Descarga de red: 0 B'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(await tester.runAsync(manager.installed), isEmpty);
    await tester.tap(find.text('Activar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await _waitFor(tester, find.text('Activo · 0.1.0'));
    expect(await tester.runAsync(manager.installed), hasLength(1));
  });
}

Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(finder, findsOneWidget);
  await tester.pumpAndSettle();
}
