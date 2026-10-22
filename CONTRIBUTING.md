# Contribuir

Cada cambio entra a `main` por un pull request, y `main` es lo que recibe cada instalación con
`keepalive update`. Por eso lo que se fusiona tiene que funcionar ya, en Ubuntu y en Debian.

## Preparar el repositorio

```bash
git clone https://github.com/JDCloud-Ecosystem/agent-keepalive.git
cd agent-keepalive
pnpm install
```

`pnpm install` solo instala commitlint y Husky, que revisan cada mensaje de commit. La herramienta no usa Node
para correr sus scripts. Las pruebas piden Docker y, en Windows, Git Bash.

## Un cambio, de la issue al PR

1. Abrir la issue con su plantilla. Las issues en blanco están apagadas.
2. Si es una funcionalidad, escribir su spec en `docs/specs/features/{N}-{english-slug}.md`, con `N` el número de
   la issue, desde `_TEMPLATE.md`. No se programa hasta que diga `status: approved`.
3. Crear la rama desde `main`, `{tipo}/{N}-{english-slug}`, como `fix/15-night-session-skips-sundays`, siempre en
   inglés.
4. Hacer el cambio. Cada texto que ve una persona va en español, que es el único idioma de la herramienta.
5. Correr las pruebas.

   ```bash
   bash tests/lint.sh
   bash tests/run.sh
   ```

   `tests/lint.sh` revisa que cada script se pueda leer y corre shellcheck. `tests/run.sh` instala el código en un
   Ubuntu limpio, con agentes de prueba, y recorre cada pantalla desde una terminal real.

6. Si el cambio toca el envío, el inicio de sesión o el horario, correr `keepalive test` en una máquina de
   prueba, con los agentes de verdad.
7. Abrir el PR contra `main`, con su plantilla y `Closes #N`. El CI corre las mismas pruebas, y otra revisión
   valida el título.

El flujo completo, con las plantillas, las labels y el tablero, está en
[docs/GITHUB-WORKFLOW.md](docs/GITHUB-WORKFLOW.md).

## Commits y títulos de PR

Siguen [Conventional Commits](https://www.conventionalcommits.org/) en inglés, con el scope obligatorio y
hasta 100 caracteres.

```text
fix(login): ask again for the Claude account until it is a plain email
```

| Tipo       | Cuándo                                          |
| ---------- | ----------------------------------------------- |
| `feat`     | Algo nuevo para quien usa la herramienta        |
| `fix`      | Un error arreglado                              |
| `refactor` | Código que cambia sin cambiar lo que hace       |
| `docs`     | Solo documentación                              |
| `style`    | Solo formato                                    |
| `test`     | Las pruebas                                     |
| `chore`    | Mantenimiento, dependencias, herramientas       |
| `ci`       | Los workflows de GitHub Actions                 |

Ningún commit lleva atribución a una IA, ni en el mensaje ni como coautor.

El PR se fusiona con **Squash and merge**, el único botón activo. En `main` queda un solo commit con el título
del PR, y ese título es la línea que verá en el changelog quien actualice. Conviene escribirlo para esa persona.

## Versiones

Las publica Release Please con un PR de versión que se mantiene al día solo. El proceso completo está en
[docs/RELEASE.md](docs/RELEASE.md).

## Decisiones de arquitectura (ADR)

Las decisiones arquitectónicas se registran en [`docs/adr/`](docs/adr/README.md), siguiendo
[MADR 4.0.0](https://adr.github.io/madr/). Ahí está la plantilla.

Una spec se congela cuando su función queda terminada. Un ADR sigue rigiendo después. Esa diferencia
decide dónde va una decisión.

**Escribe un ADR cuando se cumplan las tres:**

1. **Es estructural.** Fija cómo se hace algo más allá de la función en curso, como dónde guarda sus datos una
   instalación, cómo se actualiza, el formato de un log o una convención que heredarán las siguientes.
2. **Sobrevive a su spec.** Sigue mandando cuando la spec ya está terminada.
3. **Tuvo alternativas reales.** Hubo opciones que se midieron y se descartaron por motivos que se pueden
   escribir.

**Si no las cumple, va a otro sitio:**

| La decisión                                 | Dónde vive                               |
| ------------------------------------------- | ---------------------------------------- |
| Estructural y duradera, con alternativas    | `docs/adr/NNNN-*.md`                     |
| Duradera pero sin alternativas que sopesar  | Una regla en `AGENTS.md`                 |
| Elección de implementación de una sola spec | La spec, sección 6 «Decisiones técnicas» |
| Mecánica, deducible leyendo el código       | En ningún sitio. El código ya lo dice    |

Un ADR nace en `proposed` y solo el desarrollador lo pasa a `accepted`. Nunca se borra ni se reescribe
para decir otra cosa. Una decisión que cambia genera un ADR nuevo, y el anterior pasa a
`superseded by ADR-NNNN`.

## Los agentes de IA

Las reglas para los agentes están en `AGENTS.md`, y sus skills en `.agents/skills/`. Nunca hacen commits.
Preparan la guía en `tmp/{N}/commit-guide.md` y el cuerpo del PR en `tmp/{N}/pr-body.md`, y la persona los corre.
