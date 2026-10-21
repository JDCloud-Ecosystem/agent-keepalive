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
para correr sus scripts.

## Un cambio, de la rama al PR

1. Crear la rama desde `main`, como `fix/login-email` o `feature/night-session`, siempre en inglés.
2. Hacer el cambio. Cada texto que ve una persona va en el bloque `es` y en el bloque `en` de su script.
3. Revisar que los scripts pasen.

   ```bash
   for s in ./*.sh keepalive; do bash -n "$s"; done
   shellcheck -x --severity=error ./*.sh keepalive
   ```

4. Si el cambio toca el envío, el inicio de sesión o el horario, correr `keepalive test` en una máquina de
   prueba.
5. Abrir el PR contra `main`. El CI corre la sintaxis y shellcheck, y otra revisión valida el título.

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

El PR se fusiona con **Squash and merge**, el único botón activo. En `main` queda un solo commit con el título
del PR, y ese título es la línea que verá en el changelog quien actualice. Conviene escribirlo para esa persona.

## Versiones

Las publica Release Please con un PR de versión que se mantiene al día solo. El proceso completo está en
[docs/RELEASE.md](docs/RELEASE.md).

## Los agentes de IA

Las reglas para los agentes están en `AGENTS.md`. Nunca hacen commits. Preparan la guía en
`tmp/{rama}/commit-guide.md` y el cuerpo del PR en `tmp/{rama}/pr-body.md`, y la persona los corre.
