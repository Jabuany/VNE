import 'package:material_ui/material_ui.dart';

import '../core/game.dart';
import '../detection/game_detector.dart';
import '../detection/web_game_detector.dart';
import '../engine_api/engine.dart';
import '../engine_manager/local_runtime_manager.dart';
import '../engine_manager/runtime_manager.dart';
import '../import/folder_game_importer.dart';
import '../import/game_importer.dart';
import '../library/game_library.dart';
import 'runtimes_page.dart';

typedef EngineChoice = ({bool automatic, String? entryPoint});
typedef LoadDetection = Future<GameDetectionState> Function(String id);
typedef ChangeEngine = Future<Game> Function(String id, EngineChoice choice);
typedef PlayGame = Future<void> Function(Game game);

typedef FolderImportAction = Future<ImportResult?> Function(
  GameStorage storage,
  ImportCancellation cancellation,
  void Function(ImportProgress) onProgress,
);

class LibraryPage extends StatefulWidget {
  const LibraryPage({
    super.key,
    required this.loadGames,
    this.importFolder,
    this.loadDetection,
    this.changeEngine,
    this.playGame,
    this.runtimes,
    this.canActivate,
  });

  final Future<List<Game>> Function() loadGames;
  final FolderImportAction? importFolder;
  final LoadDetection? loadDetection;
  final ChangeEngine? changeEngine;
  final PlayGame? playGame;
  final LocalRuntimeManager? runtimes;
  final Future<bool> Function()? canActivate;

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
        if (widget.runtimes case final manager?)
          IconButton(
            tooltip: 'Motores',
            icon: const Icon(Icons.settings_applications_outlined),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => RuntimesPage(
                  manager: manager,
                  canActivate: widget.canActivate,
                ),
              ),
            ),
          ),
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
                                      builder: (_) => _GameDetails(
                                        game: game,
                                        loadDetection: widget.loadDetection,
                                        changeEngine: widget.changeEngine,
                                        playGame: widget.playGame,
                                        onChanged: _refreshGames,
                                      ),
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

  void _refreshGames() {
    if (!mounted) return;
    final games = widget.loadGames();
    setState(() {
      _games = games;
    });
  }
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

class _GameDetails extends StatefulWidget {
  const _GameDetails({
    required this.game,
    required this.loadDetection,
    required this.changeEngine,
    required this.playGame,
    required this.onChanged,
  });

  final Game game;
  final LoadDetection? loadDetection;
  final ChangeEngine? changeEngine;
  final PlayGame? playGame;
  final VoidCallback onChanged;

  @override
  State<_GameDetails> createState() => _GameDetailsState();
}

class _GameDetailsState extends State<_GameDetails> {
  late Game game = widget.game;
  late Future<GameDetectionState>? _detection = widget.loadDetection?.call(
    game.id,
  );
  bool _saving = false;
  bool _playing = false;

  Future<void> _play(PlayGame playGame) async {
    setState(() => _playing = true);
    try {
      await playGame(game);
    } on RuntimeFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.diagnostic.message)));
      }
    } on RuntimeInstallFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.diagnostic.message)));
      }
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el reproductor.')),
        );
      }
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  Future<void> _chooseEngine(
    GameDetectionState detection,
    ChangeEngine changeEngine,
  ) async {
    final report = detection.report;
    final eligible =
        report?.htmlEntries ?? [if (game.entryPoint case final entry?) entry];
    final choice = await showDialog<EngineChoice>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Selección de motor'),
        children: [
          if (report != null)
            SimpleDialogOption(
              onPressed: () =>
                  Navigator.pop(context, (automatic: true, entryPoint: null)),
              child: const Text('Usar detección automática'),
            ),
          SimpleDialogOption(
            onPressed: () =>
                Navigator.pop(context, (automatic: false, entryPoint: null)),
            child: const Text('Dejar sin motor'),
          ),
          for (final entry in eligible)
            SimpleDialogOption(
              onPressed: () =>
                  Navigator.pop(context, (automatic: false, entryPoint: entry)),
              child: Text('HTML5 · $entry'),
            ),
        ],
      ),
    );
    if (!mounted || choice == null) return;
    setState(() => _saving = true);
    try {
      final updated = await changeEngine(game.id, choice);
      widget.onChanged();
      if (!mounted) return;
      setState(() {
        game = updated;
        _detection = Future.value((report: report, manual: !choice.automatic));
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar la selección.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(game.title)),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (game.engineId == 'html5' && game.entryPoint != null)
            if (widget.playGame case final play?)
              FilledButton(
                onPressed: _playing || _saving ? null : () => _play(play),
                child: const Text('Reproducir'),
              ),
          Text(
            _runtimeStatus(game),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (game.engineId case final engine?)
            ListTile(
              title: const Text('Motor'),
              subtitle: Text(
                engine == 'tyranoscript' ? 'TyranoScript' : engine,
              ),
            ),
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
          if (_detection case final detection?)
            FutureBuilder<GameDetectionState>(
              future: detection,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const ListTile(
                    title: Text('No se pudo leer la detección.'),
                  );
                }
                if (!snapshot.hasData) return const SizedBox.shrink();
                final state = snapshot.requireData;
                final report = state.report;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Divider(),
                    ListTile(
                      title: Text(
                        report == null
                            ? 'Sin informe de detección'
                            : switch (report.kind) {
                                WebContentKind.unknown =>
                                  'Contenido desconocido',
                                WebContentKind.genericHtml => 'HTML genérico',
                                WebContentKind.possibleWebGame =>
                                  'Posible juego web',
                                WebContentKind.identifiedWebEngine =>
                                  'Motor web identificado',
                              },
                      ),
                      subtitle: Text(
                        [
                          if (report == null)
                            'Importado antes de guardar evidencia'
                          else
                            'Detector v${report.version} · ${report.confidence == DetectionConfidence.candidate ? 'Candidato' : 'Inconcluso'}',
                          if (state.manual) 'Selección manual',
                        ].join(' · '),
                      ),
                    ),
                    if (report != null)
                      for (final item in report.evidence)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Text(item),
                        ),
                    if (widget.changeEngine case final change?)
                      TextButton(
                        onPressed: _saving || _playing
                            ? null
                            : () => _chooseEngine(state, change),
                        child: const Text('Cambiar motor'),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    ),
  );
}
