import 'package:material_ui/material_ui.dart';

import '../core/game.dart';
import '../import/folder_game_importer.dart';
import '../import/game_importer.dart';

typedef FolderImportAction = Future<ImportResult?> Function(
  GameStorage storage,
  ImportCancellation cancellation,
  void Function(ImportProgress) onProgress,
);

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, required this.loadGames, this.importFolder});

  final Future<List<Game>> Function() loadGames;
  final FolderImportAction? importFolder;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  late Future<List<Game>> _games = widget.loadGames();
  String _query = '';
  ImportCancellation? _import;
  ImportProgress? _progress;
  bool _cancelRequested = false;

  Future<void> _startImport(FolderImportAction importFolder) async {
    final storage = await showDialog<GameStorage>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Importar carpeta'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, GameStorage.managedCopy),
            child: const ListTile(
              title: Text('Copiar a VNE'),
              subtitle: Text('Usa espacio adicional y conserva el original.'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () =>
                Navigator.pop(context, GameStorage.externalReference),
            child: const ListTile(
              title: Text('Referenciar carpeta'),
              subtitle: Text(
                'Mantén la carpeta en su ubicación y con acceso de lectura.',
              ),
            ),
          ),
        ],
      ),
    );
    if (storage == null || !mounted) return;
    final cancellation = ImportCancellation();
    setState(() => _import = cancellation);
    final ImportResult? result;
    try {
      result = await importFolder(storage, cancellation, (progress) {
        if (mounted) setState(() => _progress = progress);
      });
    } on Exception {
      if (mounted)
        _finishImport('No se pudo seleccionar o importar la carpeta.');
      return;
    }
    if (!mounted) return;
    switch (result) {
      case GameImported():
        _games = widget.loadGames();
        _query = '';
        _finishImport('Juego agregado a la biblioteca.');
      case ImportFailed(:final diagnostic):
        _finishImport(diagnostic.message);
      case ImportCancelled():
        _finishImport('Importación cancelada.');
      case EngineSelectionRequired():
        _finishImport('El juego requiere una selección de motor.');
      case null:
        _finishImport(null);
    }
  }

  void _finishImport(String? message) {
    setState(() {
      _import = null;
      _progress = null;
      _cancelRequested = false;
    });
    if (message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    _import?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Biblioteca'),
      actions: [
        if (widget.importFolder case final importFolder?)
          IconButton(
            tooltip: 'Importar carpeta',
            onPressed: _import != null
                ? null
                : () => _startImport(importFolder),
            icon: const Icon(Icons.create_new_folder_outlined),
          ),
      ],
    ),
    body: SafeArea(
      child: Column(
        children: [
          if (_import != null)
            _ImportStatus(
              progress: _progress,
              onCancel:
                  _cancelRequested || _progress?.phase == ImportPhase.publishing
                  ? null
                  : () {
                      _import?.cancel();
                      setState(() => _cancelRequested = true);
                    },
            ),
          Expanded(
            child: FutureBuilder<List<Game>>(
              future: _games,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(
                      semanticsLabel: 'Cargando juegos',
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No se pudo abrir la biblioteca.'),
                        TextButton(
                          onPressed: () {
                            final games = widget.loadGames();
                            setState(() {
                              _games = games;
                            });
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                final games = snapshot.requireData;
                if (games.isEmpty) {
                  return const Center(
                    child: Text('Aún no hay juegos en la biblioteca.'),
                  );
                }

                final matches = games
                    .where((game) => game.title.toLowerCase().contains(_query))
                    .toList(growable: false);
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Buscar juegos',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) =>
                            setState(() => _query = value.trim().toLowerCase()),
                      ),
                    ),
                    Expanded(
                      child: matches.isEmpty
                          ? const Center(
                              child: Text('No hay juegos que coincidan.'),
                            )
                          : ListView.builder(
                              itemCount: matches.length,
                              itemBuilder: (context, index) {
                                final game = matches[index];
                                return ListTile(
                                  title: Text(game.title),
                                  subtitle: Text(_runtimeStatus(game)),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => Navigator.of(context).push<void>(
                                    MaterialPageRoute(
                                      builder: (_) => _GameDetails(game: game),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _ImportStatus extends StatelessWidget {
  const _ImportStatus({required this.progress, required this.onCancel});

  final ImportProgress? progress;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final status = switch (progress) {
      (phase: ImportPhase.scanning, :final entries, bytes: _) =>
        'Inspeccionando · $entries entradas',
      (phase: ImportPhase.copying, :final entries, :final bytes) =>
        'Copiando · $entries entradas · ${(bytes / 1024 / 1024).toStringAsFixed(1)} MiB',
      (phase: ImportPhase.publishing, entries: _, bytes: _) =>
        'Guardando juego',
      null => 'Abriendo carpeta',
    };
    return Column(
      children: [
        const LinearProgressIndicator(),
        ListTile(
          title: Text(status),
          trailing: TextButton(
            onPressed: onCancel,
            child: const Text('Cancelar'),
          ),
        ),
      ],
    );
  }
}

String _runtimeStatus(Game game) => game.engineId == null
    ? 'Motor sin seleccionar'
    : 'Motor asignado · disponibilidad sin verificar';

class _GameDetails extends StatelessWidget {
  const _GameDetails({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(game.title)),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _runtimeStatus(game),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (game.engineId case final engine?)
            ListTile(title: const Text('Motor'), subtitle: Text(engine)),
          if (game.entryPoint case final entry?)
            ListTile(
              title: const Text('Punto de entrada'),
              subtitle: Text(entry),
            ),
          ListTile(
            title: const Text('Almacenamiento'),
            subtitle: Text(switch (game.source.storage) {
              GameStorage.externalReference => 'Referencia externa',
              GameStorage.managedCopy => 'Copia administrada',
            }),
          ),
        ],
      ),
    ),
  );
}
