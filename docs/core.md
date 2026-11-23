# Contratos del Core · API 1.0

Los contratos viven en `lib/src` y usan Dart sin importar Flutter. La aplicación será responsable de componer los servicios y presentar su estado. Los adaptadores de plataforma podrán usar APIs nativas por debajo del contrato.

| Módulo | Contrato |
| --- | --- |
| `core` | Juego y origen local mediante URI, ajustes, metadatos de guardado y diagnósticos locales. Una copia administrada y una referencia externa son modos distintos. El contenido de un guardado pertenece al runtime. |
| `detection` | Inspección sin ejecución, con evidencia y diagnósticos. Un candidato indica que hay evidencia para evaluar un motor. Si hay ambigüedad, la decisión pasa a la persona usuaria. El detector HTML5 existente conserva su método independiente. |
| `import` | Solicitud con modo de almacenamiento y selección opcional. Resultado tipado de éxito, selección pendiente o fallo. La biblioteca recibe el juego solo tras una importación resuelta. |
| `engine_api` | Un adaptador describe el backend y lanza una sesión. WebView, proceso externo y componente nativo pueden ofrecer el mismo contrato. La sesión expone cierre y eventos; pausa y guardado son interfaces opcionales. |
| `engine_manager` | Catálogo e inventario por plataforma y arquitectura, progreso, cancelación y retirada. La operación de instalación también permite actualizar una versión existente. |

## Versiones y compatibilidad

La API **1.0** se versiona de forma independiente de la versión del runtime y de la aplicación. Un host acepta un contrato del mismo número mayor cuyo número menor sea igual o inferior al suyo. El número mayor cambia con las incompatibilidades. Un paquete debe coincidir también con el destino de plataforma y arquitectura. Estas comprobaciones permiten filtrar candidatos. La instalación deberá verificar el manifiesto, HTTPS y SHA-256 antes de activar el paquete.

## Ciclo de vida y datos

Una solicitud de lanzamiento aporta el juego, sus ajustes y una ubicación de datos privada que proporciona la aplicación. El adaptador devuelve una sesión cuando arranca correctamente y libera recursos adquiridos si falla. La sesión entrega diagnósticos y un evento terminal al cerrar. El cierre debe ser seguro al repetirse. Las interfaces de pausa y guardado pueden estar ausentes, por lo que la UI puede presentar solo los controles disponibles.

La instalación solo se invoca tras confirmación del usuario. Un cambio de versión debe conservar la instalación anterior hasta que la nueva quede preparada. Una cancelación previa a la activación también la conserva. La desinstalación preserva juegos y guardados. Los diagnósticos se muestran localmente y deben omitir rutas privadas y credenciales.

## Transporte

La aplicación usa una sesión Dart tipada, con transporte definido dentro de cada adaptador. Permite probar el Core con independencia de la plataforma y mantener pequeñas las interfaces opcionales. Un protocolo serializado común puede evaluarse si se necesita distribuir adaptadores externos con interfaces de otro lenguaje.

El BLOQUE 5 cubre contratos y pruebas de sus reglas de compatibilidad y resultados. La persistencia, importación, gestión de paquetes y ejecución se implementan en sus bloques.
