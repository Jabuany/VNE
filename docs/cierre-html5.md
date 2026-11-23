# Revisión de cierre de HTML5 · BLOQUE 13

**Estado:** validado como prototipo funcional en Debian 13.8 x64 con Wayland y en Android 15. Cierre formal pendiente. El alcance probado cubre juegos web locales sin conexión, con las limitaciones de la [matriz](compatibilidad-html5.md).

| Criterio del plan | Resultado de la revisión |
| --- | --- |
| Detección revisada y probada | Cumplido. Se conservan evidencia, confianza, versión del detector y corrección manual. |
| Importación segura integrada | Cumplido para carpetas copiadas o referenciadas. Se prueban confinamiento, límites y cancelación. Los archivos comprimidos quedan fuera del alcance actual. |
| Biblioteca registra y muestra juegos | Cumplido. Persistencia SQLite, listado, búsqueda y detalles probados. |
| Runtime se activa según el diseño | Cumplido para instalación local verificada en Linux y activación del WebView en Android. La actualización y la reversión se probaron con versiones sintéticas. La publicación Linux sigue pendiente. |
| Juego local inicia y cierra | Cumplido con la escena propia en los dos entornos de la matriz. |
| Recursos y rutas relativas | Cumplido con la escena. Se probaron CSS, JavaScript, imagen, fuente, JSON y WAV. |
| Errores y liberación de recursos | Cumplido para los casos probados, incluidos 404, entrada ausente, cierre de sesión y limpieza del auxiliar temporal tras un cierre ordinario. |
| Seguridad revisada | Revisados la procedencia e integridad del paquete, la resolución de recursos, el aislamiento, los rechazos de navegación y los perfiles. El APK offline no declara permiso de Internet. |
| Matriz y documentación | Cumplido. La matriz registra plataforma y versiones probadas, instrucciones y limitaciones. Esta revisión añade diagnóstico. |
| Pruebas automatizadas registradas | Cumplido. Consulta el registro del bloque para los resultados de la repetición. |
| Defectos críticos | No se identificaron defectos críticos en los recorridos revisados. |
| Conjunto de juegos legales de prueba | **Pendiente.** El repositorio tiene una escena propia y se ejercitaron dos perfiles. Falta una segunda muestra independiente que cubra guardado y carga explícitos y una estructura distinta. |
| Licencia y publicación del auxiliar Linux | **Pendiente.** Las dependencias de terceros están documentadas. Falta decidir y registrar la licencia del código propio para el artefacto de distribución y el origen de publicación. El catálogo actual permite instalar el paquete local. |

## Diagnóstico de fallos comunes

| Síntoma | Qué comprobar |
| --- | --- |
| HTML5 no está disponible | Abrir **Motores** y comprobar si está instalado o activado. En Android, usar el APK offline y un proveedor WebView con perfiles múltiples y renderizador separado. |
| SHA-256 o tamaño no coincide | Volver a obtener el archivo de la revisión indicada por el catálogo. Una copia incompleta o una versión distinta se rechazan antes de arrancar. |
| La entrada del juego no carga | Revisar la entrada de la ficha y la presencia del archivo. Si es una referencia, comprobar que la carpeta sigue en su lugar y que el permiso SAF sigue vigente. |
| WebKitGTK no inicia | Comprobar Wayland, Bubblewrap con `--ro-bind-fd`, Python con PyGObject y WebKitGTK 4.1. El auxiliar se detiene cuando no puede abrir la sesión con el confinamiento exigido. |
| El juego pierde el sonido al pausar | El audio de la muestra requiere un gesto. Android reanuda la vista y el juego conserva el control de su audio. Linux ofrece silencio y cierre. |

Los datos web se guardan por juego. La prueba existente verifica persistencia y separación mediante `localStorage`. La API de ranuras de VNE sigue sin implementarse. Distribuciones adicionales, X11, códecs y búsqueda dentro de medios necesitan pruebas propias antes de anunciarlos.

## Punto de control

Para cerrar HTML5, completar la segunda muestra y acordar la licencia y el origen de distribución del auxiliar Linux. La evaluación de TyranoScript queda después de que se confirme el cierre de HTML5.
