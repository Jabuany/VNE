import 'package:material_ui/material_ui.dart';

import '../core/game.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, required this.loadGames});

  final Future<List<Game>> Function() loadGames;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  late Future<List<Game>> _games = widget.loadGames();
  String _query = '';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Biblioteca')),
    body: SafeArea(
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
                    ? const Center(child: Text('No hay juegos que coincidan.'))
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
  );
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
