import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'import_tree.dart';

final class LinuxImportTree implements ImportTree {
  LinuxImportTree._(this._rootFd, this.title);

  static Future<LinuxImportTree> open(Uri source, Directory managedRoot) async {
    final path = source.toFilePath();
    final fd = _open(-100, path, _noSymlinks);
    try {
      final descriptor = Directory(_fdPath(fd));
      if ((await FileStat.stat(descriptor.path)).type !=
          FileSystemEntityType.directory) {
        throw const FileSystemException('Se requiere una carpeta.');
      }
      final canonical = await descriptor.resolveSymbolicLinks();
      final managed = await managedRoot.resolveSymbolicLinks();
      if (canonical == '/' ||
          canonical == managed ||
          managed.startsWith('$canonical/') ||
          canonical.startsWith('$managed/')) {
        throw const FileSystemException(
          'Selecciona una carpeta fuera del almacenamiento de VNE.',
        );
      }
      return LinuxImportTree._(fd, canonical.split('/').last);
    } catch (_) {
      _close(fd);
      rethrow;
    }
  }

  final int _rootFd;

  @override
  final String title;

  @override
  String get root => '.';

  String _relative(String directory, String name) =>
      directory == root ? name : '$directory/$name';

  int _openChild(String path) =>
      _open(_rootFd, path, _noSymlinks | _beneath | _noMountCrossing);

  @override
  Stream<TreeEntry> children(String directory) async* {
    final fd = _openChild(directory);
    try {
      if ((await FileStat.stat(_fdPath(fd))).type !=
          FileSystemEntityType.directory) {
        throw const FileSystemException('La carpeta de origen cambió.');
      }
      await for (final item in Directory(
        _fdPath(fd),
      ).list(followLinks: false)) {
        final name = item.path.split('/').last;
        final relative = _relative(directory, name);
        final child = _openChild(relative);
        final FileStat stat;
        try {
          stat = await FileStat.stat(_fdPath(child));
        } finally {
          _close(child);
        }
        final type = stat.mode & 0xf000;
        if (type != _regularFile && type != _directory) {
          throw const FileSystemException(
            'La carpeta contiene un archivo especial.',
          );
        }
        yield (
          id: relative,
          name: name,
          isDirectory: type == _directory,
          size: stat.size,
        );
      }
    } finally {
      _close(fd);
    }
  }

  @override
  Stream<List<int>> read(String file, {int? limit}) async* {
    final fd = _openChild(file);
    try {
      final path = _fdPath(fd);
      if ((await FileStat.stat(path)).mode & 0xf000 != _regularFile) {
        throw const FileSystemException('El archivo de origen cambió.');
      }
      yield* File(path).openRead(0, limit);
    } finally {
      _close(fd);
    }
  }

  @override
  Future<void> retainReference() async {}

  @override
  Future<void> close() async {
    _close(_rootFd);
  }
}

final class _OpenHow extends Struct {
  @Uint64()
  external int flags;
  @Uint64()
  external int mode;
  @Uint64()
  external int resolve;
}

const _noMountCrossing = 0x01;
const _noSymlinks = 0x04;
const _beneath = 0x08;
const _directory = 0x4000;
const _regularFile = 0x8000;
const _openPath = 0x200000;
const _closeOnExec = 0x80000;

final _libc = DynamicLibrary.process();
final _syscall = _libc
    .lookupFunction<
      Long Function(Long, Int, Pointer<Utf8>, Pointer<_OpenHow>, Size),
      int Function(int, int, Pointer<Utf8>, Pointer<_OpenHow>, int)
    >('syscall');
final _close = _libc.lookupFunction<Int Function(Int), int Function(int)>(
  'close',
);

String _fdPath(int fd) => '/proc/self/fd/$fd';

int _open(int parent, String path, int resolve) {
  final abi = Abi.current();
  if (abi != Abi.linuxX64 && abi != Abi.linuxArm64) {
    throw UnsupportedError('La importación segura requiere Linux x64 o arm64.');
  }
  if (path.contains('\u0000')) {
    throw const FileSystemException('Ruta de origen inválida.');
  }
  final nativePath = path.toNativeUtf8();
  final how = calloc<_OpenHow>();
  try {
    // openat2 (437) on Linux x64 and arm64. O_PATH opens no device or FIFO.
    how.ref
      ..flags = _openPath | _closeOnExec
      ..resolve = resolve;
    final fd = _syscall(437, parent, nativePath, how, sizeOf<_OpenHow>());
    if (fd < 0) {
      throw const FileSystemException(
        'No se pudo abrir el origen sin seguir enlaces ni cruzar montajes.',
      );
    }
    return fd;
  } finally {
    calloc.free(how);
    calloc.free(nativePath);
  }
}
