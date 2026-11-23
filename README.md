# VNE · Visual Novel Engine

Reproductor en desarrollo para novelas visuales y juegos narrativos locales en Android y Linux. El primer runtime previsto es HTML5.

La reproducción en ambas plataformas está pendiente.

La biblioteca local guarda sus datos en SQLite. La pantalla inicial ofrece búsqueda y detalles de los juegos registrados.

Usa **Importar carpeta** para copiar un juego local o referenciar su ubicación original. VNE inspecciona el contenido para detectar un candidato HTML5.

## Compilación y pruebas

La aplicación Flutter está en la raíz. Usa Flutter 3.50.1 estable y Dart 3.14.0. En los ejemplos, `flutter` y `dart` se pueden invocar por ruta absoluta desde `/home/osorio/SDK/flutter/bin/`.

```sh
flutter pub get
flutter analyze
flutter test
dart run tool/check_html5_detector.dart
flutter build linux --debug
flutter run -d linux
```

Para Android, usa el SDK local y el JDK con variables de la sesión. El APK de depuración se genera en `build/app/outputs/flutter-apk/app-debug.apk`.

```sh
export JAVA_HOME=/home/osorio/SDK/temurin-21.0.13.1
export ANDROID_HOME=/home/osorio/SDK/android
flutter build apk --debug
flutter devices
flutter run -d ID_DEL_DISPOSITIVO
```

Conecta un teléfono con depuración USB y autoriza la computadora en el dispositivo antes de ejecutar el último comando.

Si el teléfono bloquea la instalación por USB, desbloquéalo, habilita **Instalar mediante USB** en las opciones de desarrollador si está disponible y confirma la instalación en pantalla.

- [Estado y continuidad](CURRENT_STATUS.md)
- [Entorno, arquitectura y plan](docs/arranque.md)
- [Contratos del Core](docs/core.md)
- [Biblioteca, migraciones y respaldo](docs/biblioteca.md)
- [Importación local y límites](docs/importacion.md)
- [Detección web y selección de motor](docs/deteccion.md)
- [Evaluación del runtime HTML5](docs/runtime-html5.md)
- [Preparación del SDK](docs/preparacion-sdk.md)
