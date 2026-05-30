# claude-keepalive

Mantiene activas las sesiones de **Claude Code** y **Codex** enviando mensajes automáticos al día mediante cron. Soporta hasta 3 sesiones diarias (mañana, tarde y noche opcional), configurables de forma independiente. Codex se instala automáticamente pero su cron está desactivado por defecto.

> **Plataforma:** Ubuntu Server (Linux). El desarrollo puede hacerse en Windows — el archivo `.gitattributes` fuerza saltos de línea LF para que los `.sh` lleguen sin corrupción al servidor.

---

## Qué hace

```
07:00 → [MORNING]   Envía mensajes a Claude y/o Codex  (reinicia el contador de 5 horas)
12:00 → [AFTERNOON] Envía mensajes a Claude y/o Codex  (reinicia el contador de 5 horas)
17:00 → [NIGHT]     Envía mensajes a Claude y/o Codex  (opcional, desactivado por defecto)
```

Cada sesión y cada herramienta (Claude / Codex) se activan o desactivan de forma independiente desde `bash update-schedule.sh`. Los logs se guardan en archivos separados: `sessions.log` (Claude) y `codex-sessions.log` (Codex).

---

## Requisitos

| Requisito              | Notas                                         |
| ---------------------- | --------------------------------------------- |
| Ubuntu Server / Debian | `apt-get` debe estar disponible               |
| Acceso `sudo`          | Necesario una sola vez para instalar paquetes |
| Conexión a internet    | Para descargar Node.js y Claude Code          |

---

## Instalación desde cero

Clona el repositorio en tu servidor Linux y ejecuta el instalador:

```bash
git clone https://github.com/JDCloud-Ecosystem/claude-keepalive.git
cd claude-keepalive
bash install.sh
```

> Si no tienes `git` instalado aún:
>
> ```bash
> sudo apt-get install -y git
> ```

El instalador hace todo automáticamente:

1. Pregunta el idioma (**Español / English**) con una TUI o prompt de texto
2. Instala `git`, `curl`, `cron` y `whiptail` (solo si faltan)
3. Instala **Node.js LTS** vía NodeSource (solo si falta)
4. Instala **Claude Code** vía `npm install -g @anthropic-ai/claude-code` (solo si falta)
5. Instala **Codex** vía `npm install -g @openai/codex` (solo si falta)
6. Crea `config.sh` con el horario por defecto (lunes a viernes, 07:00 y 12:00; noche y Codex desactivados)
7. Registra los cron jobs
8. Muestra un resumen

> **En Guacamole:** usa **Ctrl+Alt+Shift** para abrir el panel lateral, sube los archivos via "Devices → Upload Files", y luego ejecuta `bash install.sh` en la terminal SSH.

---

## Primer inicio de sesión (obligatorio)

El instalador no puede autenticarte automáticamente. Al terminar `install.sh`, ejecuta cada herramienta que vayas a usar:

```bash
claude login   # Autenticar Claude Code
codex login    # Autenticar Codex (solo si lo vas a usar)
```

Las credenciales se guardan en sus respectivos directorios de configuración y son privadas para tu usuario.

---

## Verificar la instalación

```bash
bash test.sh
```

El smoke test comprueba:

- ✓ Sistema operativo Linux
- ✓ Servicio cron activo
- ✓ Claude Code instalado
- ✓ `config.sh` existe
- ✓ Entradas en crontab presentes
- ✓ `session-starter.sh` se ejecuta y escribe en el log

El código de salida es `0` si todo pasa, distinto de cero si hay fallos.

---

## Editar el horario (TUI)

```bash
bash update-schedule.sh
```

La interfaz gráfica de terminal (whiptail) permite:

- Seleccionar cualquier combinación de días con flechas y Espacio
- Activar o desactivar cada sesión (mañana, tarde, noche) de forma independiente
- Activar o desactivar Codex (se ejecuta en el mismo horario que Claude cuando está activo)
- Configurar la hora y minuto de cada sesión activa
- Confirmar antes de aplicar

Los cambios se escriben en `config.sh` y el crontab se actualiza de inmediato, sin pasos adicionales.

---

## Archivos

| Archivo              | Tipo     | Descripción                                                |
| -------------------- | -------- | ---------------------------------------------------------- |
| `install.sh`         | repo     | Instalador principal — ejecutar una vez                    |
| `session-starter.sh` | repo     | Script que ejecuta cron (no eliminar)                      |
| `update-schedule.sh` | repo     | Editor de horario con TUI                                  |
| `test.sh`            | repo     | Smoke test                                                 |
| `uninstall.sh`       | repo     | Elimina todo                                               |
| `config.sh`          | generado | Configuración de horario e idioma (ignorado por git)       |
| `sessions.log`       | generado | Log de Claude, rotación automática (ignorado por git)      |
| `codex-sessions.log` | generado | Log de Codex, rotación automática (ignorado por git)       |

---

## Ver el log

```bash
cat sessions.log
```

Hay dos archivos de log separados, uno por herramienta. Cada línea incluye la etiqueta de sesión (`[MORNING]`, `[AFTERNOON]`, `[NIGHT]`):

**`sessions.log`** — Claude:
```
[2026-05-28 07:00:01] [MORNING] Starting session reset
[2026-05-28 07:00:03] [MORNING] Reset: Session initialized...
[2026-05-28 07:00:05] [MORNING] Work:  Session active...
[2026-05-28 07:00:05] [MORNING] Session complete
---
[2026-05-28 12:00:01] [AFTERNOON] Starting session reset
...
---
```

**`codex-sessions.log`** — Codex (solo cuando `CODEX_ENABLED=true`):
```
[2026-05-28 07:00:01] [MORNING] Starting session reset
[2026-05-28 07:00:03] [MORNING] Reset: Session initialized...
[2026-05-28 07:00:05] [MORNING] Work:  Session active...
[2026-05-28 07:00:05] [MORNING] Session complete
---
```

Cada log se recorta automáticamente a las últimas 50 líneas al superar **200 líneas**.

---

## Desinstalar

```bash
bash uninstall.sh
```

Elimina (tras una sola confirmación):

- Entradas del crontab
- `config.sh`
- `sessions.log` y archivos temporales
- Opcionalmente: Claude Code (`npm uninstall -g`)
- Opcionalmente: Node.js (`apt-get remove nodejs`)

La carpeta del repositorio no se borra — elimínala manualmente con `rm -rf claude-keepalive` si quieres limpieza total.

---

## Idioma

Elige **Español** o **English** durante `install.sh`. La elección se guarda en `config.sh` y aplica a todos los scripts posteriores.

Para cambiar el idioma después de instalar, edita `config.sh`:

```bash
LANGUAGE="es"   # o "en"
```

---

## Referencia de configuración

`config.sh` se crea automáticamente. Puedes editarlo directamente o usar `update-schedule.sh`.

```bash
LANGUAGE="es"           # es o en
MORNING_HOUR=7          # 0–23
MORNING_MINUTE=0        # 0–59
MORNING_ENABLED=true    # activa/desactiva la sesión matutina
AFTERNOON_HOUR=12       # 0–23
AFTERNOON_MINUTE=0      # 0–59
AFTERNOON_ENABLED=true  # activa/desactiva la sesión vespertina
NIGHT_HOUR=17           # 0–23
NIGHT_MINUTE=0          # 0–59
NIGHT_ENABLED=false     # activa/desactiva la sesión nocturna (por defecto desactivada)
CODEX_ENABLED=false     # activa/desactiva Codex en todas las sesiones (por defecto desactivado)
WEEKDAYS="1,2,3,4,5"   # 0=Dom 1=Lun 2=Mar 3=Mié 4=Jue 5=Vie 6=Sáb
MAX_LOG_LINES=200       # el log se recorta al alcanzar este número de líneas
```

---

## Codex

Codex se instala automáticamente junto a Claude Code. Su cron está **desactivado por defecto**; para activarlo:

```bash
bash update-schedule.sh   # selecciona "Yes" en el diálogo de Codex
```

Para ver los logs de Codex:

```bash
cat codex-sessions.log
```

> **Nota sobre la sintaxis de Codex:** `session-starter.sh` llama a Codex con `codex "mensaje"`. Si tu versión del CLI requiere flags diferentes (por ejemplo `--approval-mode full-auto`), edita la sección `codex` en `session-starter.sh` según corresponda.

---

## Solución de problemas

### `claude: command not found`

Claude Code no está instalado. Vuelve a ejecutar `bash install.sh` o instálalo manualmente:

```bash
sudo npm install -g @anthropic-ai/claude-code
```

### `ERROR: sudo access required`

El instalador necesita sudo para instalar paquetes. Verifica que tu usuario tenga privilegios sudo.

### El log está vacío

El cron aún no se ha ejecutado. Prueba manualmente pasando el tipo de sesión:

```bash
bash session-starter.sh morning
```

### Error de autenticación en el log

Necesitas iniciar sesión primero:

```bash
claude login
```

### Cron no se ejecuta

Verifica que cron esté activo:

```bash
sudo systemctl status cron
sudo systemctl start cron
```

### Los scripts tienen caracteres `^M` (saltos de línea Windows)

Ocurre si `.gitattributes` no estaba en el repo antes de clonar. Corrígelo con:

```bash
sed -i 's/\r//' *.sh
```

---

## Notas

- Cada usuario del servidor debe ejecutar su propia instalación
- Las credenciales se guardan en `~/.claude/` y son privadas por usuario
- La herramienta es intencionalmente mínima: sin demonios ni procesos en segundo plano — solo cron y bash
- Probado en Ubuntu Server 22.04 y 24.04
