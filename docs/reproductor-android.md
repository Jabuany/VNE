# Reproductor HTML5 de desarrollo en Android

Para probar el reproductor con una APK de depuración sin permiso de Internet, compila desde la raíz:

```sh
export JAVA_HOME=/home/osorio/SDK/temurin-21.0.13.1
export ANDROID_HOME=/home/osorio/SDK/android
VNE_HTML5_OFFLINE=1 flutter build apk --debug
"$ANDROID_HOME/platform-tools/adb" install -r build/app/outputs/flutter-apk/app-debug.apk
```

VNE comprueba que la app carece del permiso de Internet antes de abrir el juego. Esta variante se prueba con un APK ya compilado. La variante habitual de depuración conserva el permiso requerido por las herramientas de Flutter.

En **Biblioteca → Motores**, activa HTML5. Importa `test/fixtures/html5` como carpeta local de prueba y abre su ficha. Pulsa **Reproducir**. La pantalla nativa ofrece **Volver**, **Pausar** y **Pantalla completa**. El volumen usa las teclas multimedia del teléfono. Android WebView recibe el toque, el zoom y la entrada de teclado o ratón que entregue el dispositivo.

## Alcance

- Los archivos se entregan desde un origen HTTPS local por juego. Las copias privadas y las referencias SAF se abren en modo de lectura. Una referencia requiere que el permiso siga vigente.
- El runtime exige un WebView con perfiles múltiples y renderizador separado. Ante un proveedor incompatible o una entrada ausente, la biblioteca muestra un diagnóstico.
- Cada juego tiene un perfil persistente separado. El prototipo permite probar `localStorage`. La API explícita de ranuras de guardado sigue pendiente.
- La pausa suspende temporizadores y reproducción de elementos de audio o vídeo. Si el proveedor admite silenciar WebView, también silencia la vista en pausa o en segundo plano. La reanudación de audio depende del juego.
- La primera versión atiende archivos locales completos. La reproducción con rangos, codecs adicionales, WebAssembly, workers y contenido de red quedan pendientes de validación. El reproductor de Linux tiene una [guía y matriz propias](compatibilidad-html5.md).
- La compilación offline habilita los requisitos de aislamiento. La activación del motor se confirma en [Motores](catalogo-html5.md).

La muestra es propia. Incluye una escena HTML, CSS y JavaScript, una imagen SVG, una fuente simple creada para la prueba y un tono PCM generado. **Recursos OK · red bloqueada** indica que se cargaron los recursos, que un archivo ausente devolvió 404 y que la petición externa quedó bloqueada. **Probar audio** requiere un gesto. Al reabrir la escena, **Visita** permite comprobar persistencia, y una importación separada comprueba el perfil de otro juego.
