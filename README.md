# agent-keepalive

Abre a la hora que elijas la ventana de uso de tus agentes de IA, para que el límite de 5 horas empiece
a contar cuando a ti te conviene y no cuando te sientas a trabajar. Un cron envía un mensaje corto a
cada agente, hasta tres veces al día, y anota cómo salió.

Funciona con Claude Code, Codex y OpenCode. Solo tiene sentido con planes que
cuentan el uso por ventanas de tiempo, como Claude Pro o Max y ChatGPT Plus o Pro; con una llave de API
no hay ventana que abrir.

> **Plataforma:** Ubuntu o Debian. Puedes editar el código en Windows; `.gitattributes` mantiene los
> saltos de línea LF que necesitan los scripts.

---

## Instalación

```bash
git clone https://github.com/JDCloud-Ecosystem/agent-keepalive.git ~/projects/agent-keepalive
bash ~/projects/agent-keepalive/install.sh
```

El instalador pide el idioma, instala lo que falte (git, cron, whiptail, Node.js, Claude Code y Codex),
crea `config.sh` con el horario por defecto, registra el cron y deja disponible el comando `keepalive`.
El horario por defecto es a las 07:00 y 12:00, de lunes a viernes, solo con Claude.

Después conecta tus agentes, como se explica abajo.

---

## Un solo comando

`keepalive` sin nada más abre un menú. También acepta cada acción directa:

| Comando                   | Qué hace                                                        |
| ------------------------- | --------------------------------------------------------------- |
| `keepalive status`        | Qué agentes participan, si tienen sesión y cómo salió el último envío |
| `keepalive login [agente]`| Conecta un agente; sin nombre, pregunta cuál                    |
| `keepalive schedule`      | Cambia las horas, los días y qué agentes reciben el envío       |
| `keepalive test`          | Hace un envío real a cada agente elegido y revisa el resultado  |
| `keepalive log [agente]`  | Muestra los últimos envíos                                      |
| `keepalive update`        | Baja la versión más reciente sin tocar tu horario               |
| `keepalive uninstall`     | Quita el cron, la configuración y el comando                    |

---

## Conectar los agentes

| Agente      | Se conecta con                | Cómo lo llama el cron              |
| ----------- | ----------------------------- | ---------------------------------- |
| Claude Code | `keepalive login claude`      | `claude -p`                        |
| Codex       | `codex login --device-auth`   | `codex exec`                       |
| OpenCode    | `opencode auth login`         | `opencode run`                     |

Todos se ejecutan en su modo sin terminal, que es el único que funciona dentro de cron. OpenCode no
lo instala `install.sh`; si lo quieres, instálalo con `sudo npm install -g opencode-ai` y márcalo en
`keepalive schedule`. Con OpenCode solo vale la pena si entra con una suscripción de Claude o ChatGPT.

Gemini CLI y Qwen Code quedan fuera a propósito. Gemini cuenta su uso por día y no por ventanas, así que
un envío programado no le abre nada, y Qwen Code ya no tiene inicio de sesión gratuito.

**Claude se conecta por un año.** `claude login` guarda una sesión corta que se renueva sola, y si dos
procesos la renuevan a la vez, como el cron y una terminal abierta, o si una renovación falla, Claude la
borra y hay que volver a entrar. `keepalive login claude` usa `claude setup-token`, que entrega un token
de un año que nunca se renueva, así que nada lo rompe. Abre el inicio de sesión de Claude, guarda solo
el token en `~/.config/agent-keepalive/` (legible únicamente por ti), comprueba que funcione y hace que
el cron y cada terminal nueva lo usen. Un mes antes de que venza, `keepalive status` y `keepalive test`
lo avisan, y basta con volver a correr el mismo comando.

---

## El historial

Cada envío deja una línea en el log de su agente (`sessions.log` para Claude, `codex-sessions.log` para
Codex y `<agente>-sessions.log` para los demás). Termina siempre en uno de tres resultados:

| Resultado | Significa                                                                   |
| --------- | --------------------------------------------------------------------------- |
| `OK`      | El agente respondió y su ventana empezó                                     |
| `LIMIT`   | Ya había una ventana abierta, o la cuenta llegó a su límite semanal; no hay nada que arreglar |
| `ERROR`   | Algo falló, y la misma línea dice qué comando corre para arreglarlo         |

Los logs se recortan solos al llegar a 200 líneas.

---

## Configuración

`config.sh` se crea al instalar y `keepalive schedule` lo mantiene. También se puede editar a mano:

```bash
LANGUAGE="es"            # es o en
MORNING_HOUR=7           # 0 a 23
MORNING_MINUTE=0         # 0 a 59
MORNING_ENABLED=true
AFTERNOON_HOUR=12
AFTERNOON_MINUTE=0
AFTERNOON_ENABLED=true
NIGHT_HOUR=17
NIGHT_MINUTE=0
NIGHT_ENABLED=false
AGENTS="claude codex"    # agentes que reciben el envío, separados por espacio
WEEKDAYS="1,2,3,4,5"     # 0 es domingo y 6 es sábado
MAX_LOG_LINES=200
```

Después de editarlo a mano, `keepalive update` vuelve a escribir el cron.

---

## Archivos

| Archivo              | Qué es                                                         |
| -------------------- | -------------------------------------------------------------- |
| `keepalive`          | El comando; `install.sh` lo enlaza en `~/.local/bin`           |
| `lib.sh`             | Lo que comparten los scripts: agentes, sesiones y cron         |
| `session-starter.sh` | Lo que corre el cron, un envío por agente                      |
| `login.sh`           | Conecta Claude por un año                                      |
| `install.sh`         | Instala y registra el cron                                     |
| `update-schedule.sh` | El editor de horario y agentes                                 |
| `test.sh`            | La prueba completa                                             |
| `uninstall.sh`       | Lo quita todo                                                  |
| `config.sh`, `*.log` | Se generan al usarlo y git los ignora                          |

---

## Si algo falla

- **El log está vacío.** El cron todavía no ha corrido; `keepalive test` hace un envío en ese momento.
- **Un `ERROR` de inicio de sesión.** Corre el comando que trae la misma línea, por ejemplo
  `keepalive login claude` o `codex login --device-auth`.
- **El cron no corre.** Revisa que esté activo con `sudo systemctl status cron`.
- **Los scripts muestran `^M`.** Se clonaron antes de que existiera `.gitattributes`; `sed -i 's/\r//' *.sh`
  lo corrige.

Cada usuario del servidor tiene su propia instalación y sus propias sesiones. No hay demonios ni
procesos en segundo plano, solo cron y bash. Probado en Ubuntu Server 22.04 y 24.04.
