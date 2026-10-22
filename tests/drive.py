"""Drives keepalive through a real terminal, as tester, and checks every screen. Run inside the test container."""
import base64
import datetime
import os
import pty
import re
import select
import subprocess
import sys
import time

HOME = "/home/tester"
KIT = f"{HOME}/projects/agent-keepalive"
ANSI = re.compile(r"\x1b\[[0-9;?]*[A-Za-z]|\x1b\][^\x07]*\x07|\r")
BACKGROUND = re.compile(r"\x1b\[(?:[0-9]+;)*(?:4[0-7]|10[0-7])(?:;[0-9]+)*m")
PICK = "Elige una opción"
results = []


class Term:
    def __init__(self, command, env=None):
        self.pid, self.fd = pty.fork()
        if self.pid == 0:
            os.execvpe("bash", ["bash", "-c", command], {**os.environ, "TERM": "xterm", **(env or {})})
        self.raw = ""
        self.mark = 0

    def read(self, timeout=0.3):
        end = time.time() + timeout
        while time.time() < end:
            ready, _, _ = select.select([self.fd], [], [], 0.05)
            if ready:
                try:
                    data = os.read(self.fd, 65536).decode("utf-8", "replace")
                except OSError:
                    return
                if not data:
                    return
                self.raw += data

    def text(self):
        return ANSI.sub("", self.raw)

    def since(self):
        return ANSI.sub("", self.raw[self.mark:])

    def expect(self, needle, timeout=10):
        end = time.time() + timeout
        while time.time() < end:
            self.read(0.2)
            if (needle.search(self.since()) if isinstance(needle, re.Pattern) else needle in self.since()):
                return True
        raise AssertionError(f"never saw {needle!r}; screen ends with:\n{self.text()[-1800:]}")

    def quiet(self, seconds=1.0):
        """Nothing new shows up for a while: the key was not taken."""
        before = len(self.raw)
        self.read(seconds)
        return ANSI.sub("", self.raw[before:]).strip() == ""

    def key(self, keys):
        """Keys exactly as given; a single-key answer needs no Enter."""
        self.mark = len(self.raw)
        os.write(self.fd, keys.encode())
        time.sleep(0.15)

    def send(self, line):
        self.key(line + "\n")

    def wait(self, timeout=10):
        end = time.time() + timeout
        while time.time() < end:
            self.read(0.2)
            done, status = os.waitpid(self.pid, os.WNOHANG)
            if done:
                return os.waitstatus_to_exitcode(status)
        raise AssertionError("did not end")


def check(name, function):
    try:
        function()
        results.append((name, True, ""))
    except Exception as error:  # noqa: BLE001
        results.append((name, False, str(error)[:2200]))


def config():
    return open(f"{KIT}/config.sh").read()


def set_config(text):
    with open(f"{KIT}/config.sh", "w") as handle:
        handle.write(text)


def crontab():
    return subprocess.run(["crontab", "-l"], capture_output=True, text=True).stdout


def b64(text):
    return base64.b64encode(text.encode()).decode()


def row(*cells):
    """A table row with these cells in order, whatever the column widths."""
    return re.compile(r"│ " + r"\s*│ ".join(re.escape(cell) for cell in cells) + r"\s*│")


def tables_line_up(text):
    """Every line of each table is as wide as its top line."""
    width = None
    for line in text.splitlines():
        if line.startswith("  ┌"):
            width = len(line)
        elif width and line.startswith(("  │", "  ├", "  └")):
            assert len(line) == width, f"{len(line)} != {width}: {line!r}"
            if line.startswith("  └"):
                width = None


HEADER = "\x1b[1;36m░█░█ MI SERVIDOR ░█░█\x1b[0m\n\n  Hola, tester."
ENV = {"KEEPALIVE_HEADER": b64(HEADER), "KEEPALIVE_NOTICE": b64("  AVISO UNA VEZ"), "KEEPALIVE_EXIT_LABEL": "Volver al inicio"}


def menu():
    term = Term("keepalive", ENV)
    term.expect(PICK)
    return term


def t_menu_draws():
    term = menu()
    text = term.text()
    for needle in ("MI SERVIDOR", "Hola, tester.", "AVISO UNA VEZ", "SESIONES AUTOMÁTICAS DE TUS AGENTES",
                   "Horario        a las 07:00 y 12:00, de lunes a viernes", "Próximo envío", "SESIONES AUTOMÁTICAS",
                   "1  Probar ahora", "3  Cambiar el horario o los agentes", "4  Conectar o cambiar una cuenta",
                   "6  Actualizar Claude Code, Codex y OpenCode", "8  Usar la terminal", "0  Volver al inicio",
                   "─" * 72):
        assert needle in text, needle
    assert row("Estado", "Agente", "Cuenta", "Último envío").search(text), text[-1500:]
    assert row("OK", "Claude Code", "persona@example.com").search(text), text[-1500:]
    assert "Codex" not in text.split("Último envío")[1].split("SESIONES AUTOMÁTICAS\n")[0]  # no session, not in it
    tables_line_up(text)
    assert not BACKGROUND.search(term.raw), "a tag has a background colour"
    assert "idioma" not in text.lower()
    term.key("\n")  # Enter only draws it again, and the notice was for the first screen only
    term.expect(PICK)
    time.sleep(0.5); term.read()
    again = term.since()
    assert "MI SERVIDOR" in again and "AVISO UNA VEZ" not in again, again[-600:]
    term.key("0")
    assert term.wait() == 0


def t_keys_need_no_enter():
    term = menu()
    term.key("9")
    assert term.quiet(), "9 is not an option and must not be taken"
    term.key("x")
    assert term.quiet(), "a letter is not an option"
    term.key("2")  # taken at once, no Enter
    term.expect("HISTORIAL DE ENVÍOS")
    term.expect("0  Volver al menú")
    term.key("0")
    term.expect(PICK)
    term.key("0")
    assert term.wait() == 0


def t_terminal_and_back():
    term = menu()
    term.key("8")
    term.expect("Escribe menu para volver al menú.")
    time.sleep(0.5)
    term.send("echo dentro-$((40+2))")
    term.expect("dentro-42")
    term.send("keepalive status")
    term.expect("hasta el")
    term.send("menu")
    term.expect("8  Usar la terminal")
    term.key("8")
    term.expect("Escribe menu para volver al menú.")
    time.sleep(0.5)
    term.send("keepalive")
    term.expect(PICK)
    term.key("8")
    term.expect("Escribe menu para volver")
    time.sleep(0.5)
    term.send("exit")
    term.expect(PICK)
    term.key("0")
    assert term.wait() == 0


def t_schedule():
    term = menu()
    term.key("3")
    term.expect("HORARIO Y AGENTES")
    term.expect(PICK)
    assert "Idioma" not in term.since() and "6  " not in term.since(), term.since()[-800:]
    term.key("1")
    term.expect("Elige los días")
    term.send("9-2")
    term.expect("Usa números del 1 al 7")
    term.expect("Elige los días")
    term.send("1-3 7")
    term.expect("Guardado, y el cron quedó al día.")
    assert 'WEEKDAYS="0,1,2,3"' in config(), config()
    assert "Días       lunes, martes, miércoles y domingo" in term.since(), term.since()[-900:]
    term.expect(PICK)
    term.key("2")
    term.expect("Escribe la hora")
    term.send("25:00")
    term.expect("Usa la hora como 07:30")
    term.expect("Escribe la hora")
    term.send("08:15")  # a time starting with 0 is not taken as going back
    term.expect("Guardado")
    assert "MORNING_HOUR=8" in config() and "MORNING_MINUTE=15" in config()
    term.expect(PICK)
    term.key("3")
    term.expect("Escribe la hora")
    term.send("no")
    term.expect("Guardado")
    assert "AFTERNOON_ENABLED=false" in config()
    term.expect(PICK)
    term.key("2")
    term.expect("Escribe la hora")
    term.send("no")
    term.expect("Es la única sesión activa")
    term.expect("Escribe la hora")
    term.send("0")
    term.expect(PICK)
    term.key("5")
    term.expect("Elige los agentes")
    term.send("1 4")
    term.expect("Usa los números de la lista")
    term.expect("Elige los agentes")
    term.send("1 2")
    term.expect("Guardado")
    assert 'AGENTS="claude codex"' in config()
    cron = crontab()
    assert "15 8 * * 0,1,2,3" in cron and "session-starter.sh morning codex" in cron and "afternoon" not in cron, cron
    term.expect(PICK)
    term.key("5")
    term.expect("Elige los agentes")
    term.send("1")
    term.expect("Guardado")
    assert 'AGENTS="claude"' in config()
    term.expect(PICK)
    term.key("1")
    term.expect("Elige los días")
    term.key("0")  # 0 alone goes back at once, even where a list is expected
    term.expect("HORARIO Y AGENTES")
    term.expect(PICK)
    term.key("0")
    term.expect("SESIONES AUTOMÁTICAS DE TUS AGENTES")
    term.expect(PICK)
    term.key("0")
    term.wait()


def t_login_and_logout():
    term = menu()
    term.key("4")
    term.expect("CONECTAR O CAMBIAR UNA CUENTA")
    term.expect("Elige un agente")
    term.key("0")  # back, with no pause
    term.expect("8  Usar la terminal")
    term.key("4")
    term.expect("Elige un agente")
    term.key("3")
    term.expect("CONECTAR OPENCODE")
    term.expect("OpenCode quedó conectado, OpenCode Zen (llave de API).")
    term.expect("¿Sumas a OpenCode a la sesión automática? (s o n)")
    term.key("n")
    term.expect("0  Volver al menú")
    assert "opencode" not in config().split("AGENTS=")[1].split("\n")[0]
    term.key("0")
    term.expect(row("FUERA", "OpenCode", "OpenCode Zen (llave de API)", "fuera de la sesión automática"))
    term.key("5")
    term.expect("CERRAR LA SESIÓN DE UNA CUENTA")
    term.expect("Elige un agente")
    picks = term.text().split("CERRAR LA SESIÓN DE UNA CUENTA")[-1]
    number = [line.strip()[0] for line in picks.splitlines() if "OpenCode" in line][0]
    term.key(number)
    term.expect("¿Cerrar la sesión de OpenCode, cuenta OpenCode Zen (llave de API)? (s o n)")
    term.key("s")
    term.expect("Listo, OpenCode quedó sin sesión en esta máquina.")
    term.expect(PICK)
    term.key("0")
    term.expect("8  Usar la terminal")
    term.key("0")
    term.wait()


def t_codex_login_joins_schedule():
    term = menu()
    term.key("4")
    term.expect("Elige un agente")
    term.send("codex")  # a name works too, ended with Enter
    term.expect("Codex quedó conectado, dev@example.com (Plus).")
    term.expect("(s o n)")
    term.key("\n")  # Enter takes the default, yes
    term.expect("Codex entra a la sesión automática y el cron quedó al día.")
    assert "session-starter.sh morning codex" in crontab()
    term.key("0")
    term.expect(PICK)
    term.key("0")
    term.wait()


def t_test_now():
    term = menu()
    term.key("1")
    term.expect("PRUEBA DE TUS AGENTES")
    term.expect("(s o n)")
    term.key("n")
    term.expect("No se envió nada.")
    term.expect("8  Usar la terminal")  # straight back, no pause
    term.key("1")
    term.expect("(s o n)")
    term.key("s")
    term.expect("Todas las pruebas pasaron.", 30)
    term.expect("0  Volver al menú")
    term.key("0")
    term.expect(PICK)
    term.key("2")
    term.expect("HISTORIAL DE ENVÍOS")
    term.expect("0  Volver al menú")
    shown = term.since()
    assert row("Agente", "Cuándo", "Resultado", "Qué pasó").search(shown), shown[-1200:]
    assert re.search(r"│ Claude Code\s+│ \d\d/\d\d \d\d:\d\d │ OK\s+│ salió bien", shown), shown[-1200:]
    tables_line_up(shown)
    term.key("0")
    term.expect(PICK)
    term.key("0")
    term.wait()


def t_failed_run_shows_why():
    open("/var/lib/stub/claude-fails", "w").close()
    subprocess.run(["bash", f"{KIT}/session-starter.sh", "morning", "claude"])
    os.remove("/var/lib/stub/claude-fails")
    term = menu()
    text = term.text()
    assert re.search(r"│ FALLÓ\s+│ Claude Code\s+│ persona@example.com\s+│ \d\d/\d\d \d\d:\d\d, falló\s+│", text), text[-1500:]
    assert ("El último envío a Claude Code falló porque su sesión venció. Conéctalo otra vez en "
            "«Conectar o cambiar una cuenta».") in text, text[-1500:]
    term.key("2")
    term.expect("0  Volver al menú")
    assert re.search(r"│ FALLÓ\s+│ para arreglarlo corre keepalive login claude", term.since()), term.since()[-800:]
    term.key("0")
    term.expect(PICK)
    term.key("0")
    term.wait()
    full = subprocess.run(["keepalive", "status"], capture_output=True, text=True).stdout
    plain = ANSI.sub("", full)
    assert row("Estado", "Agente", "Sesión", "Cuenta", "Último envío").search(plain), plain
    assert re.search(r"│ FALLÓ\s+│ Claude Code\s+│ hasta el \d\d/\d\d/\d{4}", plain), plain
    assert "El último envío a Claude Code falló, para arreglarlo corre keepalive login claude." in plain, plain


def t_update_agents():
    term = menu()
    term.key("6")
    term.expect("ACTUALIZAR CLAUDE CODE, CODEX Y OPENCODE")
    term.expect("0  Volver al menú", 30)
    text = term.text()
    assert "Claude Code pasó de 2.1.0 a 2.1.1" in text and "Codex pasó de 0.50.0 a 0.50.1" in text, text[-1200:]
    assert "OpenCode pasó de 1.0.0 a 1.0.1" in text
    term.key("0")
    term.expect(PICK)
    open("/var/lib/stub/npm-fails", "w").close()
    term.key("6")
    term.expect("0  Volver al menú", 30)
    assert "No se pudo actualizar Codex. Esto respondió." in term.since() and "network request failed" in term.since()
    os.remove("/var/lib/stub/npm-fails")
    term.key("0")
    term.expect(PICK)
    term.key("0")
    term.wait()


def t_update_repo():
    term = menu()
    term.key("7")
    term.expect("Ya tenías la versión más reciente", 20)
    term.expect("0  Volver al menú")
    term.key("0")
    term.expect(PICK)
    # A new version lands upstream: the menu pulls it and opens again with it.
    subprocess.run(["bash", "-c", "cd /tmp && rm -rf up && git clone -q /srv/ka.git up && cd up && echo 9.9.9 > version.txt "
                    "&& git commit -qam 'chore: bump' && git push -q"], check=True)
    term.key("7")
    term.expect("Actualizado de", 20)
    term.expect("El menú se abre otra vez con la versión nueva.")
    term.key("0")
    term.expect(PICK)
    after = term.since()
    assert "MI SERVIDOR" in after and "AVISO UNA VEZ" not in after
    term.key("0")
    term.wait()


def t_renewal_and_old_language():
    created = f"{HOME}/.config/agent-keepalive/claude-token.created"
    before, settings = open(created).read(), config()
    try:
        with open(created, "w") as handle:
            handle.write((datetime.date.today() - datetime.timedelta(days=350)).isoformat() + "\n")
        set_config(settings.replace('LANGUAGE="es"', 'LANGUAGE="en"'))  # an install from before keeps working
        assert 'LANGUAGE="en"' in config()
        done = subprocess.run(["keepalive", "status"], capture_output=True, text=True, stdin=subprocess.DEVNULL)
        plain = ANSI.sub("", done.stdout)
        assert "SESIONES AUTOMÁTICAS DE TUS AGENTES" in plain and "Último envío" in plain, plain
        assert re.search(r"La conexión de Claude vence el \d\d/\d\d/\d{4}, renuévala en «Conectar o cambiar una cuenta»\.",
                         plain), plain
    finally:
        with open(created, "w") as handle:
            handle.write(before)
        set_config(settings)


def t_without_terminal():
    done = subprocess.run(["keepalive"], capture_output=True, text=True, stdin=subprocess.DEVNULL)
    plain = ANSI.sub("", done.stdout)
    assert "SESIONES AUTOMÁTICAS DE TUS AGENTES" in plain and PICK not in plain, plain
    assert "Último envío" in plain, plain
    assert ";" not in plain and not re.search(r"[A-Za-zÁ-úñ]: ", plain), plain
    done = subprocess.run(["keepalive", "schedule"], capture_output=True, text=True, stdin=subprocess.DEVNULL)
    assert "HORARIO Y AGENTES" in done.stdout and "Próximo" in done.stdout, done.stdout
    done = subprocess.run(["keepalive", "login"], capture_output=True, text=True, stdin=subprocess.DEVNULL)
    assert done.returncode == 1 and "Indica el agente" in done.stdout, (done.returncode, done.stdout)
    done = subprocess.run(["keepalive", "help"], capture_output=True, text=True)
    assert "update-agents" in done.stdout and "abre el menú" in done.stdout and "keepalive uninstall" in done.stdout
    done = subprocess.run(["keepalive", "volar"], capture_output=True, text=True)
    assert done.returncode == 1 and "keepalive no tiene el comando volar" in done.stdout, done.stdout
    done = subprocess.run(["keepalive", "login", "gemini"], capture_output=True, text=True, stdin=subprocess.DEVNULL)
    assert done.returncode == 1 and "No hay un agente llamado gemini" in done.stdout, done.stdout
    done = subprocess.run(["keepalive", "logout", "codex", "--yes"], capture_output=True, text=True)
    assert done.returncode == 0 and "Codex quedó sin sesión" in done.stdout, done.stdout
    assert "Codex salió de la sesión automática" in done.stdout


def t_next_run():
    lib = f"SCRIPT_DIR={KIT}; . {KIT}/lib.sh"
    now = datetime.datetime.now()

    def run(slots, days):
        script = f"{lib}; MORNING_ENABLED=false AFTERNOON_ENABLED=false NIGHT_ENABLED=false; WEEKDAYS={days}; "
        for name, slot in zip(("MORNING", "AFTERNOON", "NIGHT"), slots):
            script += f"{name}_ENABLED=true {name}_HOUR={slot.hour} {name}_MINUTE={slot.minute}; "
        return subprocess.run(["bash", "-c", script + "next_run_text"], capture_output=True, text=True).stdout.strip()

    today = (now.weekday() + 1) % 7
    soon = now + datetime.timedelta(minutes=65)
    if soon.date() == now.date():
        assert run([soon], str(today)) == f"hoy a las {soon:%H:%M}, en 1 h 5 min", run([soon], str(today))
    soon = now + datetime.timedelta(minutes=7)
    if soon.date() == now.date():
        assert run([soon], str(today)) == f"hoy a las {soon:%H:%M}, en 7 min"
    earlier = now - datetime.timedelta(minutes=30)
    if earlier.date() == now.date():
        tomorrow = (today + 1) % 7
        got = run([earlier], f"{today},{tomorrow}")
        assert got.startswith(f"mañana a las {earlier:%H:%M}, en 23 h"), got
        names = ["domingo", "lunes", "martes", "miércoles", "jueves", "viernes", "sábado"]
        later = (today + 3) % 7
        got = run([earlier], str(later))
        assert got.startswith(f"el {names[later]} a las {earlier:%H:%M}, en 2 días y 23 h"), got
    assert run([], "1,2,3") == ""
    assert subprocess.run(["bash", "-c", f"{lib}; MORNING_ENABLED=true AFTERNOON_ENABLED=false NIGHT_ENABLED=false; "
                           "MORNING_HOUR=7 MORNING_MINUTE=0; WEEKDAYS=1; schedule_text"], capture_output=True, text=True
                          ).stdout.strip() == "a las 07:00, lunes"


def t_keys_logic():
    lib = f"SCRIPT_DIR={KIT}; . {KIT}/lib.sh"
    cases = {("3", 8): "fits whole", ("0", 8): "fits whole", ("9", 8): "no", ("1", 12): "fits",
             ("12", 12): "fits whole", ("13", 12): "no", ("05", 9): "no"}
    for (typed, top), expected in cases.items():
        got = subprocess.run(["bash", "-c", f"{lib}; _ui_fits {typed} {top} && printf fits; "
                              f"_ui_whole {typed} {top} && printf ' whole'; true"], capture_output=True, text=True).stdout
        assert (got or "no") == expected, (typed, top, got)


for name, function in [(n, f) for n, f in globals().items() if n.startswith("t_")]:
    check(name, function)
failed = [r for r in results if not r[1]]
for name, ok, detail in results:
    print(("PASS " if ok else "FAIL ") + name + ("" if ok else "\n" + detail))
print(f"{len(results) - len(failed)}/{len(results)} passed")
sys.exit(1 if failed else 0)
