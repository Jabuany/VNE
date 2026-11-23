import '../core/game.dart';
import '../detection/web_game_detector.dart';

typedef GameDetectionState = ({WebDetection? report, bool manual});

abstract interface class GameLibrary {
  List<Game> listGames();
  Game? findGame(String id);
  void saveGame(Game game);
  void saveImportedGame(Game game, WebDetection report);
  GameDetectionState findDetection(String gameId);
  Game selectEngine(
    String gameId, {
    required bool automatic,
    String? entryPoint,
  });
  bool removeGame(String id);
  GameSettings? findSettings(String gameId);
  void saveSettings(String gameId, GameSettings settings);
}
