# Validación del runtime HTML5

La validación usa la [escena propia del repositorio](../test/fixtures/html5/). Instala o activa el reproductor desde el [catálogo de Motores](catalogo-html5.md).

| Caso | Debian 13.8 x64 · Wayland · WebKitGTK 2.54.3 | Android 15 · WebView 157 |
| --- | --- | --- |
| Apertura, cierre y entrada inexistente | Probados con el adaptador y el auxiliar confinado. | Probados en el teléfono, en la variante aislada. |
| HTML, CSS, JavaScript, imagen, fuente y JSON | Probados con la escena. | Probados con la misma escena. |
| Audio WAV | Carga y decodificación probadas. Un gesto GTK en la prueba inició WebAudio y PulseAudio detectó el flujo activo. | Carga y decodificación probadas. Un toque de prueba dentro de la vista inició WebAudio. |
| Navegación externa y archivo ausente | Petición externa bloqueada, navegación externa rechazada y respuesta local 404 comprobadas. | Petición externa bloqueada, navegación externa rechazada y respuesta local 404 comprobadas. |
| Persistencia y aislamiento | Probados. El mismo juego incrementó el contador y el segundo perfil empezó en 1. | Probados. El mismo juego incrementó el contador y el segundo perfil conservó su propio valor. |
| Tamaño y controles | La escena siguió funcionando en viewports de 960 × 554 y 645 × 774. Puntero, silencio, entrada con F11 y salida con Escape comprobados mediante eventos de prueba. El compositor confirmó ambos estados de pantalla completa. | Se comprobaron viewports de 392 × 746 y 839 × 276, pausa y reanudación por canal, y ocultación y restauración de las barras de sistema. |
| Fuente de archivos | Carpeta referenciada desde Linux, enlazada en solo lectura al abrir el juego. | Copia privada probada con la escena completa. Apertura y cierre comprobados con la entrada de una referencia SAF persistente. |
| Medios con rangos | El servidor atiende rangos simples y se probó el cálculo de límites. Búsqueda durante reproducción pendiente. | El prototipo entrega archivos completos. |

## Ejecutar en Linux

El auxiliar usa Python 3, PyGObject, GTK 3, WebKitGTK 4.1 y Bubblewrap con soporte de `--ro-bind-fd`. Se comprobó con Bubblewrap 0.12.0 y Wayland en Debian. Para audio usa el socket compatible con PulseAudio, si está disponible. No se añadieron paquetes del sistema durante el bloque.

```sh
flutter build linux --debug
build/linux/x64/debug/bundle/vne
/usr/bin/python3 -B -m unittest discover -s test -p linux_html5_player_test.py -v
```

Instala HTML5 desde **Motores**, importa la muestra de prueba y abre **Reproducir**. En la ventana nativa puedes volver, mostrar pantalla completa o silenciar el audio. F11 alterna pantalla completa y Escape sale de ella. El contrato de pausa queda deshabilitado en Linux porque silenciar y ocultar la ventana no suspende de forma fiable toda la actividad de WebKit.

El auxiliar abre la carpeta mediante un descriptor sin seguir enlaces y Bubblewrap la monta en solo lectura. Los recursos se sirven desde una dirección loopback dentro de un espacio de red independiente. Esto mantiene un origen web convencional para `fetch` y `localStorage` sin exponer el puerto al anfitrión. WebKit conserva su sandbox interno. Cada juego usa un directorio de datos distinto. El proceso no recibe el directorio personal ni el bus general de sesión. Como resultado, el bus de accesibilidad GTK queda fuera de esta validación.

## Ejecutar en Android

Usa la [guía del APK offline](reproductor-android.md). Para completar las pruebas manuales en ambos destinos, abre la muestra, pulsa **Probar audio**, verifica que el sonido se oye, cambia el tamaño o la orientación y comprueba los controles de regreso y pantalla completa.
