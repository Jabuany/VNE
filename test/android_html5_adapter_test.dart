import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vne/src/core/game.dart';
import 'package:vne/src/engine_api/engine.dart';
import 'package:vne/src/engines/html5/android_html5_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('org.vne.vne/html5');
  const codec = StandardMethodCodec();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final RuntimeLaunch request = (
    game: (
      id: 'a' * 32,
      title: 'Muestra',
      source: (
        uri: Uri.parse('file:///private/games/game-test/'),
        storage: GameStorage.managedCopy,
      ),
      engineId: 'html5',
      entryPoint: 'index.html',
    ),
    settings: (fullscreen: false, preferredLocale: null),
    privateDataDirectory: Uri.parse('file:///private/data/'),
  );

  Future<void> emit(String kind, Map<String, Object> data) async {
    await messenger.handlePlatformMessage(
      channel.name,
      codec.encodeMethodCall(MethodCall(kind, data)),
      (_) {},
    );
  }

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    channel.setMethodCallHandler(null);
  });

  test('routes lifecycle commands and closes only once', () async {
    final methods = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      methods.add(call.method);
      final arguments = call.arguments as Map;
      final token = arguments['token'] as int;
      if (call.method == 'launch') {
        expect(arguments['entryPoint'], 'index.html');
        expect(arguments['managed'], isTrue);
      }
      if (call.method == 'close') await emit('closed', {'token': token});
      return null;
    });
    final adapter = AndroidHtml5Adapter();
    final session = await adapter.launch(request);
    final events = session.events.toList();
    await expectLater(adapter.launch(request), throwsA(isA<RuntimeFailure>()));
    await emit('closed', {'token': 999});
    await session.pauseControl!.pause();
    await session.pauseControl!.resume();
    await session.close();
    await session.close();
    expect(methods, ['launch', 'pause', 'resume', 'close']);
    expect((await events).single.kind, RuntimeEventKind.closed);
    expect(session.saveControl, isNull);
  });

  test('launch errors are typed and release the adapter', () async {
    var attempts = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'launch' && ++attempts == 1) {
        throw PlatformException(
          code: 'entry_load_failed',
          message: 'Entrada ausente',
        );
      }
      if (call.method == 'close') {
        await emit('closed', {
          'token': (call.arguments as Map)['token'] as int,
        });
      }
      return null;
    });
    final adapter = AndroidHtml5Adapter();
    await expectLater(
      adapter.launch(request),
      throwsA(
        isA<RuntimeFailure>().having(
          (error) => error.diagnostic.code,
          'code',
          'entry_load_failed',
        ),
      ),
    );
    final session = await adapter.launch(request);
    await session.close();
  });
}
