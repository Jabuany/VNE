# AGENT.md --- VNE (Visual Novel Engine)

## 1. Contexto del proyecto

VNE es un reproductor multiplataforma de novelas visuales y juegos
narrativos. Su primera meta es Android, Windows y Linux, con desarrollo
inicial y pruebas en Debian.

La aplicación permite que el usuario importe juegos que tenga derecho a
utilizar y los ejecute mediante intérpretes o runtimes compatibles. VNE
no aloja, incluye ni distribuye juegos. Tampoco debe incorporar enlaces
a copias no autorizadas ni eludir DRM.

El proyecto tendrá una arquitectura híbrida y modular: - Aplicación
principal para biblioteca, importación, configuración, controles y
administración. - API común para comunicarse con los motores. -
Adaptadores e intérpretes independientes por motor. - Catálogo de
motores instalables bajo demanda.

## 2. Decisiones técnicas acordadas

-   Aplicación principal: Flutter + Dart.
-   Base de datos local: SQLite.
-   Plataformas objetivo iniciales: Android, Windows y Linux.
-   Entorno de desarrollo actual: Debian.
-   Código nativo cuando sea necesario: C/C++, Kotlin/Android NDK y APIs
    específicas de cada plataforma.
-   Contenido de juegos: archivos locales importados por el usuario.
-   Arquitectura: híbrida; reutilizar proyectos existentes solo cuando
    sus licencias y condiciones permitan integrarlos, y crear
    adaptadores o intérpretes propios cuando sea necesario.

No cambies estas decisiones sin explicar primero la razón y pedir
confirmación al usuario.

## 3. Motores previstos

La compatibilidad deseada incluye: 1. HTML5. 2. TyranoScript /
TyranoBuilder. 3. Ren'Py. 4. VNDS. 5. ONScripter. 6. RPG Maker MV/MZ. 7.
KiriKiri y compatibilidad con juegos utilizados mediante Kirikiroid2. 8.
RPG Maker XP/VX/VX Ace.

Esta lista es el objetivo a largo plazo, no una promesa de
compatibilidad inmediata. No afirmes que un juego funciona solo porque
se reconoce su extensión o motor. Las versiones, plugins, modificaciones
y dependencias pueden afectar la compatibilidad.

## 4. Desarrollo estrictamente secuencial por intérprete

**Regla fundamental: terminar y validar un intérprete antes de comenzar
la integración del siguiente.**

No desarrolles varios intérpretes en paralelo. No agregues esqueletos
vacíos de todos los motores para aparentar avance. Mantén la API
preparada para futuras integraciones, pero trabaja en un único
intérprete activo.

Orden inicial recomendado: 1. Runtime HTML5 básico. 2. Adaptador
TyranoScript. 3. Ren'Py. 4. VNDS. 5. ONScripter. 6. RPG Maker MV/MZ. 7.
KiriKiri. 8. RPG Maker XP/VX/VX Ace.

Este orden puede revisarse si el análisis técnico demuestra que una
integración no es viable, pero no se debe saltar de motor por
conveniencia sin documentar la decisión.

### Definición de "intérprete terminado"

Un motor no se considera terminado hasta que: - Se haya documentado qué
versiones y características soporta. - Se haya comprobado la licencia y
procedencia de sus componentes. - Se pueda instalar, actualizar y
desinstalar de forma controlada. - Se pueda detectar o seleccionar
manualmente para un juego. - Pueda iniciar, pausar/reanudar cuando el
runtime lo permita, y cerrar correctamente. - Se gestionen errores y
registros. - Se validen recursos gráficos, audio, fuentes y entrada que
correspondan al motor. - Se pruebe el guardado/cargado si el motor lo
soporta; si no, se documenta la limitación. - Existan pruebas
automatizadas y un conjunto de juegos de prueba legales. - Se pruebe en
cada plataforma declarada como compatible. - Se documente cualquier
incompatibilidad conocida. - El usuario pueda instalarlo bajo demanda
desde el administrador de motores.

No declares terminado un motor con una demo que solo abre una escena o
un archivo de ejemplo.

## 5. Instalación de intérpretes bajo demanda

**No descargar ni instalar todos los intérpretes junto con la
aplicación.**

El usuario debe poder elegir qué motor instalar. La instalación debe ser
explícita, visible y opcional. El instalador de VNE puede incluir
únicamente el núcleo de la aplicación y los componentes indispensables
para mostrar la interfaz.

El administrador de motores debe contemplar: - Catálogo de motores
disponibles. - Descripción, versión, tamaño de descarga y espacio
estimado instalado. - Plataformas y arquitecturas compatibles. -
Licencia y avisos de terceros. - Estado: no instalado, descargando,
instalado, actualización disponible o error. - Descarga e instalación
bajo demanda. - Progreso, cancelación y reintento. - Verificación de
integridad mediante hash criptográfico. - Actualización controlada y
posibilidad de volver a una versión anterior cuando sea viable. -
Desinstalación y cálculo del espacio recuperable. - Detección de motores
requeridos por los juegos importados. - Mensaje claro cuando un juego
necesita un motor que aún no está instalado.

Nunca descargues un runtime silenciosamente al importar o abrir un
juego. Antes de descargar, informa tamaño, espacio requerido, licencia y
plataforma. Pide confirmación.

### Seguridad del catálogo

-   No ejecutes instaladores o scripts descargados sin validación.
-   Usa HTTPS.
-   Mantén un manifiesto versionado con URL, versión, plataforma,
    arquitectura, tamaño, hash SHA-256 y licencia.
-   Verifica el hash antes de instalar.
-   No aceptes rutas arbitrarias ni extracción de archivos fuera del
    directorio destino.
-   Evita path traversal y archivos comprimidos maliciosos.
-   No inventes URLs, hashes, versiones ni licencias. Si todavía no hay
    infraestructura de distribución, crea una interfaz local/mock y
    documenta que el catálogo remoto está pendiente.
-   No incorpores binarios de terceros al repositorio sin revisar
    licencia y procedencia.

## 6. Arquitectura y separación de responsabilidades

Mantén separadas estas áreas: - `app`: interfaz Flutter y navegación. -
`core`: modelos y servicios compartidos. - `library`: biblioteca de
juegos. - `import`: selección, inspección y extracción segura. -
`detection`: detección de motores con evidencias y nivel de confianza. -
`engine_api`: contratos comunes. - `engine_manager`: catálogo,
instalación, actualización y desinstalación de runtimes. - `player`:
ciclo de vida de ejecución y comunicación con el runtime. - `saves`:
gestión de partidas, sin asumir que todos los motores usan el mismo
formato. - `input`: teclado, ratón, controles y entrada táctil. -
`storage`: rutas y persistencia específica por plataforma. -
`diagnostics`: logs y reportes de errores. - `engines/<engine_id>`:
adaptador e integración del intérprete activo.

La interfaz no debe depender de detalles internos de un motor. Los
motores no deben depender de widgets Flutter.

Define contratos explícitos y versionados. Distingue entre: 1.
Adaptador, que conecta VNE con un motor. 2. Runtime, que ejecuta
realmente el juego. 3. Paquete instalable, que contiene los componentes
necesarios para una plataforma concreta.

No presupongas que todos los motores pueden ejecutarse en el mismo
proceso. Permite procesos separados, bibliotecas nativas o WebView según
el motor y la plataforma.

## 7. Detección e importación de juegos

-   No confíes únicamente en extensiones de archivo.
-   Examina estructuras, manifiestos y archivos característicos.
-   Devuelve evidencias y nivel de confianza.
-   Si hay ambigüedad, solicita selección manual.
-   No ejecutes scripts durante la inspección o importación.
-   La extracción debe ser segura y limitar rutas, tamaño y cantidad de
    archivos.
-   Conserva los archivos originales cuando sea posible.
-   Permite referenciar una carpeta externa o copiarla a la biblioteca,
    explicando ambas opciones.
-   No alteres los archivos originales del juego sin consentimiento.

## 8. Plataformas y Debian

El entorno de desarrollo inicial es Debian. Antes de instalar
dependencias o modificar el sistema: - Inspecciona la versión de Debian,
arquitectura, Flutter, Dart y herramientas existentes. - Explica qué
dependencia hace falta y por qué. - No uses `sudo` ni ejecutes cambios
globales sin autorización explícita. - Prefiere herramientas
reproducibles y documenta versiones. - No asumas que una ruta o paquete
existe sin comprobarlo.

Para Linux, prioriza compatibilidad con Debian/Ubuntu inicialmente.
Mantén el diseño portable para otras distribuciones, pero no declares
soporte para ellas hasta probar paquetes y dependencias.

En Android, respeta el almacenamiento moderno y usa el selector de
archivos/documentos cuando sea adecuado. No solicites permisos de
almacenamiento amplios sin necesidad.

## 9. Calidad, pruebas y documentación

-   Escribe pruebas unitarias para lógica de dominio y detección.
-   Escribe pruebas de integración para importación, instalación y ciclo
    de vida del motor.
-   Añade pruebas de interfaz para los flujos principales.
-   Usa juegos de prueba propios, de dominio público o con licencia que
    permita su uso en pruebas.
-   No incluyas juegos comerciales ni recursos sin permiso en el
    repositorio.
-   Registra limitaciones y resultados reales; no inventes
    compatibilidad.
-   Mantén README, documentación de arquitectura, instrucciones de
    compilación y matriz de compatibilidad actualizados.
-   Añade `THIRD_PARTY_NOTICES` y archivos de licencia cuando
    corresponda.

## 10. Seguridad y privacidad

-   Los juegos importados son datos no confiables.
-   No ejecutes código al escanear o importar.
-   Aísla los runtimes cuando sea posible.
-   Limita acceso a archivos y permisos.
-   No transmitas nombres, rutas ni contenido de la biblioteca del
    usuario.
-   No añadas telemetría ni analítica sin consentimiento explícito.
-   Evita que un juego pueda sobrescribir archivos de otros juegos o del
    núcleo de VNE.

## 11. Flujo de trabajo que debe seguir Codex

En cada tarea: 1. Inspecciona el repositorio y lee esta guía y la
documentación relacionada. 2. Resume brevemente el estado actual y qué
vas a cambiar. 3. Propón un plan pequeño y verificable. 4. Implementa
solo el alcance solicitado; evita refactorizaciones no relacionadas. 5.
Ejecuta formato, análisis estático y pruebas relevantes. 6. Corrige los
errores introducidos por los cambios. 7. Actualiza documentación y
ejemplos cuando cambie una interfaz. 8. Resume archivos modificados,
pruebas ejecutadas, resultados y pendientes.

Antes de hacer cambios grandes, migraciones, descargas de runtimes,
añadir dependencias nativas o modificar el sistema operativo, explica el
impacto y pide autorización.

No afirmes que una prueba pasó si no la ejecutaste. No ocultes pruebas
fallidas. Si no puedes ejecutar una prueba, indícalo claramente.

## 12. Reglas de implementación

-   Prioriza código claro, modular y mantenible.
-   Evita dependencias innecesarias.
-   No añadas abstracciones prematuras.
-   No uses APIs ficticias ni inventes métodos de bibliotecas.
-   Consulta documentación oficial y licencias antes de integrar
    proyectos externos.
-   Fija versiones de dependencias cuando sea razonable.
-   Maneja errores de forma explícita.
-   No guardes secretos ni tokens en el repositorio.
-   No crees implementaciones vacías que aparenten funcionar.
-   No marques características como completadas si solo tienen una
    interfaz visual.

## 13. Primera tarea del proyecto

Al iniciar un repositorio nuevo: 1. Inspecciona el entorno Debian y
comprueba si Flutter está instalado. 2. Si no está instalado, informa de
los pasos necesarios; no instales nada sin autorización. 3. Crea la
estructura mínima de Flutter para Android, Windows y Linux, según las
herramientas disponibles. 4. Establece la arquitectura base y los
contratos mínimos. 5. Implementa la biblioteca local básica y la
persistencia SQLite solo en el alcance necesario. 6. Diseña el
administrador de intérpretes bajo demanda, inicialmente con un catálogo
local de ejemplo claramente identificado como demostración. 7. Comienza
exclusivamente con el runtime HTML5. 8. No empieces TyranoScript ni
ningún otro motor hasta que HTML5 cumpla la definición de terminado de
la sección 4.

El primer objetivo no es producir muchas pantallas: es establecer una
base funcional, verificable y segura para incorporar un intérprete
completo cada vez.
