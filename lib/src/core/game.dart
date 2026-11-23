/// A URI can identify a filesystem location or a platform-managed document.
typedef GameSource = ({Uri uri, GameStorage storage});

enum GameStorage { externalReference, managedCopy }

typedef Game = ({
  String id,
  String title,
  GameSource source,
  String? engineId,
  String? entryPoint,
});

typedef GameSettings = ({bool fullscreen, String? preferredLocale});

/// The payload format and storage are private to the runtime.
typedef GameSave = ({
  String gameId,
  String engineId,
  String slotId,
  DateTime updatedAt,
});
