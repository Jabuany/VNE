# Importación local · BLOQUE 7

En la biblioteca, abre **Importar carpeta** y elige un modo:

- **Copiar a VNE.** Conserva el original y guarda una copia en el área privada de VNE. La copia ocupa espacio adicional.
- **Referenciar carpeta.** Conserva la ubicación original. Moverla, modificarla o retirar el permiso de lectura puede afectar el acceso posterior. Android conserva un permiso de lectura para la carpeta seleccionada.

Linux usa el selector nativo de carpetas. Android usa el selector de documentos del sistema mediante `ACTION_OPEN_DOCUMENT_TREE` y limita los orígenes a los proveedores locales de almacenamiento del sistema. Algunas raíces y carpetas del sistema están restringidas por Android. Elige una subcarpeta que el selector permita abrir. VNE solicita acceso de lectura a la selección. [Storage Access Framework](https://developer.android.com/training/data-storage/shared/documents-files)

## Límites y publicación

- El límite es de 10 000 archivos y directorios, 32 niveles y 1 GiB por importación. Una referencia requiere tamaños verificables. En una copia también se limita el número real de bytes escritos.
- Se rechazan nombres ambiguos, rutas absolutas, separadores en nombres, duplicados sin distinción de mayúsculas y ciclos de directorios. En Linux x64 y arm64, las aperturas usan descriptores relativos y `openat2` para rechazar enlaces simbólicos y montajes anidados. Se requiere un kernel compatible y acceso a `/proc/self/fd`. [Resolución de rutas en Linux](https://man7.org/linux/man-pages/man2/openat2.2.html)
- El progreso muestra entradas y volumen copiado. La cancelación se comprueba entre entradas y bloques. Una lectura que ya está en curso debe terminar antes de procesarla. Cuando empieza la publicación en SQLite, la operación deja de ser cancelable.
- La biblioteca registra el juego después de validar el árbol y terminar la copia, si corresponde. Un fallo controlado o una cancelación elimina la copia temporal. Si el proceso o el equipo se apagan a mitad de una copia, puede quedar una carpeta privada sin registrar. La recuperación automática queda pendiente.
- Al terminar el recorrido se inspeccionan las cabeceras de los archivos HTML de la raíz y se consideran archivos característicos del paquete. El motor se asigna solo ante evidencia suficiente para sugerir un candidato. Consulta [detección y selección manual](deteccion.md).

## Archivos comprimidos

El selector admite carpetas. Para ZIP se identificó `archive` como candidato Dart con licencia MIT y soporte publicado en Android y Linux. La extracción requerirá pruebas de límites, rutas y cancelación antes de incorporarlo. 7z y RAR quedan pendientes de evaluación de bibliotecas, licencias y compatibilidad. Puedes extraer un archivo con una herramienta de confianza fuera de VNE y seleccionar la carpeta resultante. [Paquete archive](https://pub.dev/packages/archive)

## Dependencias

`file_selector_linux` 0.9.4+1 (BSD-3-Clause) aporta el selector nativo Linux. `ffi` 2.2.0 (BSD-3-Clause) ya estaba en el árbol de dependencias y pasó a ser directa para acceder a la apertura confinada en Linux. El selector Android usa las APIs del sistema para conservar la URI y leer el árbol. La alternativa para Linux sería mantener un selector nativo propio. [file_selector_linux](https://pub.dev/packages/file_selector_linux) · [ffi](https://pub.dev/packages/ffi)

La biblioteca nativa del selector en el paquete Linux x64 de depuración ocupa unos 162 KiB. El APK de depuración para tres arquitecturas creció unos 26 MiB respecto al BLOQUE 6. Esta medición incluye el código y los artefactos de depuración de toda la aplicación.
