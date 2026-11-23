import 'package:flutter/services.dart';

import 'import_tree.dart';

final class AndroidImportTree implements ImportTree {
  AndroidImportTree._(this.source, this.root, this.title);

  static const _channel = MethodChannel('org.vne.vne/import_tree');

  static Future<Uri?> pick() async {
    final source = await _channel.invokeMethod<String>('pick');
    return source == null ? null : Uri.parse(source);
  }

  static Future<AndroidImportTree> open(Uri source) async {
    final info = (await _channel.invokeMapMethod<String, String>('root', {
      'source': source.toString(),
    }))!;
    return AndroidImportTree._(source, info['id']!, info['name']!);
  }

  final Uri source;
  @override
  final String root;
  @override
  final String title;

  Map<String, Object> _arguments([String? id]) => {
    'source': source.toString(),
    if (id != null) 'id': id,
  };

  @override
  Stream<TreeEntry> children(String directory) async* {
    final rows = (await _channel.invokeListMethod<Map<Object?, Object?>>(
      'children',
      _arguments(directory),
    ))!;
    for (final row in rows) {
      yield (
        id: row['id'] as String,
        name: row['name'] as String,
        isDirectory: row['directory'] as bool,
        size: row['size'] as int?,
      );
    }
  }

  @override
  Stream<List<int>> read(String file, {int? limit}) async* {
    await _channel.invokeMethod<void>('open', _arguments(file));
    var read = 0;
    try {
      while (limit == null || read < limit) {
        final chunk = (await _channel.invokeMethod<Uint8List>('read', {
          'size': limit == null ? 65536 : limit - read,
        }))!;
        if (chunk.isEmpty) break;
        read += chunk.length;
        yield chunk;
      }
    } finally {
      await _channel.invokeMethod<void>('closeFile');
    }
  }

  @override
  Future<void> retainReference() =>
      _channel.invokeMethod<void>('retain', _arguments());

  @override
  Future<void> close() async {}
}
