# Catálogo e instalación de HTML5

En **Biblioteca → Motores** se muestran la plataforma, la arquitectura, la versión, la API, el origen, la licencia, el tamaño y el SHA-256. Cada operación requiere confirmación. La biblioteca conserva los juegos y los guardados al cambiar o desinstalar el motor.

## Linux

El catálogo local reconoce el auxiliar de VNE fijado en esta revisión. El archivo no se incluye en el bundle Flutter. Para preparar el paquete local de desarrollo desde la raíz:

```sh
mkdir -p build/runtime-packages
cp runtime/html5/linux/player.py build/runtime-packages/vne-html5-linux-0.1.0.py
sha256sum build/runtime-packages/vne-html5-linux-0.1.0.py
```

En **Motores**, elige **Instalar**, revisa la información y confirma. Selecciona ese archivo en el diálogo. El nombre del archivo puede variar. VNE exige los bytes exactos fijados por el catálogo y comprueba el SHA-256 otra vez antes de iniciar el auxiliar en el sandbox. Consulta los requisitos de [Linux y la matriz de compatibilidad](compatibilidad-html5.md).

El canal HTTPS se puede configurar al compilar con `--dart-define=VNE_HTML5_PACKAGE_URL=URL_HTTPS_VERIFICADA`. Debe apuntar al mismo artefacto fijado en el catálogo. Se verifica TLS con el almacén normal, se rechazan redirecciones y se pide el contenido sin compresión de transporte. La versión actual no trae un origen remoto predeterminado. La publicación de paquetes Linux queda pendiente de definir su licencia de redistribución y su destino. Se verificó la descarga HTTPS con los bytes propios del repositorio fijados por revisión como prueba controlada.

## Android

El APK contiene la integración AndroidX y usa el proveedor WebView del sistema. En **Motores**, pulsa **Activar** y confirma con una compilación offline compatible. El instalador verifica el descriptor incluido y registra la selección localmente. Esta operación no descarga WebView. Desinstalar HTML5 desde VNE retira la activación y mantiene WebView, sus datos de perfil y los juegos. WebView recibe sus actualizaciones por el canal del dispositivo. [Compilar el APK offline](reproductor-android.md)

## Actualizaciones, reversión y cancelación

La versión activa y una versión anterior verificada se guardan como paquetes en una base SQLite de motores separada. El tamaño que muestra el catálogo corresponde a los bytes de cada paquete. SQLite y el archivo de sesión Linux añaden espacio temporal o metadatos. Al desinstalar, se retiran las versiones guardadas y se intenta recuperar el espacio libre de SQLite. La activación se publica en una transacción después de verificar tamaño y digest. La actualización fallida o cancelada conserva el paquete anterior. Con dos versiones, **Cambiar a…** verifica el otro paquete y lo intercambia con el activo. Después de un fallo de red, de archivo o de integridad, se puede reintentar.

Para publicar una actualización de VNE con otro paquete del motor, mantener en el catálogo las huellas de las versiones que se quiera admitir para reversión. Se admite un solo paquete binario u objeto de activación por versión. El JSON interno y los nombres de fichero de trabajo los genera VNE. El instalador no extrae archivos ni ejecuta comandos de instalación.

## Pruebas

En Debian con Wayland, ejecuta la prueba de instalación y arranque del auxiliar:

```sh
flutter test test/local_runtime_manager_test.dart \
  --dart-define=VNE_TEST_LINUX_RUNTIME=true
```

Para comprobar también el transporte HTTPS, añade `--dart-define=VNE_TEST_PACKAGE_URL=URL_HTTPS_VERIFICADA` con un origen que entregue exactamente el paquete fijado en el catálogo. Las pruebas de actualización y reversión usan dos versiones sintéticas. La prueba de interfaz comprueba que cancelar la confirmación deja el motor sin activar.
