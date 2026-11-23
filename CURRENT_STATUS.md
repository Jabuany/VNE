# Estado actual de VNE

## Punto de control vigente · BLOQUE 10 · 2026-11-22

- **Estado y avances.** BLOQUE 10 completado para Android. Reproductor HTML5 de desarrollo con Activity nativa, adaptador del Core, origen local y perfil por juego, acceso de lectura a copias privadas y referencias SAF, diagnósticos y controles de regreso, pausa y pantalla completa. Dispone de activación explícita en APK debug sin permiso de Internet.
- **Archivos creados.** Activity, canal y lector de recursos Kotlin, manifiesto offline, adaptador Dart, prueba de adaptador, muestra propia `test/fixtures/html5`, guía de Android y texto Apache-2.0. Actualizados runner Android, composición Flutter, ficha de biblioteca, pruebas de interfaz, avisos y documentación. Sin archivos eliminados.
- **Dependencias.** AndroidX WebKit 1.18.0 (Apache-2.0), unos 296 kB como AAR publicado. El WebView se obtiene del proveedor del sistema. Sin instalaciones globales ni descargas de juegos externos.
- **Pruebas automatizadas.** `flutter analyze --no-pub` aprobó sin incidencias, `flutter test --no-pub` aprobó 35 pruebas y las tres comprobaciones del detector aprobaron. La última prueba de interfaz detectó una ubicación incorrecta del botón Reproducir, corregida antes de recompilar. Se construyó el APK offline con firma y manifiesto sin Internet verificados. La aplicación base volvió a compilar para Linux.
- **Pruebas físicas.** Android 15 con WebView 157. Se instaló una variante aislada después de rechazos iniciales de ADB. Tres sesiones abiertas y cerradas por la API, pausa/reanudación por canal, rechazo de entrada ausente y vuelta a Flutter. La UI de la muestra confirmó CSS, JS, imagen, fuente, JSON y decodificación WAV, respuesta 404 y petición externa bloqueada. El contador pasó de visita 3 a 4 al reabrir y mostró visita 2 para otro juego, tras una corrida anterior. La inspección de UI de esa corrida anterior omitió temporalmente el árbol web en la tercera sesión. Se repitió con espera hasta que apareció el contenido.
- **Condiciones pendientes.** La prueba física usó copias privadas. Reproducción de referencia SAF, audio audible, rotación, controles físicos y codecs/rangos adicionales quedan para validación posterior. La API explícita de guardado de ranuras y el catálogo no están implementados. La variante aislada sigue instalada en el teléfono.
- **Siguiente tarea.** Solicitar autorización antes de extender el runtime a Linux y realizar la validación multiplataforma del BLOQUE 11.

## Registro del BLOQUE 9 · 2026-11-22

- **Estado y avances.** Evaluación del runtime HTML5 completada. Propuesta pendiente de aprobación: Android primero con Activity Kotlin, WebView del sistema y AndroidX WebKit. Para Linux, auxiliar GTK 3 con WebKitGTK 4.1, perfil por juego y Bubblewrap. Se documentaron navegación, recursos locales, permisos, audio, entrada, pantalla completa, cierre y aislamiento de datos.
- **Archivos.** Creado `docs/runtime-html5.md`. Actualizados `README.md` y este registro. Sin archivos eliminados, cambios de código, dependencias instaladas ni descargas de juegos.
- **Comprobaciones.** `adb shell dumpsys webviewupdate` confirmó WebView 157.0.8103.50 en Android 15. En Debian 13.8 amd64, `dpkg-query` y una consulta de versión de la biblioteca confirmaron WebKitGTK 2.54.3. Bubblewrap 0.12.0 creó un espacio de red distinto del anfitrión, con solo loopback, para una prueba de shell. La simulación APT de `libwebkit2gtk-4.1-dev` estimó 13 paquetes, 2,2 MB de descarga y 13,9 MB adicionales.
- **Pendientes.** Se requiere verificar `MULTI_PROFILE`, la carga local con red bloqueada y el aislamiento con los motores activos. La prueba de Bubblewrap no ejecutó WebKitGTK. No se ejecutó ni validó la reproducción HTML5.
- **Siguiente tarea.** Aprobar plataforma inicial y estrategia de aislamiento, y autorizar el BLOQUE 10. Revisar en el BLOQUE 12 la activación opcional del adaptador Android y el empaquetado independiente del auxiliar Linux. No se registraron decisiones técnicas nuevas como aprobadas.

## Registro del BLOQUE 8 · 2026-11-22

- **Estado y avances.** Detección estática web integrada con importación y biblioteca. Clasifica contenido desconocido, HTML genérico, posible juego web y estructura identificada de TyranoScript. SQLite guarda evidencia, confianza, versión e indicios de entrada con el juego en una transacción. La selección manual distingue preferencia y evidencia original.
- **Archivos creados.** `lib/src/detection/web_game_detector.dart`, `test/web_game_detector_test.dart` y `docs/deteccion.md`.
- **Archivos modificados.** Composición Flutter, pantalla de biblioteca, importador de carpeta, contrato de biblioteca, repositorio SQLite, tres archivos de pruebas existentes, README, guías de biblioteca e importación y este registro. Sin archivos eliminados.
- **Pruebas.** Dart format ejecutado. `flutter analyze --no-pub` aprobó sin incidencias después de actualizar el callback de publicación en pruebas y retirar un import redundante. `flutter test --no-pub` aprobó 32 pruebas. Las tres comprobaciones del detector anterior aprobaron. Se probaron falsos positivos y negativos, prioridad de TyranoScript, límite de cabecera, migración, persistencia y corrección manual.
- **Validación en plataforma.** Compilaciones debug Linux y Android aprobadas. En Debian 13.8 x64, la app migró una biblioteca de prueba del esquema 1 al 2 y conservó juego y ajustes. En Android 15 físico se actualizó la variante aislada, se verificó el arranque y se confirmó que la migración mantuvo sus dos juegos. La interacción de corrección manual se verificó mediante pruebas de widgets en Debian.
- **Decisiones y dependencias.** Sin dependencias añadidas o instaladas. Informe de detector v1 y esquema SQLite 2. Registros previos sin informe conservan su motor y entrada. La firma de TyranoScript es clasificación estructural y no integra su intérprete.
- **Pendientes y siguiente tarea.** HTML5 aún no se reproduce. Esperar autorización para el BLOQUE 9 y evaluar el runtime en Linux y Android.

## Registro del BLOQUE 7 · 2026-11-22

- **Validación de copia en Android.** Tras la selección manual en Android 15, se confirmó un registro SQLite con modo `managedCopy`, candidato `html5` y entrada `index.html`. La copia privada, el original del teléfono y la muestra local tienen el mismo SHA-256.
- **Validación de referencia en Android.** Tras reiniciar la variante aislada con `adb shell am force-stop` y `am start -W`, SQLite conservó ambos modos. La referencia tiene URI SAF, candidato `html5` y entrada `index.html`. `adb shell dumpsys activity permissions` confirmó acceso de lectura persistente (`persisted=0x1`) asignado a la variante de prueba. El comando suplementario `content read` desde `run-as` no pudo ejecutarse por los permisos del comando de Android. La variante y la muestra temporal siguen en el teléfono.

- **Estado y avances.** BLOQUE 7 completado. Importación de carpetas locales por referencia o copia, con progreso, cancelación y límites de entradas, profundidad y bytes. Android usa SAF y Linux usa un selector nativo y aperturas confinadas. El detector inspecciona una cabecera acotada al terminar el recorrido y la biblioteca publica el registro en SQLite. Pruebas de Debian y comprobación de ambos modos en Android 15 completadas.
- **Archivos creados.** `android/app/src/main/kotlin/org/vne/vne/ImportTreeChannel.kt`, `lib/src/import/{android_import_tree,folder_game_importer,import_tree,linux_import_tree}.dart`, `test/folder_game_importer_test.dart` y `docs/importacion.md`. Actualizados la actividad Android, la composición y pantalla de biblioteca, el contrato de importación, el detector, las pruebas de interfaz, los manifiestos Pub, los registros generados de plugins Linux, README, avisos y este archivo. Sin archivos del repositorio eliminados.
- **Dependencias.** `file_selector_linux` 0.9.4+1 y `ffi` 2.2.0 como dependencias directas. FFI ya formaba parte del árbol. Sin paquetes globales ni cambios de PATH. El APK de depuración aumentó unos 26 MiB respecto al BLOQUE 6.
- **Pruebas.** En Debian 13.8 x64, `flutter analyze --no-pub`, `flutter test --no-pub` (21 pruebas) y las tres comprobaciones del detector aprobaron. Las ocho pruebas de importación abarcan persistencia, copia y referencia, enlaces, cambios de origen durante la inspección, nombres, límites, cancelación y limpieza por fallo. Se recompiló y arrancó el bundle Linux con almacén temporal. Se compiló y verificó la firma del APK Android.
- **Teléfono.** La variante de integración aislada con ID `org.vne.vne.importtest` se instaló y arrancó en Android 15. El dispositivo rechazó los toques de ADB por falta de `INJECT_EVENTS`. Se dejó abierta la variante aislada y la carpeta sintética `Documentos/VNE-import-Mm2ERt` para que el usuario haga la selección. La biblioteca del APK habitual conserva sus datos.
- **Pendientes y limitaciones.** El selector admite carpetas. ZIP, 7z y RAR, selección manual de motor, evidencia persistente y recuperación de una copia interrumpida por apagado quedan pendientes. La reproducción HTML5 sigue fuera de este bloque.
- **Siguiente tarea.** Esperar autorización para el BLOQUE 8, integración de detección HTML5 con evidencia persistente y corrección manual.

## Registro del BLOQUE 6 · 2026-11-22

- **Etapa y avances.** Biblioteca SQLite con listados, consulta, alta, actualización y eliminación de registros, preferencias por juego, migración transaccional y claves foráneas. Pantalla con estados de carga, vacío y error, búsqueda, detalles y estado de asignación de motor. La importación y la disponibilidad efectiva de runtimes siguen pendientes.
- **Archivos creados.** `lib/src/app/library_page.dart`, `lib/src/library/game_library.dart`, `lib/src/storage/sqlite_game_library.dart`, `test/sqlite_game_library_test.dart`, `docs/biblioteca.md` y `THIRD_PARTY_NOTICES`.
- **Archivos modificados.** `.gitignore`, `lib/main.dart`, `test/widget_test.dart`, `pubspec.yaml`, `pubspec.lock`, `linux/flutter/generated_plugins.cmake`, `README.md`, `docs/core.md`, `DECISIONS.md` y este registro. Sin archivos eliminados.
- **Dependencias.** `sqlite3` 3.9.2, `path_provider` 2.1.6 y `material_ui` 1.11.1. Gradle instaló Platform 35 revisión 2 y CMake 3.22.1 en el SDK Android local para dependencias. Sin cambios de PATH ni paquetes globales.
- **Pruebas.** Dart format, `flutter analyze --no-pub`, 12 pruebas Flutter y las tres comprobaciones del detector aprobadas. Se corrigió un fallo inicial en el botón de reintento que devolvía un Future a `setState`. Las pruebas SQLite verificaron CRUD, persistencia tras reabrir, integridad referencial, rechazo de esquema futuro y reversión de migración fallida.
- **Validación en plataforma.** Compilación debug y arranque verificados en Debian 13.8 amd64 y Android 15 físico. Se verificó la creación de una base vacía con esquema 1 en ambos destinos. CRUD y búsqueda se verificaron en las pruebas automatizadas de Debian.
- **Decisiones.** Se registró la aprobación de la API del Core tras la autorización del BLOQUE 6. Se implementó el esquema inicial para juegos y ajustes. Catálogo, guardados e historial se incorporarán cuando existan sus flujos.
- **Siguiente tarea.** Solicitar autorización para el BLOQUE 7 de importación local. Integrar selección, copia o referencia y detección sin ejecutar juegos. La reproducción HTML5 continúa pendiente.

## Registro del BLOQUE 5 · 2026-11-22

- **Etapa y avances.** Contratos del Core en Dart para juego, ajustes, metadatos de guardado, diagnóstico, detección, importación, API de motor, sesiones y gestión de paquetes. Propuesta de API 1.0, con compatibilidad por número mayor y menor, y filtro adicional por plataforma y arquitectura.
- **Archivos creados.** `lib/src/core/game.dart`, `lib/src/core/diagnostics.dart`, `lib/src/detection/game_detector.dart`, `lib/src/import/game_importer.dart`, `lib/src/engine_api/engine.dart`, `lib/src/engine_manager/runtime_manager.dart`, `test/core_contracts_test.dart` y `docs/core.md`.
- **Archivos modificados.** `lib/src/detection/html5_detector.dart` comparte y reexporta el tipo de confianza sin cambiar la lógica de inspección. Actualizados `README.md` y `CURRENT_STATUS.md`. Sin archivos eliminados ni dependencias añadidas o instaladas.
- **Pruebas.** Dart format ejecutado sobre los archivos nuevos. En Debian 13.8 amd64 con Flutter 3.50.1 y Dart 3.14.0, `flutter analyze --no-pub` aprobó sin incidencias, `flutter test --no-pub` aprobó seis pruebas y `dart --disable-analytics run tool/check_html5_detector.dart` aprobó las tres comprobaciones existentes.
- **Propuesta y pendientes.** Sesión Dart tipada con transporte interno por adaptador y capacidades opcionales de pausa y guardado. Arquitectura propuesta, pendiente de aprobación. Los contratos no han sido validados con un runtime conectado. No se repitieron las compilaciones ni las pruebas de dispositivo del BLOQUE 4.
- **Siguiente tarea.** Revisar y aprobar los contratos antes de fijar la API y autorizar el BLOQUE 6 de SQLite y biblioteca. Los hallazgos de la auditoría del detector siguen pendientes.

## Registro del BLOQUE 4 · 2026-11-22

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
