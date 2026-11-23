# Arranque de VNE

## Preparación de Debian

Git, curl, unzip, xz-utils, zip y libglu1-mesa ya están presentes. Descarga una versión estable del SDK Flutter para Linux x64 desde el archivo oficial y extrae el tarball en una ruta de usuario. Flutter incluye Dart. Sustituye las rutas de ejemplo por las reales. El cambio de PATH de abajo dura solo la sesión de terminal. [Instalación manual de Flutter](https://docs.flutter.dev/install/manual)

```sh
tar -xf /ruta/al/archivo-del-sdk.tar.xz -C /ruta/de/instalacion
export PATH="/ruta/de/instalacion/flutter/bin:$PATH"
flutter --version
dart --version
```

Los siguientes comandos requieren autorización antes de ejecutarse. El primero actualiza los índices APT. El segundo aporta Clang para C/C++, CMake para configurar la compilación, Ninja para ejecutarla y las cabeceras de GTK 3 para el runner. Debian ya dispone de `pkg-config` mediante `pkgconf` y de las cabeceras de la biblioteca estándar de C++ mediante `libstdc++-14-dev`. [Requisitos de Flutter para Linux](https://docs.flutter.dev/platform-integration/linux/setup)

```sh
sudo apt update
sudo apt install clang cmake ninja-build libgtk-3-dev
```

Para Android, instala Android Studio o las herramientas oficiales de línea de comandos y usa un JDK compatible con el Gradle del proyecto generado. En SDK Manager selecciona la plataforma y Build Tools que pida la plantilla, Command-line Tools y Platform-Tools para obtener `adb`. Usa un dispositivo físico o instala el emulador si se necesita. CMake y NDK de Android se seleccionarán según las versiones que requiera el proyecto. [Configuración de Android para Flutter](https://docs.flutter.dev/platform-integration/android/setup)

```sh
flutter doctor --android-licenses
flutter doctor -v
flutter devices
```

## Arquitectura prevista

| Área | Responsabilidad |
| --- | --- |
| `android/`, `linux/` | Runners de Flutter y enlaces con APIs nativas cuando haga falta |
| `lib/src/app/`, `core/` | Navegación y composición de servicios, con modelos compartidos independientes de widgets |
| `lib/src/library/`, `storage/` | Biblioteca local, esquema y migraciones SQLite, rutas de datos por plataforma |
| `lib/src/import/`, `detection/` | Copia o referencia de fuentes locales, inspección acotada y detección con evidencia |
| `lib/src/engine_api/`, `engine_manager/` | Contrato versionado y catálogo de paquetes por plataforma y arquitectura |
| `lib/src/player/`, `engines/html5/` | Ciclo de vida del jugador y adaptador HTML5 |
| `lib/src/saves/`, `input/`, `diagnostics/` | Persistencia por juego, entrada y diagnóstico local cuando se integren |
| `test/`, `integration_test/` | Pruebas de dominio, interfaz e integración |

## Hitos y criterios de verificación

1. Generar los runners Flutter para Android y Linux, fijar la versión del SDK y compilar en Debian. Validar Linux en Debian y Android en un dispositivo o emulador.
2. Implementar SQLite y la biblioteca. Verificar que los registros sobreviven al reinicio y que una importación interrumpida mantiene un estado coherente.
3. Integrar selección local y detección. Verificar importación por referencia o copia, selección manual y rechazo de rutas inseguras. Añadir límites antes de admitir archivos comprimidos.
4. Implementar la API de motores y el gestor con catálogo local de demostración. Con una fuente de distribución verificada, validar confirmación explícita, descarga HTTPS verificable por SHA-256, cancelación, actualización y desinstalación. La publicación de paquetes reales sigue pendiente.
5. Implementar HTML5 con un adaptador por plataforma. Evaluar Android WebView y WebKitGTK; comprobar licencias y avisos antes de incorporar dependencias. Probar navegación restringida, recursos, audio, entrada, ciclo de vida, persistencia y aislamiento con contenido propio. HTML5 sigue siendo el único intérprete en alcance hasta completar los criterios de AGENT.md.

En Android, el selector puede entregar un URI de contenido y permisos revocables. La importación deberá resolverlos con APIs de almacenamiento de Android. El reproductor deberá aislar los datos de cada juego y controlar el acceso a archivos, navegación y red. SQLite y WebKitGTK ya tienen bibliotecas de ejecución en Debian, pero faltan sus paquetes de desarrollo. La necesidad de las cabeceras se decidirá con el enlace SQLite y el adaptador Linux elegidos.

## Primera verificación

Una vez disponible Dart, desde la raíz:

```sh
dart format lib/src/detection tool/check_html5_detector.dart
dart analyze lib/src/detection
dart run tool/check_html5_detector.dart
```

El detector busca un archivo regular `index.html` en la raíz y lee hasta 4096 bytes para reconocer una cabecera HTML. Puede devolver un candidato para una página común o pasar por alto juegos con otra entrada. La detección por firma se utiliza como evidencia para la importación.
