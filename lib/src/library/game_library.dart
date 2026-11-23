import '../core/game.dart';

abstract interface class GameLibrary {
  List<Game> listGames();
  Game? findGame(String id);
  void saveGame(Game game);
  bool removeGame(String id);
  GameSettings? findSettings(String gameId);
  void saveSettings(String gameId, GameSettings settings);
}
