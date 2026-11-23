# Estado actual de VNE

## Punto de control vigente · BLOQUE 4 · 2026-11-22

- **Validación final en Android.** En el siguiente reintento, `adb -d install -r` instaló el APK correctamente en el teléfono con Android 15 (API 35). `adb shell am start -W` confirmó arranque en frío con estado `ok`. `pidof` confirmó el proceso y `dumpsys activity activities` mostró `MainActivity` en primer plano. Queda validado el arranque de la aplicación mínima en Android y Linux. El BLOQUE 5 sigue pendiente de autorización.

- **Reverificación con teléfono.** Android 15 (API 35) detectado y autorizado en ADB. Se recompiló el APK y se verificó su firma. Dos intentos con `adb -d install -r build/app/outputs/flutter-apk/app-debug.apk` fallaron con `INSTALL_FAILED_USER_RESTRICTED: Install canceled by user`. `adb shell pm path org.vne.vne` no encontró el paquete. No se pudo probar el arranque en Android. Se documentó cómo habilitar la instalación por USB o continuar con el APK manualmente.
- **Reverificación en Debian.** `flutter analyze --no-pub`, `flutter test --no-pub`, las tres comprobaciones del detector y `flutter build linux --debug --no-pub` aprobaron. La traza Wayland volvió a confirmar título VNE y fotogramas. Sin cambios de código ni dependencias.

- **Etapa y avances.** Aplicación Flutter mínima en la raíz, con runners oficiales de Android y Linux. La pantalla de arranque muestra VNE. El detector HTML5 existente y sus comprobaciones se incorporaron al repositorio sin cambiar su contenido. La auditoría del detector conserva sus hallazgos pendientes.
- **Archivos.** Creados `android/`, `linux/`, `lib/main.dart`, `test/widget_test.dart`, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `.gitignore` y `.metadata`. Actualizados `README.md` y este registro. Sin archivos del proyecto eliminados.
- **Dependencias y decisiones.** Flutter 3.50.1 y Dart 3.14.0. Se usaron `widgets.dart` y `flutter_test` del SDK, y se retiraron las dependencias directas de la plantilla que la aplicación mínima no necesita. Identificador Android provisional `org.vne.vne`. Se descargaron artefactos de compilación Flutter y dependencias Gradle de la plantilla. Sin paquetes del sistema ni cambios globales.
- **Pruebas comunes.** `flutter analyze` y `flutter test` aprobados. El análisis inicial encontró un constructor `const` incorrecto, corregido antes del reintento. Las tres comprobaciones de `dart --disable-analytics run tool/check_html5_detector.dart` aprobaron.
- **Linux.** `flutter build linux --debug --no-pub` aprobó en Debian 13.8 amd64. El ejecutable abrió una ventana con título VNE y envió fotogramas a Wayland. El proceso se cerró al final de la comprobación de arranque.
- **Android.** `flutter build apk --debug --no-pub` aprobó con API 36 y Temurin 21. APK en `build/app/outputs/flutter-apk/app-debug.apk`. Se verificaron su firma de depuración y el manifiesto, con Android mínimo API 24. `adb devices` no detectó un teléfono. La ejecución física sigue pendiente.
- **Siguiente tarea.** BLOQUE 5 sujeto a autorización expresa para trabajar en contratos del Core. Para validar Android en un teléfono, conectarlo con depuración USB y autorizar la computadora.

## Preparación de Android · 2026-11-22

- **Alcance autorizado.** Preparar un SDK local con herramientas de línea de comandos y usar un teléfono físico para las pruebas.
- **JDK instalado y verificado.** Eclipse Temurin 21.0.13.1+2 en `/home/osorio/SDK/temurin-21.0.13.1`. SHA-256 cotejado con el publicado por Adoptium. `java -version` y `javac -version` ejecutados correctamente. Sin cambios de PATH ni paquetes del sistema.
- **SDK Android instalado.** Tras la aceptación del usuario, se cotejó el SHA-256 de las herramientas de línea de comandos y se instaló SDK Tools 22.0, plataforma Android 36 (revisión 2), Build Tools 36.0.0, Platform-Tools 37.0.3 y NDK 28.2.13676358 en `/home/osorio/SDK/android`. Sin Android Studio, emulador ni cambios globales de PATH.
- **Verificación del BLOQUE 3.** Flutter Doctor detectó el SDK y Java mediante `ANDROID_HOME` y `JAVA_HOME` por invocación. Linux sigue con `[✓]`. Android queda con aviso por siete licencias de componentes adicionales sin instalar. Los cuatro paquetes instalados referencian `android-sdk-license`, presente en el SDK local. `adb version` pasó y `adb devices -l` no detectó un teléfono.
- **Siguiente paso.** BLOQUE 3 completado para la preparación autorizada. El BLOQUE 4 requiere autorización para generar runners y compilar. El arranque en Android queda pendiente de conectar un teléfono con depuración USB y autorizar el equipo.

## Punto de control vigente · BLOQUE 3 · 2026-11-22

- **Estado.** Completado para el alcance autorizado de Linux. El SDK local funciona y Flutter Doctor marcó la cadena de compilación Linux con `[✓]` tras la instalación realizada por el usuario.
- **Verificación final.** `dpkg-query` confirmó Clang, CMake, Ninja y GTK 3 de desarrollo instalados. Se ejecutaron Clang 19.1.7, CMake 3.31.6 y Ninja 1.12.1. `pkg-config --modversion gtk+-3.0` devolvió 3.24.49. Los comandos ya se resuelven en la sesión y no se encontró el marcador `/run/reboot-required`. No hace falta reiniciar para que Flutter detecte la cadena Linux.
- **Reintento.** Se repitieron las consultas de versión y `flutter doctor -v`, con los mismos resultados. `dpkg-query` confirmó que siguen sin instalarse los cuatro paquetes Linux. `sudo -n apt update` volvió a salir con código 1 y el mensaje «a password is required».
- **Comprobaciones.** `flutter --version` y `dart --version` por ruta absoluta confirmaron Flutter 3.50.1 estable (revisión `ae9b586f34`) y Dart 3.14.0. `flutter doctor -v` terminó con código 0, detectó Linux y la conectividad, y confirmó que faltan Clang, CMake, Ninja y GTK 3 de desarrollo. Android SDK y Chrome tampoco se detectaron. Flutter y Dart siguen fuera de PATH.
- **Instalación.** `sudo -n -l` y `sudo -n apt update` devolvieron «a password is required». La simulación con los índices actuales estimó 89 paquetes nuevos y ninguna actualización o eliminación. No se refrescaron índices ni se instaló software.
- **Cambios.** Solo se actualizó este registro. Antes de editarlo, Git conservaba el mismo estado que al inicio del bloque. Sin cambios en código, PATH o configuración global.
- **Siguiente tarea.** Esperar autorización para el BLOQUE 4 y generar los runners previstos. El SDK de Android se preparó después de esta verificación Linux. Aún no se compiló ni se ejecutó VNE.

## Registro del BLOQUE 2 · 2026-11-22

- **Reverificación del alcance Android y Linux.** Se ejecutó Dart 3.14.0 por ruta absoluta y se confirmó la etiqueta local de Flutter 3.50.1. APT confirmó la estimación previa de 89 paquetes, 63,0 MB de descarga y 321 MB de disco. Java, adb y sdkmanager siguen fuera de PATH. Se documentaron criterios separados de diagnóstico, compilación y arranque para ambos destinos. No se ejecutaron compilaciones ni se instalaron herramientas.

- **Alcance aprobado.** Android y Linux son las únicas plataformas objetivo. Se retiraron del plan los requisitos de compilación, integración y validación de Windows. Se actualizaron `AGENT.md`, `VNE_EXECUTION_PLAN.md`, `README.md`, la guía de arranque y el plan del SDK. La decisión consta en `DECISIONS.md`. El BLOQUE 3 sigue pendiente de autorización.

- **Etapa y avances.** Plan de preparación documentado en `docs/preparacion-sdk.md`. Propuesta de reutilizar Flutter 3.50.1 estable y Dart 3.14.0 en `/home/osorio/SDK/flutter`, completar primero Linux y autorizar Android por separado.
- **Comprobaciones.** Se verificaron metadatos, etiqueta Git del SDK y tamaño local de 1,6 GiB. La simulación APT con `--no-install-recommends` y la consulta `--print-uris` estimaron 89 paquetes nuevos, 63,0 MB de descarga y 321 MB de disco adicional, con cero actualizaciones o eliminaciones. La consulta inicial con `--assume-no` falló por acceso al bloqueo de APT y se sustituyó por consultas de simulación y de URI sin bloqueo. Se revisaron las guías oficiales de Flutter y Android y los valores de la plantilla Android local.
- **Archivos y dependencias.** Creado `docs/preparacion-sdk.md` y actualizado este registro. Sin archivos eliminados, instalaciones, cambios de PATH ni decisiones técnicas aprobadas.
- **Pendientes y siguiente bloque.** BLOQUE 3 sujeto a autorización expresa para reutilizar el SDK y ejecutar la transacción Debian propuesta. Android requiere decidir modo y componentes. La validación de VNE en Linux y Android sigue pendiente. Las correcciones del detector quedan pendientes de autorización.

## Registro del BLOQUE 1 · 2026-11-22

- **Etapa y objetivos completados.** Auditoría del detector HTML5 y de sus tres comprobaciones. Se revisaron el tope de 4096 bytes, el cierre del descriptor y el manejo de rutas, evidencias y errores. La auditoría quedó completada. El detector sigue en su versión inicial.
- **Pruebas.** En Debian 13.8 amd64 con Dart 3.14.0, `dart --disable-analytics run tool/check_html5_detector.dart` aprobó las tres comprobaciones existentes. Una prueba temporal aprobó archivo vacío, HTML genérico grande en ruta Unicode con espacios, firma fuera de los 4096 bytes, permiso denegado y enlace simbólico directo. El primer análisis estático falló al crear estado en `~/.dartServer` dentro del sandbox. El reintento autorizado de `dart --disable-analytics analyze lib/src/detection` y `dart --disable-analytics analyze tool/check_html5_detector.dart` terminó con código 0 y sin incidencias en ambos objetivos.
- **Hallazgos.** El detector lee datos sin ejecutar scripts, extraer recursos ni modificarlos. Un fallo de apertura, lectura o cierre puede propagarse fuera del contrato de resultado. El enlace directo se rechaza durante la comprobación de tipo, pero sigue pendiente asegurar el confinamiento con directorios enlazados y cambios entre comprobación y apertura. El límite de lectura es deliberado. La firma estrecha puede omitir HTML válido, y la expresión regular merece una prueba de tiempo con comentarios no coincidentes.
- **Clasificación.** HTML genérico y otros runtimes web pueden compartir la firma. El resultado actual expresa un candidato genérico y carece de identificación específica de TyranoScript. La futura integración deberá conservar esa distinción y admitir evidencia específica o selección manual cuando corresponda.
- **Archivos y dependencias.** Solo se modificó este registro. La prueba complementaria se creó en `/tmp`. Sin archivos del repositorio creados ni eliminados, funcionalidades nuevas, dependencias instaladas o decisiones técnicas aprobadas.
- **Pendientes y siguiente paso.** Hace falta autorización para corregir el detector o iniciar el BLOQUE 2. Para las correcciones, priorizar errores de E/S explícitos y límites de inspección, y añadir casos permanentes para el límite exacto, rutas, permisos, enlaces y documentos ambiguos. La aplicación y el runtime siguen pendientes de validación en Linux y Android.

## Diagnóstico del SDK existente · 2026-11-22

- **Alcance.** Diagnóstico puntual solicitado sobre `/home/osorio/SDK/flutter`. El BLOQUE 1 sigue pendiente de autorización.
- **SDK verificado.** Flutter 3.50.1 estable (framework `ae9b586f34`), Dart 3.14.0 y DevTools 2.61.0 en Debian 13.8 amd64. Flutter y Dart siguen fuera de PATH.
- **Pruebas.** Dart `--version` y Flutter `--version` ejecutados correctamente con rutas absolutas. El primer intento de `flutter doctor -v` falló por falta de escritura en la caché del SDK. La ejecución con acceso autorizado terminó con código 0 y avisos en cuatro categorías.
- **Pendientes.** Doctor confirmó que faltan Clang, CMake, Ninja y las cabeceras de GTK 3 para Linux. No encontró el SDK de Android ni Chrome para el destino web de Flutter. Detectó Linux como dispositivo y verificó los recursos de red. Las pruebas del detector y las compilaciones de VNE siguen pendientes.
- **Cambios.** Se actualizó únicamente este registro en el proyecto. Sin dependencias instaladas ni cambios en PATH.

## Registro del BLOQUE 0 (reverificación)

- **Fecha y etapa.** 2026-11-22. BLOQUE 0 completado. Diagnóstico e inventario del estado recuperado.
- **Git.** Rama `main`, con seguimiento de `origin/main` y sin divergencia indicada localmente. Único commit visible: `96a87db Initial project documentation`. `AGENT.md` sigue siendo el único archivo versionado. Se encontraron seis archivos sin seguimiento: este estado, `README.md`, `VNE_EXECUTION_PLAN.md`, `docs/arranque.md`, el detector y sus comprobaciones.
- **Entorno verificado.** Debian 13.8 (trixie), `amd64`/`x86_64`. Git 2.47.3, GCC y G++ 14.2.0, y `pkg-config` 1.8.1 mediante `pkgconf`. El SDK local de `/home/osorio/SDK/flutter` aporta Flutter 3.50.1 estable y Dart 3.14.0. Ambos siguen fuera de PATH. Java, adb, sdkmanager, Clang, CMake y Ninja tampoco se resolvieron en PATH. Faltan las cabeceras de GTK 3 y están presentes las bibliotecas de ejecución de SQLite y WebKitGTK.
- **Avances y pruebas.** Se repitieron las consultas de Git, el inventario y la identificación del sistema y herramientas. Se ejecutó el binario Dart con `--version` y se cotejó la revisión de Flutter con `bin/cache/flutter.version.json`. Se conservaron los resultados de Flutter Doctor del diagnóstico anterior. Se localizaron el detector, las tres comprobaciones y la guía, con ejecución de las comprobaciones pendiente.
- **Cambios, dependencias y decisiones.** Solo se actualizó este archivo para registrar el punto de control. No se crearon ni eliminaron archivos, no se instalaron dependencias y no se aprobaron decisiones técnicas nuevas. `ROADMAP.md` y `DECISIONS.md` están ausentes.
- **Pendientes y problemas.** Detector existente pendiente de auditoría y pruebas, ahora ejecutables con Dart por ruta absoluta. Linux requiere completar sus herramientas de compilación y Flutter Doctor no localizó el SDK de Android. Linux y Android siguen pendientes de validación de la aplicación.
- **Siguiente bloque propuesto.** BLOQUE 1, auditoría del detector HTML5 y evaluación de sus comprobaciones, tras autorización expresa.

## Registro de la sesión inicial

- **Fecha.** 2026-11-22.
- **Etapa.** Diagnóstico del entorno y primera pieza del Core.
- **Objetivos completados.** Lectura íntegra de AGENT.md, inspección del repositorio y de Debian 13.8 amd64, y documentación de la arquitectura y los hitos.
- **Archivos creados.** `README.md`, `docs/arranque.md`, `lib/src/detection/html5_detector.dart`, `tool/check_html5_detector.dart` y `CURRENT_STATUS.md`.
- **Archivos existentes modificados.** Ninguno.
- **Funcionalidades implementadas.** Detector estático de candidatos HTML5 con evidencia. Lee una cabecera acotada de un posible punto de entrada y devuelve un resultado inconcluso si no reconoce la firma.
- **Pruebas y resultados.** Se escribieron tres comprobaciones para archivo ausente, texto con extensión HTML y cabecera HTML con BOM y comentario. `dart run tool/check_html5_detector.dart` y `flutter doctor -v` devolvieron código 127 porque los comandos no están disponibles. Formato, análisis y ejecución de las comprobaciones quedan pendientes. La revisión de espacios al final de línea en los archivos nuevos no encontró coincidencias.
- **Problemas pendientes.** Falta Flutter con Dart y el toolchain de Linux y Android. Siguen pendientes los runners, SQLite, biblioteca, importación, API y gestor de motores, y reproducción HTML5. Linux y Android están pendientes de validación.
- **Dependencias instaladas en esta sesión.** Ninguna.
- **Decisiones técnicas.** Detector en Dart sin dependencias externas. Resultado de candidato con evidencia, independiente de la compatibilidad de reproducción. Runners oficiales y catálogo local de demostración previstos.
- **Siguiente tarea concreta.** Una vez autorizado y disponible el SDK, ejecutar `flutter doctor -v`, fijar la versión de Flutter, generar los runners en la raíz conservando los archivos existentes y ejecutar las comprobaciones del detector.
