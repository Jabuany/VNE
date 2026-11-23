import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:vne/src/core/game.dart';
import 'package:vne/src/engine_api/engine.dart';
import 'package:vne/src/engine_manager/html5_catalog.dart';
import 'package:vne/src/engine_manager/local_runtime_manager.dart';
import 'package:vne/src/engine_manager/runtime_manager.dart';
import 'package:vne/src/engines/html5/linux_html5_adapter.dart';

const linux = (platform: RuntimePlatform.linux, architecture: 'x64');
const android = (platform: RuntimePlatform.android, architecture: 'arm64');

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('vne-engines-test-');
    addTearDown(() => directory.delete(recursive: true));
  });

  LocalRuntimeManager manager(
    RuntimeTarget target,
    List<RuntimeCatalogItem> entries,
  ) => LocalRuntimeManager(
    directory: () async => directory,
    target: target,
    entries: entries,
  );

  test(
    'installs the actual Linux helper and materializes only a verified copy',
    () async {
      final entries = html5Catalog(linux);
      final store = manager(linux, entries);
      final package = entries.single.package;
      final helper = File('runtime/html5/linux/player.py');
      expect(await store.installed(), isEmpty);
      await expectLater(
        store.withActive((_) async {}),
        throwsA(isA<RuntimeInstallFailure>()),
      );

      final operation = store.installFromFile(package, helper);
      final progress = operation.progress.toList();
      final installed = await operation.result;
      expect((await progress).last.state, RuntimeInstallState.installed);
      expect(installed.version, '0.1.0');
      final reopened = manager(linux, entries);
      final materialized = await reopened.withActive((path) async {
        expect(await File(path!).readAsBytes(), await helper.readAsBytes());
        await expectLater(
          reopened.uninstall(installed),
          throwsA(isA<RuntimeInstallFailure>()),
        );
        return path;
      });
      expect(await File(materialized).exists(), isFalse);
      final saves = File.fromUri(directory.uri.resolve('save-data.txt'));
      await saves.writeAsString('keep');
      await reopened.uninstall(installed);
      expect(await reopened.installed(), isEmpty);
      expect(await saves.readAsString(), 'keep');
    },
  );

  test('checks Android descriptor and persists opt-in separately', () async {
    final entries = html5Catalog(android);
    final store = manager(android, entries);
    final installed = await store.install(entries.single.package).result;
    expect(installed.target, android);
    final reopened = manager(android, entries);
    expect(await reopened.withActive((path) async => path), isNull);
    await reopened.uninstall(installed);
    expect(await reopened.installed(), isEmpty);
  });

  test(
    'cancel and integrity failure keep the previous active package',
    () async {
      final first = _item('1.0.0', 'original');
      final next = _item('1.1.0', 'updated!');
      final store = manager(linux, [next, first]);
      Future<File> file(String contents) =>
          File.fromUri(directory.uri.resolve('source')).writeAsString(contents);
      await store.installFromFile(first.package, await file('original')).result;

      final canceled = store.installFromFile(
        next.package,
        await file('updated!'),
      );
      await canceled.cancel();
      await expectLater(canceled.result, throwsA(_code('cancelled')));
      await expectLater(
        store.installFromFile(next.package, await file('tampered')).result,
        throwsA(_code('integrity')),
      );
      expect((await store.installed()).single.version, '1.0.0');
      expect(await store.previous(), isNull);
      await store.installFromFile(next.package, await file('updated!')).result;
      expect((await store.installed()).single.version, '1.1.0');
      expect((await store.previous())?.version, '1.0.0');
      await store.rollback();
      expect((await store.installed()).single.version, '1.0.0');
      expect((await store.previous())?.version, '1.1.0');
    },
  );

  test('launch rejects a corrupted runtime payload in the store', () async {
    final entries = html5Catalog(android);
    final store = manager(android, entries);
    await store.install(entries.single.package).result;
    final db = sqlite3.open(
      directory.uri.resolve('runtimes/html5.sqlite3').toFilePath(),
    );
    final size = entries.single.package.downloadBytes;
    db.execute('UPDATE packages SET payload = zeroblob(?) WHERE slot = 0', [
      size,
    ]);
    db.close();

    await expectLater(
      store.withActive((_) async => fail('corrupt package dispatched')),
      throwsA(_code('integrity')),
    );
  });

  test('filters architecture and rejects insecure remote origins', () {
    expect(
      html5Catalog((platform: RuntimePlatform.linux, architecture: 'arm64')),
      isEmpty,
    );
    expect(
      isSecureRuntimeUrl(Uri.parse('http://example.invalid/package')),
      isFalse,
    );
    expect(
      isSecureRuntimeUrl(Uri.parse('https://user@example.invalid/package')),
      isFalse,
    );
    expect(
      isSecureRuntimeUrl(Uri.parse('https://example.invalid/package')),
      isTrue,
    );
  });

  test('installed Linux package opens the sample inside the sandbox', () async {
    const url = String.fromEnvironment('VNE_TEST_PACKAGE_URL');
    final entries = html5Catalog(linux, linuxPackageUrl: url);
    final store = manager(linux, entries);
    final package = entries.single.package;
    await (url.isEmpty
            ? store.installFromFile(
                package,
                File('runtime/html5/linux/player.py'),
              )
            : store.install(package))
        .result;
    await store.withActive((helper) async {
      final session = await LinuxHtml5Adapter(helper!).launch((
        game: (
          id: 'a' * 32,
          title: 'Muestra',
          source: (
            uri: Directory('test/fixtures/html5').absolute.uri,
            storage: GameStorage.externalReference,
          ),
          engineId: 'html5',
          entryPoint: 'index.html',
        ),
        settings: (fullscreen: false, preferredLocale: null),
        privateDataDirectory: directory.uri.resolve('state/'),
      ));
      final events = session.events.toList();
      await Future<void>.delayed(const Duration(seconds: 3));
      await session.close();
      final emitted = await events;
      expect(
        emitted.any(
          (event) => event.diagnostic?.code == 'resource_unavailable',
        ),
        isTrue,
      );
      expect(emitted.last.kind, RuntimeEventKind.closed);
    });
    expect(await store.installed(), hasLength(1));
  }, skip: !const bool.fromEnvironment('VNE_TEST_LINUX_RUNTIME'));
}

Matcher _code(String code) => isA<RuntimeInstallFailure>().having(
  (error) => error.diagnostic.code,
  'code',
  code,
);

RuntimeCatalogItem _item(String version, String contents) {
  final bytes = utf8.encode(contents);
  return RuntimeCatalogItem(
    package: (
      engineId: 'html5',
      version: version,
      api: currentEngineApi,
      target: linux,
      downloadUri: Uri(path: 'test-package'),
      sha256: sha256.convert(bytes).toString(),
      downloadBytes: bytes.length,
      installedBytes: bytes.length,
      license: 'Test fixture',
    ),
    name: 'Test',
    origin: 'Generated test input',
    notes: '',
  );
}
