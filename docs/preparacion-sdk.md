# BLOQUE 2 · Preparación del entorno Flutter

Propuesta del 22 de noviembre de 2026, pendiente de autorización para ejecutar el BLOQUE 3.

## SDK de referencia

Reutilizar `/home/osorio/SDK/flutter` con Flutter **3.50.1 estable** (etiqueta local `3.50.1`, revisión `ae9b586f34`) y Dart **3.14.0**. La instalación existente ocupa 1,6 GiB. Flutter usa BSD de tres cláusulas según su archivo `LICENSE` e incluye Dart y componentes con sus respectivos avisos. Usar rutas absolutas evita editar perfiles de shell.

Si hace falta reproducir la instalación en otro equipo, elegir la misma versión para Linux x64 en el archivo oficial, verificar los datos de procedencia publicados y extraerla en una carpeta nueva de usuario. La instalación manual permite fijar versión y ubicación. El asistente de VS Code facilita la configuración interactiva. Para probar otra versión o volver a la anterior, ejecutar el binario de la carpeta correspondiente. [Archivo oficial](https://docs.flutter.dev/install/archive) · [Instalación manual](https://docs.flutter.dev/install/manual)

## Linux · preparar primero

| Paquete | Candidato APT local | Uso y licencia principal |
| --- | --- | --- |
| `clang` | `1:19.0-63` | Compilador C/C++ para el runner. LLVM usa Apache-2.0 con excepciones LLVM. |
| `cmake` | `3.31.6-2` | Configura la compilación nativa. BSD-3-Clause. |
| `ninja-build` | `1.12.1-1` | Ejecuta la compilación generada. Apache-2.0. |
| `libgtk-3-dev` | `3.24.49-3` | Cabeceras y metadatos de GTK 3. LGPL-2.1 o posterior. |

Los avisos completos están en los archivos de copyright de cada paquete Debian. `pkg-config` y las cabeceras de libstdc++ 14 ya están presentes, con validación final a cargo de Doctor. Las cabeceras de SQLite y WebKitGTK se evaluarán en sus bloques de integración. Chrome solo corresponde al destino web de Flutter.

La simulación con `--no-install-recommends` estimó 89 paquetes nuevos, 63,0 MB de descarga y 321 MB adicionales, sin actualizaciones ni eliminaciones. Los candidatos y tamaños pueden cambiar tras refrescar los índices. La guía oficial enumera el conjunto de herramientas del runner. [Flutter para Linux](https://docs.flutter.dev/platform-integration/linux/setup)

### Comandos propuestos para el BLOQUE 3

```sh
sudo apt update
apt-get -s --no-install-recommends install clang cmake ninja-build libgtk-3-dev
sudo apt install --no-install-recommends clang cmake ninja-build libgtk-3-dev
/home/osorio/SDK/flutter/bin/flutter --version
/home/osorio/SDK/flutter/bin/dart --version
/home/osorio/SDK/flutter/bin/flutter doctor -v
```

`apt update` refresca índices del sistema. Revisar la simulación antes de instalar y registrar la transacción de APT. Para una reversión autorizada, usar el historial de APT para identificar paquetes añadidos y simular su retirada con `apt-get -s remove` antes de decidir. Conservar los paquetes preexistentes y los que ahora requiera otro software. Flutter puede actualizar su caché local durante el diagnóstico.

## Android · autorización separada

Usar un SDK local, por ejemplo `/home/osorio/SDK/android`. Para compilar se necesitan un JDK compatible con el Gradle de la plantilla, Command-line Tools, SDK Platform y Build Tools. La plantilla del SDK Flutter instalado indica `compileSdk` 36 y NDK `28.2.13676358`. Seleccionar Platform-Tools para usar `adb` con un dispositivo físico. Reservar CMake de Android para las integraciones que lo requieran. Revisar el NDK con la plantilla antes de compilar y optar por emulador e imagen de sistema solo si se necesitan.

Android Studio integra el gestor de SDK y un JDK. Las herramientas de línea de comandos con un JDK compatible permiten preparar una instalación más pequeña. El espacio varía con el NDK, las imágenes y la caché de Gradle. Las descargas del SDK están sujetas a los términos de Android que el usuario debe revisar. [Flutter para Android](https://docs.flutter.dev/platform-integration/android/setup) · [Descargas y términos de Android](https://developer.android.com/studio)

Después de la autorización y de obtener las herramientas oficiales, estos comandos identifican los paquetes disponibles y preceden a la selección de Build Tools y NDK. Las variables se aplican a cada invocación. `sdkmanager --uninstall` permite retirar componentes específicos de ese SDK local.

```sh
/home/osorio/SDK/android/cmdline-tools/latest/bin/sdkmanager --sdk_root=/home/osorio/SDK/android --list
ANDROID_HOME=/home/osorio/SDK/android /home/osorio/SDK/flutter/bin/flutter doctor --android-licenses
ANDROID_HOME=/home/osorio/SDK/android /home/osorio/SDK/flutter/bin/flutter doctor -v
```
