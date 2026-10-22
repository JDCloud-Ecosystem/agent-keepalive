---
status: "accepted"
date: 2026-10-22
decision-makers: JohnyDeCoder
spec: ~
---

# Los datos de la persona viven en ~/.config/agent-keepalive

## Contexto y planteamiento del problema

Cada instalación guardaba su `config.sh` y sus logs dentro de la carpeta del código, junto a los scripts, y solo
el token de Claude vivía en `~/.config/agent-keepalive/`. Así una actualización tenía que esquivar los datos de la
persona, borrar o volver a clonar la carpeta los perdía, y el `.gitignore` tenía que nombrar cada archivo que la
herramienta escribe. Al ordenar el repositorio en `lib/` y `scripts/` hay que decidir dónde queda lo que la
persona configura y lo que se acumula con el uso.

## Factores de decisión

- Que el código y los datos no compartan carpeta, así una actualización solo toca código.
- Un solo lugar que respaldar, revisar o borrar, con permisos que solo ve su dueño.
- Que una instalación de antes siga enviando a la hora de siempre, sin un paso a mano.
- Que los programas de fuera que leen estos archivos sigan funcionando mientras se actualizan.

## Opciones consideradas

- Todo en `~/.config/agent-keepalive/`, donde ya vive el token
- La configuración en `~/.config` y los logs en `~/.local/state`, como pide XDG
- Dejarlo junto al código, como hasta ahora

## Resultado de la decisión

Opción elegida: «Todo en `~/.config/agent-keepalive/`, donde ya vive el token», porque deja un solo lugar con modo
700 para todo lo de la persona, que ya existía y que las instalaciones y los programas de fuera ya conocen por el
token.

### Consecuencias

- Bien, porque la carpeta del código queda limpia, y `git status` en una instalación solo muestra cambios a mano.
- Bien, porque desinstalar es borrar una carpeta, y respaldar es copiarla.
- Mal, porque dos instalaciones del mismo usuario comparten horario e historial. Con una por usuario, que es lo
  normal, no se nota.
- Mal, porque volver a una versión anterior a este cambio no encuentra `config.sh`. Se arregla copiando
  `~/.config/agent-keepalive/config.sh` a la carpeta del código.
- Neutral, porque los logs no son configuración y XDG los pondría aparte; se gana un solo lugar a cambio.

### Confirmación

`lib/load.sh` define `CONFIG_FILE` y `LOG_DIR` dentro de `STATE_DIR`, y `migrate_data` en `lib/settings.sh` mueve
los datos de una instalación de antes. `tests/drive.py` lo prueba en `t_moves_old_data`, con dos envíos que
empiezan juntos, y en `t_update_from_1_0_1`, que actualiza la 1.0.1 publicada con su propio `keepalive update` y
la deja enviando.

## Ventajas y desventajas de las opciones

### Todo en `~/.config/agent-keepalive/`

- Bien, porque la carpeta ya existía con modo 700 y la conocía cada programa que lee el token.
- Mal, porque mezcla configuración con historial.

### Configuración en `~/.config` y logs en `~/.local/state`

- Bien, porque sigue la especificación de XDG al pie de la letra.
- Mal, porque son dos lugares que respaldar, migrar y borrar, y otro más que los programas de fuera tendrían que
  conocer.

### Junto al código

- Bien, porque no hay nada que migrar.
- Mal, porque cada actualización y cada clon nuevo tienen que cuidar archivos que no son código.

## Más información

**Origen:** la issue #14.
