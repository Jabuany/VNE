# Detección web · BLOQUE 8

Al importar, VNE inspecciona hasta 16 archivos HTML o HTM de la raíz y lee hasta 4096 bytes de cada uno. Da prioridad a `index.html` y `index.htm` y conserva las mayúsculas del nombre real. También registra la presencia de archivos característicos encontrados durante el recorrido confinado.

| Resultado | Evidencia y efecto |
| --- | --- |
| Contenido desconocido | La inspección acotada no encontró una cabecera HTML reconocible. |
| HTML genérico | Hay una entrada HTML, con evidencia insuficiente para asignar un motor. Si hay varias entradas y ninguna es convencional, la persona usuaria elige. |
| Posible juego web | Hay una entrada y se encontraron `game.js` y `game.json` o `game.wasm` en la raíz. Se sugiere HTML5. |
| Motor web identificado | Una entrada convencional y los archivos `tyrano/tyrano.js` y `tyrano/plugins/kag/kag.js` identifican una estructura de TyranoScript. Un marcador aislado evita la asignación genérica automática. [Estructura publicada de TyranoScript](https://github.com/ShikemokuMK/tyranoscript/blob/master/index.html) |

La clasificación es estática. Puede omitir juegos con una estructura distinta, entrada anidada o cabecera fuera del límite. Una página ajena a un juego podría compartir marcadores. Un candidato no implica que el contenido sea reproducible. La identificación de TyranoScript registra su estructura y no incorpora su intérprete.

En los detalles de un juego, **Cambiar motor** permite seleccionar HTML5 con una de las entradas reconocidas, dejar el juego sin motor o restaurar la selección automática cuando hay un informe guardado. La corrección manual conserva la evidencia. El runtime deberá verificar la entrada cuando se implemente el lanzamiento, especialmente para carpetas referenciadas que pueden cambiar.

## Persistencia

El esquema SQLite 2 guarda la versión del detector, la clasificación, la confianza, la evidencia y las entradas observadas en `game_detection`. El juego y el informe se guardan en la misma transacción. La preferencia manual se registra por separado.

Al migrar desde el esquema 1 se conservan los juegos, los ajustes y la selección previa. Hasta una nueva importación, esos juegos figuran sin informe y pueden conservar o corregir una entrada registrada. Para respaldar el archivo antes de actualizar, consulta la [guía de biblioteca](biblioteca.md).
