import 'dart:async';
import 'dart:io';

import 'package:file_selector_linux/file_selector_linux.dart';
import 'package:material_ui/material_ui.dart';

import '../engine_manager/html5_catalog.dart';
import '../engine_manager/local_runtime_manager.dart';
import '../engine_manager/runtime_manager.dart';

class RuntimesPage extends StatefulWidget {
  const RuntimesPage({super.key, required this.manager, this.canActivate});

  final LocalRuntimeManager manager;
  final Future<bool> Function()? canActivate;

  @override
  State<RuntimesPage> createState() => _RuntimesPageState();
}

class _RuntimesPageState extends State<RuntimesPage> {
  late Future<({InstalledRuntime? active, InstalledRuntime? previous})> _state =
      _read();
  RuntimeInstallation? _installation;
  RuntimeInstallProgress? _progress;
  String? _error;
  bool _busy = false;

  Future<({InstalledRuntime? active, InstalledRuntime? previous})>
  _read() async {
    final installed = await widget.manager.installed();
    final previous = await widget.manager.previous();
    return (active: installed.firstOrNull, previous: previous);
  }

  Future<void> _install(RuntimeCatalogItem item) async {
    final package = item.package;
    final approved = await _confirm(
      item.bundledDescriptor != null ? 'Activar HTML5' : 'Instalar HTML5',
      'Origen: ${item.origin}\n'
      'Descarga de red: ${item.remote ? _size(package.downloadBytes) : '0 B'}\n'
      'Espacio del paquete: ${_size(package.installedBytes)} más metadatos\n'
      'Licencia: ${package.license}',
    );
    if (!approved || !mounted) return;
    await _run(() async {
      if (widget.canActivate case final available?) {
        if (!await available()) {
          throw const _UiFailure(
            'Se requiere una compilación Android offline y un WebView con perfiles aislados.',
          );
        }
      }
      if (!mounted) return;
      final RuntimeInstallation operation;
      if (item.needsFile) {
        final selected = await FileSelectorLinux().openFile();
        if (selected == null || !mounted) return;
        operation = widget.manager.installFromFile(
          package,
          File(selected.path),
        );
      } else {
        operation = widget.manager.install(package);
      }
      setState(() => _installation = operation);
      final subscription = operation.progress.listen((value) {
        if (mounted) setState(() => _progress = value);
      });
      try {
        await operation.result;
      } finally {
        await subscription.cancel();
      }
    });
  }

  Future<void> _run(Future<void> Function() operation) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await operation();
    } on RuntimeInstallFailure catch (error) {
      _error = error.diagnostic.message;
    } on _UiFailure catch (error) {
      _error = error.message;
    } on Exception {
      _error = 'No se pudo completar la operación con el motor.';
    } finally {
      if (mounted) {
        final next = _read();
        setState(() {
          _state = next;
          _installation = null;
          _progress = null;
          _busy = false;
        });
      }
    }
  }

  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ) ??
      false;

  @override
  void dispose() {
    if (_installation case final operation?) unawaited(operation.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Motores')),
    body: SafeArea(
      child: FutureBuilder(
        future: _state,
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(
              child: Text('No se pudo leer el estado del motor.'),
            );
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          if (widget.manager.entries.isEmpty)
            return const Center(
              child: Text('No hay motores para este dispositivo.'),
            );
          final item = widget.manager.entries.first;
          final package = item.package;
          final (active: active, previous: previous) = snapshot.requireData;
          final updateAvailable =
              active != null &&
              active.version != package.version &&
              previous?.version != package.version;
          final progress = _progress;
          final installLabel = updateAvailable
              ? 'Actualizar'
              : item.bundledDescriptor != null
              ? 'Activar'
              : 'Instalar';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(item.name, style: Theme.of(context).textTheme.headlineSmall),
              Text(
                active == null ? 'Sin instalar' : 'Activo · ${active.version}',
              ),
              const SizedBox(height: 12),
              Text(
                'Paquete ${package.version} · API ${package.api.major}.${package.api.minor}',
              ),
              Text(
                '${package.target.platform.name} · ${package.target.architecture}',
              ),
              Text('Origen: ${item.origin}'),
              Text(
                'Tamaño: ${_size(package.downloadBytes)} · espacio estimado: ${_size(package.installedBytes)} más metadatos',
              ),
              Text(package.license),
              Text(item.notes),
              const SizedBox(height: 8),
              SelectableText('SHA-256 ${package.sha256}'),
              if (_error case final error?)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(error),
                ),
              if (progress != null) ...[
                LinearProgressIndicator(
                  value: progress.state == RuntimeInstallState.downloading
                      ? progress.downloadedBytes / package.downloadBytes
                      : null,
                ),
                Text(switch (progress.state) {
                  RuntimeInstallState.downloading =>
                    item.remote ? 'Descargando paquete' : 'Leyendo paquete',
                  RuntimeInstallState.verifying => 'Verificando SHA-256',
                  RuntimeInstallState.installing => 'Guardando el motor',
                  RuntimeInstallState.installed => 'Motor activo',
                }),
              ],
              if (_installation != null &&
                  (progress == null ||
                      progress.state == RuntimeInstallState.downloading ||
                      progress.state == RuntimeInstallState.verifying))
                TextButton(
                  onPressed: () => _installation?.cancel(),
                  child: const Text('Cancelar instalación'),
                ),
              const SizedBox(height: 8),
              if (active == null || updateAvailable)
                FilledButton(
                  onPressed: _busy ? null : () => _install(item),
                  child: Text(_error == null ? installLabel : 'Reintentar'),
                ),
              if (previous != null)
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          if (await _confirm(
                                'Cambiar versión',
                                'Activar la versión guardada ${previous.version}.',
                              ) &&
                              mounted) {
                            await _run(widget.manager.rollback);
                          }
                        },
                  child: Text('Cambiar a ${previous.version}'),
                ),
              if (active != null)
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          final bytes =
                              active.installedBytes +
                              (previous?.installedBytes ?? 0);
                          if (await _confirm(
                                'Desinstalar HTML5',
                                'Se retirarán las versiones guardadas (${_size(bytes)} de datos del motor). Tus juegos y partidas se conservan.',
                              ) &&
                              mounted) {
                            await _run(() => widget.manager.uninstall(active));
                          }
                        },
                  child: const Text('Desinstalar'),
                ),
            ],
          );
        },
      ),
    ),
  );
}

String _size(int bytes) =>
    bytes < 1024 ? '$bytes B' : '${(bytes / 1024).toStringAsFixed(1)} KiB';

final class _UiFailure implements Exception {
  const _UiFailure(this.message);
  final String message;
}
