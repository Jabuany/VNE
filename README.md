# VNE · Visual Novel Engine

Reproductor en desarrollo para novelas visuales y juegos narrativos locales en Android y Linux. El primer runtime previsto es HTML5.

El código inicial inspecciona el archivo `index.html` de una carpeta y devuelve evidencia de una posible entrada HTML5. La reproducción en ambas plataformas está pendiente.

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

- [Estado y continuidad](CURRENT_STATUS.md)
- [Entorno, arquitectura y plan](docs/arranque.md)
- [Preparación del SDK](docs/preparacion-sdk.md)
