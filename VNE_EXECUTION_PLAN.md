# VNE — Plan maestro de ejecución para Codex
## Instrucciones por bloques, puntos de control y autorización obligatoria

**Proyecto:** VNE (Visual Novel Engine)
**Plataformas objetivo:** Android y Linux
**Entorno actual:** Debian 13.8 (trixie), amd64
**Tecnología:** Flutter + Dart; SQLite
**Primer runtime:** HTML5
**Documento general:** `AGENT.md`

---

## 1. Propósito

`AGENT.md` contiene las reglas generales del proyecto. Este documento establece el trabajo operativo: qué hacer, en qué orden, cómo comprobarlo y cuándo detenerse.

**Regla fundamental: ejecutar un solo bloque por vez. Al terminarlo, detenerse, entregar el informe y esperar autorización expresa del usuario.** Nunca avanzar automáticamente al bloque siguiente. La autorización para un bloque no autoriza los posteriores.

## 2. Reglas obligatorias

1. Antes de trabajar, leer `AGENT.md`, este documento y `CURRENT_STATUS.md`. Revisar también `README.md`, `ROADMAP.md` y `DECISIONS.md` si existen.
2. Antes de modificar, revisar `git status` y el estado de los archivos. No sobrescribir cambios ajenos.
3. No instalar, actualizar ni eliminar paquetes, SDK, runtimes o herramientas globales sin autorización explícita.
4. No modificar configuraciones globales, PATH ni permisos del sistema sin autorización.
5. No descargar ni ejecutar juegos durante detección o importación.
6. No descargar runtimes automáticamente. La instalación debe ser una acción explícita del usuario.
7. No inventar URLs, versiones, licencias, hashes, resultados de pruebas ni compatibilidad.
8. Diferenciar siempre: **implementado**, **probado**, **validado en plataforma** y **pendiente**.
9. No declarar una plataforma compatible si no se ha compilado y probado en ella o no hay evidencia verificable.
10. Trabajar solo en el runtime HTML5 hasta que el usuario confirme que está terminado. No comenzar TyranoScript, Ren’Py, VNDS, ONScripter, RPG Maker ni KiriKiri antes de esa aprobación.
11. Antes de añadir una dependencia, explicar motivo, licencia, plataformas, impacto/tamaño aproximado y alternativas.
12. No crear esqueletos vacíos de todos los motores ni código de ejemplo presentado como funcionalidad real.
13. Si una decisión anterior parece incorrecta, describir el problema y proponer alternativas; no cambiarla silenciosamente.
14. No borrar archivos ni descartar cambios Git sin autorización.
15. No hacer commits, pushes ni publicar repositorios sin autorización explícita.
16. Nunca subir juegos, credenciales, tokens, claves privadas ni datos personales al repositorio.
17. Si falta una herramienta, permiso o plataforma, detenerse, explicar el bloqueo y proponer el siguiente paso seguro.
18. Mantener las pruebas y documentación actualizadas. No eliminar pruebas para conseguir que pasen.
19. Tratar todo juego importado como contenido no confiable.
20. Respetar las licencias de motores y bibliotecas. No copiar código de JoiPlay, VNDS, Kirikiroid2 u otros proyectos sin verificar permisos. No distribuir juegos comerciales ni eludir DRM.

## 3. Informe obligatorio al terminar cada bloque

Usar exactamente esta estructura:

### Informe del bloque N
**Estado:** completado / parcialmente completado / bloqueado.

**A. Resultado**
- Objetivo alcanzado.
- Pendientes y bloqueos.

**B. Archivos y cambios**
- Archivos revisados, creados y modificados.
- Archivos eliminados (no hacerlo sin autorización previa).
- Dependencias añadidas o modificadas.

**C. Pruebas**
Para cada prueba: comando, resultado real (aprobado/fallido/no ejecutado), entorno/plataforma y error relevante. Nunca presentar pruebas no ejecutadas como aprobadas.

**D. Seguridad y compatibilidad**
- Riesgos y medidas.
- Limitaciones conocidas.
- Plataformas verificadas y no verificadas.

**E. Recomendaciones**
- Recomendación principal.
- Alternativas con ventajas y desventajas.
- Decisiones que debe tomar el usuario.

**F. Documentación**
Actualizar `CURRENT_STATUS.md` con bloque, fecha, avances, pendientes, pruebas, problemas, dependencias y siguiente bloque propuesto. Actualizar `DECISIONS.md` solo con decisiones aprobadas; no registrar propuestas como decisiones aceptadas.

**G. Punto de control**
Terminar literalmente con:
**“El bloque N ha terminado. ¿Autorizas que continúe con el bloque N+1?”**

Después, detenerse. No ejecutar nada más hasta recibir autorización.

---

## 4. Estado inicial conocido (verificar, no asumir)

Según el último informe:
- Debian 13.8 (trixie), amd64/x86_64.
- Git 2.47.3; GCC/G++ 14.2; `pkg-config` 1.8.1 mediante `pkgconf`.
- Flutter, Dart, Java, `adb` y `sdkmanager` no detectados.
- Faltaban Clang, CMake, Ninja y cabeceras GTK 3 para compilación Linux.
- Bibliotecas de ejecución SQLite y WebKitGTK presentes.
- Rama `main`; inicialmente `AGENT.md` era el único archivo versionado.
- Detector inicial HTML5 implementado: inspecciona hasta 4096 bytes de `index.html`, devuelve evidencia y no ejecuta contenido.
- Tres comprobaciones escritas, no ejecutadas por falta de Dart.
- `flutter doctor -v` no pudo ejecutarse.
- `CURRENT_STATUS.md` actualizado.
- No se instalaron dependencias ni se modificó la configuración global.

---

# 5. Bloques de trabajo

## BLOQUE 0 — Recuperar y verificar el estado
**Objetivo:** conocer el estado real sin modificar nada.

Tareas:
1. Leer los documentos del proyecto indicados en la sección 1.
2. Ejecutar `git status --short --branch` y `git log --oneline -5` si existe historial.
3. Mostrar el árbol de archivos excluyendo `.git`, `build`, `.dart_tool` y cachés.
4. Verificar Debian, arquitectura y herramientas: Git, Flutter, Dart, Java, adb, sdkmanager, Clang, CMake, Ninja, GCC, G++ y pkg-config.
5. Localizar el detector, sus tres pruebas y la guía de arranque.
6. Comparar el estado actual con el informe anterior.
7. No instalar ni modificar nada.

Criterios de salida: estado Git, inventario de archivos, herramientas presentes/ausentes y ubicación de detector/pruebas conocidos.

**DETENTE:** entrega el informe del bloque 0 y espera autorización para el bloque 1.

## BLOQUE 1 — Auditoría del detector HTML5
**Objetivo:** revisar el código existente, sin ampliar todavía el alcance.

Tareas:
1. Leer el detector y sus tres pruebas completas.
2. Revisar límite de lectura de 4096 bytes y manejo de errores.
3. Evaluar archivo inexistente, vacío, grande, no HTML, permisos insuficientes, rutas Unicode/con espacios, errores de lectura y enlaces simbólicos si aplican.
4. Verificar que no ejecuta scripts, no extrae ni modifica contenido, no confía solo en extensiones y devuelve evidencias.
5. Diferenciar “candidato HTML5” de “juego reproducible”.
6. Evaluar falsos positivos y falsos negativos previsibles.
7. Asegurar que HTML5 genérico no se confunda con TyranoScript.
8. No reescribir por preferencias de estilo; señalar defectos concretos.

Criterios: auditoría documentada, pruebas actuales evaluadas, lista de defectos y casos adicionales propuestos. No afirmar que está validado hasta ejecutar las pruebas.

**DETENTE:** informa y solicita autorización antes de corregir o pasar al bloque 2.

## BLOQUE 2 — Plan de preparación Flutter/Dart
**Objetivo:** diseñar una instalación segura y reproducible, sin instalar todavía.

Tareas:
1. Investigar opciones oficiales vigentes para instalar Flutter en Debian 13.
2. Proponer instalación local dentro del directorio del usuario, no global.
3. Identificar versión estable apropiada y fuente oficial; no inventar versiones.
4. Clasificar dependencias obligatorias/opcionales para Linux y Android.
5. Definir cómo validar en Debian la compilación Linux y separar la preparación y validación del SDK de Android.
6. Explicar propósito, licencia, impacto/tamaño y alternativas de dependencias cuando sea posible.
7. Presentar comandos, cambios que realizarían y cómo revertirlos.
8. No ejecutar `sudo apt install`, descargas ni cambios PATH.

Criterios: plan, versiones/fuentes, dependencias, riesgos y pasos revisados.

**DETENTE:** pedir autorización explícita para instalar Flutter y dependencias. No instalar sin ella.

## BLOQUE 3 — Instalación autorizada y diagnóstico
**Precondición:** autorización explícita para los pasos concretos.

Tareas:
1. Ejecutar solo los pasos autorizados.
2. Instalar Flutter localmente en la ubicación acordada.
3. Modificar PATH solo si fue autorizado.
4. Ejecutar `flutter --version`, `dart --version` y `flutter doctor -v`.
5. Registrar rutas, versiones y avisos.
6. No instalar automáticamente componentes adicionales sugeridos por Flutter Doctor si no estaban autorizados.
7. Comprobar que Git y archivos del proyecto siguen intactos.

Criterios: Flutter/Dart disponibles, versiones registradas, diagnóstico y bloqueos documentados.

**DETENTE:** informa y pide autorización para generar runners.

## BLOQUE 4 — Aplicación Flutter mínima y runners
**Objetivo:** crear una sola aplicación principal, sin implementar aún todas las funciones.

Tareas:
1. Inspeccionar estructura antes de crear archivos.
2. Proponer ubicación de la app Flutter.
3. Generar runners oficiales Android y Linux si el entorno lo permite.
4. Comprobar la estructura de ambos runners y registrar los requisitos para compilar y probar cada uno.
5. Evitar proyectos duplicados y esqueletos vacíos de motores.
6. Ejecutar `flutter analyze` y pruebas disponibles.
7. Intentar arranque Linux si las dependencias están listas.
8. Documentar ejecución y compilación.

Criterios: estructura mínima, runners generados, estados por plataforma honestos, análisis estático y pasos reproducibles.

**DETENTE:** informa y solicita autorización para el bloque 5.

## BLOQUE 5 — Arquitectura base y contratos del Core
**Objetivo:** definir interfaces sin acoplar Flutter al runtime.

Tareas:
1. Revisar estructura y evitar duplicados.
2. Diseñar modelos para juego, motor/runtime, detección, instalación, guardados y ajustes.
3. Diseñar contratos para detección, importación, gestión de runtimes, lanzamiento/cierre, capacidades opcionales, eventos y diagnóstico.
4. No asumir que todo motor corre dentro del proceso Flutter: admitir WebView, proceso externo o componente nativo.
5. Versionar API de motores y compatibilidad.
6. No obligar a un motor a implementar capacidades que no soporta; representar capacidades opcionales.
7. Añadir pruebas unitarias y documentación.

Criterios: contratos claros y probados, separación UI/lógica/runtime y versionado definido.

**DETENTE:** presentar opciones/recomendaciones de API y esperar aprobación antes de congelar contratos.

## BLOQUE 6 — SQLite y biblioteca local
**Objetivo:** persistir juegos y mostrar biblioteca inicial.

Tareas:
1. Diseñar esquema SQLite y migraciones.
2. Evaluar tablas mínimas: `games`, `engines`, `game_saves`, `game_settings`, `play_history`.
3. Definir claves foráneas, índices y almacenamiento de rutas/URI.
4. Implementar repositorios y pruebas de persistencia.
5. Crear interfaz inicial: estado vacío, lista, búsqueda, detalles y estado del runtime.
6. No descargar portadas ni metadatos automáticamente.
7. Documentar respaldo y migraciones.

Criterios: CRUD probado, migraciones reproducibles y datos conservados tras reiniciar.

**DETENTE:** entregar informe y solicitar autorización para el bloque 7.

## BLOQUE 7 — Importación local segura
**Objetivo:** importar juegos que el usuario ya posee legalmente.

Tareas:
1. Definir selección de carpetas/archivos por plataforma.
2. En Android priorizar Storage Access Framework/document picker; evitar permisos amplios injustificados.
3. En Linux usar selectores soportados.
4. Evaluar carpeta, ZIP, 7z y RAR solo si biblioteca, licencia y compatibilidad se verifican.
5. Prevenir path traversal, rutas absolutas, enlaces simbólicos peligrosos, nombres duplicados, bombas de descompresión y límites excesivos de archivos/tamaño.
6. Nunca ejecutar scripts o binarios al importar.
7. Ofrecer copiar o referenciar archivos, explicar consecuencias y preservar originales.
8. Añadir progreso, cancelación y manejo de errores sin bloquear UI.
9. Al terminar, invocar detección sin lanzar el juego.
10. Probar entradas válidas, inválidas y maliciosas controladas.

Criterios: importación segura probada, cancelación y errores controlados, original preservado y sin ejecución de contenido.

**DETENTE:** entregar informe de seguridad y solicitar autorización para el bloque 8.

## BLOQUE 8 — Integración de detección HTML5
**Objetivo:** integrar el detector con importación y biblioteca.

Tareas:
1. Integrarlo sin acoplarlo a UI.
2. Registrar evidencia y confianza.
3. Distinguir HTML genérico, posible juego web, motor web identificado y contenido desconocido.
4. No confundir TyranoScript con HTML5 genérico.
5. Permitir corrección manual en casos ambiguos.
6. No ejecutar contenido para comprobarlo.
7. Guardar resultado y versión del detector.
8. Probar falsos positivos/negativos conocidos.

Criterios: detección visible, corregible, segura y probada.

**DETENTE:** informar y pedir autorización para el bloque 9.

## BLOQUE 9 — Evaluación del runtime HTML5
**Objetivo:** elegir tecnología antes de implementar el reproductor.

Tareas:
1. Investigar Android WebView y WebKitGTK u otra opción apropiada para Linux.
2. Verificar mantenimiento, licencia, versiones mínimas, capacidades y limitaciones.
3. Evaluar contenido local y recursos relativos.
4. Diseñar seguridad: navegación externa, ventanas emergentes, acceso a archivos, APIs nativas expuestas y permisos.
5. Evaluar audio, pantalla completa, orientación, escalado, teclado, ratón y controles táctiles.
6. Documentar diferencias entre motores de navegador.
7. Definir juegos de prueba legales, gratuitos o creados para pruebas. No descargarlos sin permiso.
8. Proponer adaptadores por plataforma.
9. No iniciar TyranoScript.

Criterios: comparativa, estrategia por plataforma, riesgos y plan de pruebas documentados.

**DETENTE:** solicitar aprobación de la estrategia antes de implementarla.

## BLOQUE 10 — Implementación del reproductor HTML5
**Precondición:** estrategia aprobada.

Tareas:
1. Implementar primero la plataforma prioritaria acordada.
2. Cargar contenido local sin alterar originales.
3. Resolver rutas relativas de HTML, CSS, JS, imágenes, fuentes y audio.
4. Implementar preparar/iniciar/pausar/reanudar/detener/liberar.
5. Añadir controles acordados: regresar, pantalla completa, volumen si se soporta, escalado, teclado/ratón y táctil Android.
6. Mostrar errores de carga y diagnóstico.
7. No exponer APIs nativas privilegiadas sin necesidad.
8. Controlar navegación fuera del juego.
9. Separar UI Flutter y adaptador WebView.
10. Añadir pruebas y documentación.

Criterios: juego HTML5 de prueba local abre/cierra, recursos relativos funcionan, errores controlados y recursos liberados.

**DETENTE:** informar y pedir autorización antes de extender a otra plataforma.

## BLOQUE 11 — Validación multiplataforma HTML5
**Objetivo:** verificar cada plataforma con evidencia real.

Tareas:
1. Probar Linux.
2. Probar Android en dispositivo/emulador disponible.
3. Verificar recursos, audio, controles, ciclo de vida, cierre y navegación.
4. Probar resoluciones y relaciones de aspecto.
5. Registrar diferencias y actualizar matriz de compatibilidad.
6. Corregir defectos del alcance HTML5 solamente.

Criterios: matriz con probado/no probado, resultados reproducibles y limitaciones conocidas.

**DETENTE:** informar y pedir autorización para bloque 12.

## BLOQUE 12 — Catálogo e instalación de runtimes bajo demanda
**Objetivo:** diseñar el mecanismo de instalación explícita.

Tareas:
1. Diseñar catálogo con ID, nombre, versión, API compatible, plataforma/arquitectura, tamaño, licencia, origen, SHA-256 y notas.
2. No inventar URLs, hashes ni licencias.
3. Mostrar tamaño y espacio necesario antes de instalar.
4. Instalar solo tras acción explícita del usuario.
5. Implementar progreso, cancelación, reintento, validación de hash, desinstalación y actualización.
6. No ejecutar paquete antes de verificar integridad y procedencia.
7. Diseñar reversión de versión.
8. No incluir todos los runtimes en instalación inicial.
9. Probar con runtime propio o autorizado.

Criterios: instalación voluntaria, hash validado, metadatos/licencia visibles y errores controlados.

**DETENTE:** informar y solicitar autorización para el siguiente runtime.

## BLOQUE 13 — Cierre de HTML5 y evaluación del siguiente motor
HTML5 solo se considera terminado si se cumplen todos estos puntos:

- [ ] Detección revisada y probada.
- [ ] Importación segura integrada.
- [ ] Biblioteca registra y muestra juegos.
- [ ] Runtime HTML5 se activa/instala según diseño aprobado.
- [ ] Juego de prueba local inicia y cierra.
- [ ] Recursos y rutas relativas funcionan.
- [ ] Errores y liberación de recursos probados.
- [ ] Seguridad revisada.
- [ ] Matriz Android/Linux actualizada.
- [ ] Documentación de instalación, uso y diagnóstico.
- [ ] Pruebas automatizadas ejecutadas y resultados registrados.
- [ ] Limitaciones conocidas documentadas.
- [ ] Ningún defecto crítico abierto.

Si falta algo, HTML5 no está terminado: crear lista de pendientes y pedir autorización para corregirlos. No empezar otro motor.

Una vez que el usuario confirme el cierre de HTML5, evaluar el siguiente motor. Orden preliminar:
1. TyranoScript/TyranoBuilder.
2. Ren’Py.
3. VNDS.
4. ONScripter.
5. RPG Maker MV/MZ.
6. KiriKiri/Kirikiroid2.
7. RPG Maker XP/VX/VX Ace.

Este orden es una propuesta, no una garantía. Investigar variantes, licencias, código reutilizable, plataformas y limitaciones antes de cada motor.

**DETENTE:** presentar evaluación del siguiente motor y esperar autorización expresa. No comenzar su implementación.

---

## 6. Criterios de calidad permanentes

### Código
- Separar interfaz, lógica de negocio, persistencia y ejecución.
- Evitar clases gigantes, dependencias circulares y excepciones ocultas.
- Manejar errores explícitamente.
- No dejar `TODO` críticos como si fueran funcionalidad terminada.
- Mantener nombres y estructura coherentes.

### Pruebas
- Unitarias para lógica aislada.
- Integración para base de datos, importación y runtime.
- Casos de error y entradas maliciosas, no solo casos ideales.
- Registrar comandos exactos y resultados.
- No eliminar pruebas para hacer pasar la suite.

### Seguridad
- Todo juego importado es contenido no confiable.
- No ejecutar al explorar, escanear o importar.
- Limitar tamaño, cantidad y profundidad de archivos extraídos.
- No confiar en extensiones ni metadatos del juego.
- Separar guardados de originales.
- Evitar permisos amplios Android.
- No incluir secretos en logs.

### Documentación
- `AGENT.md`: reglas permanentes.
- `VNE_EXECUTION_PLAN.md`: bloques y puntos de control.
- `CURRENT_STATUS.md`: estado real y siguiente tarea.
- `ROADMAP.md`: hitos generales.
- `DECISIONS.md`: decisiones aprobadas y razones.
- `CHANGELOG.md`: cambios relevantes.
- Documentación por runtime: compatibilidad, instalación, límites y pruebas.

## 7. Comandos de inspección sugeridos

Solo son comandos de consulta. Si una herramienta no existe, registrarlo; no instalarla durante una inspección.

```bash
pwd
git status --short --branch
git log --oneline -5
find . -maxdepth 4 -type f \
  -not -path './.git/*' \
  -not -path '*/build/*' \
  -not -path '*/.dart_tool/*' | sort
cat /etc/os-release
uname -m
git --version
flutter --version
dart --version
java -version
adb version
sdkmanager --version
clang --version
cmake --version
ninja --version
gcc --version
g++ --version
pkg-config --version
```

## 8. Instrucción de inicio

Al recibir este documento:
1. Leer `AGENT.md`, `CURRENT_STATUS.md` y este plan completo.
2. Ejecutar **únicamente el BLOQUE 0**.
3. No comenzar el bloque 1 en la misma ejecución.
4. Actualizar `CURRENT_STATUS.md` con hallazgos reales.
5. Entregar el informe de la sección 3.
6. Preguntar si el usuario autoriza el bloque 1.
7. Esperar.

**Este documento NO autoriza a ejecutar todos los bloques. La autorización se concede uno por uno.**
