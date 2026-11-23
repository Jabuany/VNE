# Biblioteca local · BLOQUE 6

La pantalla inicial carga la biblioteca en un isolate. Muestra la lista, permite buscar por título y abre los detalles de cada juego. El estado del motor distingue una selección pendiente de un motor asignado cuya disponibilidad queda por verificar. La biblioteca empieza vacía y se llena mediante la importación de carpetas.

## Base de datos

El archivo `library.sqlite3` vive en el directorio de soporte de la aplicación que devuelve `path_provider`. En Linux se verificó la ruta `org.vne.vne/library.sqlite3` bajo `XDG_DATA_HOME`, que normalmente corresponde a `~/.local/share`. En Android queda en `files/library.sqlite3` dentro de los archivos privados de la aplicación. La base conserva URI de archivo o de documento Android y el modo de almacenamiento elegido. La URI por sí sola no concede acceso a un documento.

| Tabla evaluada | Decisión del esquema 2 |
| --- | --- |
| `games` | ID, título, URI, modo de almacenamiento, motor y punto de entrada opcionales. Índice por título e ID. |
| `game_settings` | Ajustes por juego con clave foránea y borrado en cascada. Actualizar un juego mantiene sus ajustes. |
| `game_detection` | Evidencia e informe de detección; se elimina con el registro del juego. Los juegos del esquema 1 se conservan sin informe. |
| `engines` | Se definirá con el catálogo. Un juego puede requerir un motor que todavía no esté instalado. |
| `game_saves` | Se definirá cuando el primer runtime exponga su almacenamiento. |
| `play_history` | Se definirá al integrar sesiones de reproducción. |

La conexión activa las claves foráneas y espera hasta un segundo ante un bloqueo. La creación de tablas e índices y el avance de `PRAGMA user_version` se ejecutan en una sola transacción. Una base con una versión posterior se rechaza sin migrarla. Para cambios futuros, probar por separado cada transición desde una versión publicada y conservar una copia antes de actualizar.

## Respaldo

En Linux, cierra VNE y copia `library.sqlite3` a una ubicación privada después de confirmar que no haya otra instancia abierta. Para restaurar, conserva una copia del estado actual y sustituye el archivo con VNE cerrado y con una versión de la aplicación compatible con el esquema. En Android, la base está en el almacenamiento privado y VNE aún no ofrece exportación ni restauración.

La base registra referencias y ajustes. Respalda también los archivos de los juegos y sus guardados por separado. Las referencias externas pueden requerir seleccionar de nuevo su ubicación o conceder acceso en el dispositivo de destino.

## Dependencias

- `sqlite3` 3.9.2 empaqueta SQLite con la aplicación y usa FFI en Android y Linux. El enlace al SQLite del sistema reduciría el paquete en Linux y complicaría mantener una misma versión en ambos destinos. [Paquete sqlite3](https://pub.dev/packages/sqlite3) · [SQLite](https://sqlite.org/copyright.html)
- `path_provider` 2.1.6 resuelve directorios privados o de soporte según plataforma. La alternativa es mantener implementaciones propias para XDG y Android. [Paquete path_provider](https://pub.dev/packages/path_provider)
- `material_ui` 1.11.1 aporta búsqueda, navegación y controles accesibles en ambas plataformas. La alternativa es componer controles y accesibilidad con los widgets de bajo nivel del SDK. [Paquete material_ui](https://pub.dev/packages/material_ui)

Consulta `THIRD_PARTY_NOTICES` para los avisos de las dependencias directas.

En esta compilación, `libsqlite3.so` ocupó 1,74 MiB en Linux x64. El APK de depuración con tres arquitecturas aumentó unos 37,1 MiB respecto al BLOQUE 4 por el conjunto de dependencias y recursos. Gradle descargó Android Platform 35, revisión 2, y CMake 3.22.1 dentro del SDK local para compilar dependencias. El APK conserva API 36 como destino.
