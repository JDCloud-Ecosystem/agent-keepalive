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

El instalador instala lo que falte (git, cron, Node.js, Claude Code y Codex), crea
`config.sh` con el horario por defecto, registra el cron y deja disponible el comando `keepalive`.
El horario por defecto es a las 07:00 y 12:00, de lunes a viernes, solo con Claude.

Después conecta tus agentes, como se explica abajo.

---

## El menú

`keepalive` sin nada más abre un menú. Arriba muestra el horario, cuándo es el próximo envío y una tabla con
cada agente, su etiqueta, su cuenta y su último envío, y debajo cada opción con su número, en grupos. Lo que
haya que arreglar aparece justo debajo de la tabla.

| Grupo                | Opciones                                                                     |
| -------------------- | ---------------------------------------------------------------------------- |
| Sesiones automáticas | Probar ahora, ver el historial y cambiar el horario o los agentes            |
| Cuentas              | Conectar o cambiar una cuenta y cerrar la sesión de una                      |
| Actualizar           | Claude Code, Codex y OpenCode, o agent-keepalive                             |
| Terminal             | Usar la terminal, donde `menu` regresa al menú                               |

Cada pantalla lleva su título en mayúsculas entre dos líneas, y en todas `0` vuelve a la anterior. Una opción se
elige con su tecla, sin Enter. Enter solo hace falta donde se escriben varios números, una hora o un nombre.
Probar ahora pregunta antes de enviar, porque el envío abre la ventana de uso de cada agente en ese momento.
Todo está en español.

Un programa que abre el menú por alguien, como una puerta de entrada por SSH, puede poner su propio encabezado
arriba de cada pantalla con `KEEPALIVE_HEADER`, un aviso solo en la primera con `KEEPALIVE_NOTICE`, los dos en
base64, y el nombre de la opción `0` con `KEEPALIVE_EXIT_LABEL`.

## Los comandos

Cada opción del menú también se corre directa.

| Comando                     | Qué hace                                                            |
| --------------------------- | ------------------------------------------------------------------- |
| `keepalive status`          | El horario, el próximo envío y la tabla de agentes, con su sesión      |
| `keepalive login [agente]`  | Conecta un agente, y sin nombre pregunta cuál                       |
| `keepalive logout [agente]` | Cierra la sesión de un agente en esta máquina, y con `--yes` no pregunta |
| `keepalive schedule`        | Cambia los días, las horas y qué agentes reciben el envío           |
| `keepalive test`            | Hace un envío real a cada agente elegido y revisa el resultado      |
| `keepalive log [agente]`    | Muestra los últimos envíos                                          |
| `keepalive update`          | Baja la versión más reciente de agent-keepalive sin tocar tu horario |
| `keepalive update-agents`   | Actualiza Claude Code, Codex y OpenCode sin tocar sus sesiones      |
| `keepalive uninstall`       | Quita el cron, la configuración y el comando                        |

`keepalive update-agents` usa `sudo` cuando los agentes se instalaron para todo el sistema, y deja para
después el que esté abierto en ese momento.

La etiqueta de cada agente dice de un vistazo cómo va:

| Etiqueta     | Color    | Significa                                                     |
| ------------ | -------- | ------------------------------------------------------------- |
| `OK`         | verde    | Tiene sesión y el último envío salió bien                     |
| `FALLÓ`      | rojo     | El último envío falló o el agente no está instalado           |
| `SIN SESIÓN` | rojo     | Falta conectarlo, y debajo de la tabla dice cómo              |
| `LÍMITE`     | amarillo | La cuenta llegó a su límite semanal y se libera sola          |
| `ESPERA`     | cian     | Tiene sesión, pero todavía no le toca su primer envío         |
| `FUERA`      | gris     | No participa en la sesión automática                          |

La etiqueta es texto de color, sin fondo, para que se lea en cualquier tema de la terminal. Junto a cada agente
aparece su cuenta, con el correo y el plan para Claude y Codex y el proveedor para OpenCode, y su último envío.
`keepalive status` suma la columna de la sesión, con la fecha en que vence la de Claude. Debajo de la tabla va
una línea por cada agente que necesita algo, con lo que hay que hacer.

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

El token mide más de 100 caracteres, y en una terminal angosta Claude lo muestra partido en dos líneas.
El comando lo junta solo; si te pide pegarlo, pégalo completo aunque ocupe varias líneas. Si Claude lo
rechaza, muestra lo que respondió. Si la cuenta está en su límite de uso, el token se guarda igual,
porque Claude ya lo aceptó.

El token no dice de qué cuenta es, así que al final el comando pregunta con qué correo entraste y lo anota
en `~/.config/agent-keepalive/claude-account` para que `keepalive status` lo muestre. Si en esa máquina ya
hubo un `claude login`, ofrece esa cuenta y basta con pulsar Enter.

Codex y OpenCode no necesitan nada parecido. Codex guarda una sesión de ChatGPT que se renueva sola cada
vez que corre, y como el cron lo usa a diario no llega a caducar. OpenCode con OpenCode Zen entra con una
llave de API, que no vence.

**Cerrar una sesión.** `keepalive logout [agente]` deja al agente sin sesión en esta máquina, para
cambiar de cuenta o cuando el equipo deja de usarse. Antes de cerrar muestra la cuenta y pide confirmación.

| Agente      | Qué quita                                                                         |
| ----------- | --------------------------------------------------------------------------------- |
| Claude Code | El token de un año, la cuenta anotada y las líneas de `~/.bashrc` que lo cargan, y además cierra la sesión normal con `claude auth logout` |
| Codex       | Su sesión, con `codex logout`                                                     |
| OpenCode    | Sus credenciales de `~/.local/share/opencode/auth.json`, porque su propio cierre de sesión solo funciona con una terminal |

Si el agente estaba en la sesión automática, el comando ofrece sacarlo y actualiza el cron, porque sin
sesión cada envío fallaría. El último agente que queda nunca sale. En la terminal donde se cerró Claude
sigue cargado el token hasta que escribas `unset CLAUDE_CODE_OAUTH_TOKEN`; las nuevas ya no lo traen.

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

| Archivo              | Qué es                                                                       |
| -------------------- | ---------------------------------------------------------------------------- |
| `keepalive`          | El comando; `install.sh` lo enlaza en `~/.local/bin`                         |
| `lib.sh`             | Lo que comparten los scripts: agentes, cron y cada pantalla                  |
| `session-starter.sh` | Lo que corre el cron, un envío por agente                                    |
| `login.sh`           | Conecta Claude por un año                                                    |
| `install.sh`         | Instala y registra el cron                                                   |
| `update-schedule.sh` | La pantalla de horario y agentes                                             |
| `terminal-rc.sh`     | El arranque de la terminal del menú, con `menu` para volver                  |
| `test.sh`            | La prueba completa                                                           |
| `tests/`             | Las pruebas de la terminal en un Ubuntu limpio, y la revisión de los scripts |
| `uninstall.sh`       | Lo quita todo                                                                |
| `config.sh`, `*.log` | Se generan al usarlo y git los ignora                                        |
| `version.txt`        | La versión instalada; la escribe Release Please                              |
| `package.json`       | Revisa los commits de quien contribuye; los scripts no usan Node             |

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

---

## Contribuir

Cada cambio empieza como una issue y llega por un pull request. Cómo se propone está en
[CONTRIBUTING.md](CONTRIBUTING.md), el flujo completo en [docs/GITHUB-WORKFLOW.md](docs/GITHUB-WORKFLOW.md) y
cómo sale cada versión en [docs/RELEASE.md](docs/RELEASE.md). Los cambios de cada versión están en
[CHANGELOG.md](CHANGELOG.md), y las decisiones que no se ven en el código, en [docs/adr/](docs/adr/README.md).
