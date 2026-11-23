# Estado actual de VNE

## Punto de control vigente · BLOQUE 2 · 2026-11-22

- **Etapa y avances.** Plan de preparación documentado en `docs/preparacion-sdk.md`. Propuesta de reutilizar Flutter 3.50.1 estable y Dart 3.14.0 en `/home/osorio/SDK/flutter`, completar primero Linux y autorizar Android por separado.
- **Comprobaciones.** Se verificaron metadatos, etiqueta Git del SDK y tamaño local de 1,6 GiB. La simulación APT con `--no-install-recommends` y la consulta `--print-uris` estimaron 89 paquetes nuevos, 63,0 MB de descarga y 321 MB de disco adicional, con cero actualizaciones o eliminaciones. La consulta inicial con `--assume-no` falló por acceso al bloqueo de APT y se sustituyó por consultas de simulación y de URI sin bloqueo. Se revisaron las guías oficiales de Flutter y Android y los valores de la plantilla Android local.
- **Archivos y dependencias.** Creado `docs/preparacion-sdk.md` y actualizado este registro. Sin archivos eliminados, instalaciones, cambios de PATH ni decisiones técnicas aprobadas.
- **Pendientes y siguiente bloque.** BLOQUE 3 sujeto a autorización expresa para reutilizar el SDK y ejecutar la transacción Debian propuesta. Android requiere decidir modo y componentes. La validación de VNE en Linux, Android y Windows sigue pendiente. Las correcciones del detector quedan pendientes de autorización.

## Registro del BLOQUE 1 · 2026-11-22

- **Etapa y objetivos completados.** Auditoría del detector HTML5 y de sus tres comprobaciones. Se revisaron el tope de 4096 bytes, el cierre del descriptor y el manejo de rutas, evidencias y errores. La auditoría quedó completada. El detector sigue en su versión inicial.
- **Pruebas.** En Debian 13.8 amd64 con Dart 3.14.0, `dart --disable-analytics run tool/check_html5_detector.dart` aprobó las tres comprobaciones existentes. Una prueba temporal aprobó archivo vacío, HTML genérico grande en ruta Unicode con espacios, firma fuera de los 4096 bytes, permiso denegado y enlace simbólico directo. El primer análisis estático falló al crear estado en `~/.dartServer` dentro del sandbox. El reintento autorizado de `dart --disable-analytics analyze lib/src/detection` y `dart --disable-analytics analyze tool/check_html5_detector.dart` terminó con código 0 y sin incidencias en ambos objetivos.
- **Hallazgos.** El detector lee datos sin ejecutar scripts, extraer recursos ni modificarlos. Un fallo de apertura, lectura o cierre puede propagarse fuera del contrato de resultado. El enlace directo se rechaza durante la comprobación de tipo, pero sigue pendiente asegurar el confinamiento con directorios enlazados y cambios entre comprobación y apertura. El límite de lectura es deliberado. La firma estrecha puede omitir HTML válido, y la expresión regular merece una prueba de tiempo con comentarios no coincidentes.
- **Clasificación.** HTML genérico y otros runtimes web pueden compartir la firma. El resultado actual expresa un candidato genérico y carece de identificación específica de TyranoScript. La futura integración deberá conservar esa distinción y admitir evidencia específica o selección manual cuando corresponda.
- **Archivos y dependencias.** Solo se modificó este registro. La prueba complementaria se creó en `/tmp`. Sin archivos del repositorio creados ni eliminados, funcionalidades nuevas, dependencias instaladas o decisiones técnicas aprobadas.
- **Pendientes y siguiente paso.** Hace falta autorización para corregir el detector o iniciar el BLOQUE 2. Para las correcciones, priorizar errores de E/S explícitos y límites de inspección, y añadir casos permanentes para el límite exacto, rutas, permisos, enlaces y documentos ambiguos. La aplicación y el runtime siguen pendientes de validación en Linux, Android y Windows.

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
- **Pendientes y problemas.** Detector existente pendiente de auditoría y pruebas, ahora ejecutables con Dart por ruta absoluta. Linux requiere completar sus herramientas de compilación y Flutter Doctor no localizó el SDK de Android. Linux, Android y Windows siguen pendientes de validación de la aplicación.
- **Siguiente bloque propuesto.** BLOQUE 1, auditoría del detector HTML5 y evaluación de sus comprobaciones, tras autorización expresa.

## Registro de la sesión inicial

- **Fecha.** 2026-11-22.
- **Etapa.** Diagnóstico del entorno y primera pieza del Core.
- **Objetivos completados.** Lectura íntegra de AGENT.md, inspección del repositorio y de Debian 13.8 amd64, y documentación de la arquitectura y los hitos.
- **Archivos creados.** `README.md`, `docs/arranque.md`, `lib/src/detection/html5_detector.dart`, `tool/check_html5_detector.dart` y `CURRENT_STATUS.md`.
- **Archivos existentes modificados.** Ninguno.
- **Funcionalidades implementadas.** Detector estático de candidatos HTML5 con evidencia. Lee una cabecera acotada de un posible punto de entrada y devuelve un resultado inconcluso si no reconoce la firma.
- **Pruebas y resultados.** Se escribieron tres comprobaciones para archivo ausente, texto con extensión HTML y cabecera HTML con BOM y comentario. `dart run tool/check_html5_detector.dart` y `flutter doctor -v` devolvieron código 127 porque los comandos no están disponibles. Formato, análisis y ejecución de las comprobaciones quedan pendientes. La revisión de espacios al final de línea en los archivos nuevos no encontró coincidencias.
- **Problemas pendientes.** Falta Flutter con Dart y el toolchain de Linux y Android. Siguen pendientes los runners, SQLite, biblioteca, importación, API y gestor de motores, y reproducción HTML5. Las tres plataformas carecen todavía de validación.
- **Dependencias instaladas en esta sesión.** Ninguna.
- **Decisiones técnicas.** Detector en Dart sin dependencias externas. Resultado de candidato con evidencia, independiente de la compatibilidad de reproducción. Runners oficiales y catálogo local de demostración previstos.
- **Siguiente tarea concreta.** Una vez autorizado y disponible el SDK, ejecutar `flutter doctor -v`, fijar la versión de Flutter, generar los runners en la raíz conservando los archivos existentes y ejecutar las comprobaciones del detector.
