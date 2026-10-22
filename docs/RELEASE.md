# Versiones

## Versionado semántico

agent-keepalive usa [SemVer](https://semver.org/lang/es/), `MAJOR.MINOR.PATCH`. El número vive en
`version.txt`.

| Tipo    | Cuándo                                                        | Ejemplo         |
| ------- | ------------------------------------------------------------- | --------------- |
| `patch` | Un arreglo que no cambia lo que la herramienta hace           | `1.0.0 → 1.0.1` |
| `minor` | Algo nuevo que convive con lo que ya estaba                   | `1.0.1 → 1.1.0` |
| `major` | Un cambio que rompe lo anterior, como un `config.sh` distinto | `1.1.0 → 2.0.0` |

## Cómo sale una versión

Las versiones las publica [Release Please](https://github.com/googleapis/release-please) desde
`.github/workflows/release-please.yml`. Nadie cambia la versión ni `CHANGELOG.md` a mano.

```text
PR (feat/fix/...) fusionado a main con Squash and merge
          │
          ├─▶ ci.yml revisa la sintaxis y corre shellcheck
          ├─▶ Cada instalación ya lo recibe con keepalive update
          │
          ▼
Release Please lee los commits desde la última etiqueta
          │
          ▼
Abre o actualiza el PR de versión
  - Título "chore(release): X.Y.Z"
  - Sube la versión en version.txt y .release-please-manifest.json
  - Escribe la entrada de CHANGELOG.md
          │
          │  Cada PR nuevo que llega a main vuelve a armar el mismo PR
          │
          ▼
Al fusionar el PR de versión
  ✅ Crea la etiqueta vX.Y.Z
  ✅ Crea el release de GitHub con sus notas
```

`keepalive update` sigue a `main`, así que un cambio llega a las instalaciones en cuanto se fusiona su PR. La
versión le pone número y notas a lo que ya llegó, y deja una etiqueta a la que se puede volver.

El PR de versión lo abre GitHub Actions, y GitHub deja sus revisiones esperando aprobación. No hace falta
aprobarlas, porque ese PR solo cambia `CHANGELOG.md`, `version.txt` y el manifiesto.

### Fusionar el PR de versión

Se fusiona con **Squash and merge**, como todos. En `main` queda un commit por versión con el título del PR
(`chore(release): X.Y.Z (#N)`) y sin cuerpo.

### Estrategia de merge, squash

Cada PR deja **un solo commit** en `main`, cuyo asunto es el **título del PR**
(`squash_merge_commit_title=PR_TITLE`, `squash_merge_commit_message=BLANK`). De ahí sale **una entrada por PR**
en el changelog, y el tipo del título decide la sección y el salto de versión. Quien escribe el título del PR
está escribiendo esa entrada, y se publica tal cual en el archivo y en las notas del release.

Con «Create a merge commit», GitHub repite el título del PR en el commit de merge y Release Please cuenta el
cambio dos veces ([googleapis/release-please#2476](https://github.com/googleapis/release-please/issues/2476)).
Por eso solo queda activo el botón de squash.

### De commit a versión

| Título del PR                                         | Versión     |
| ----------------------------------------------------- | ----------- |
| `fix(<scope>):`                                       | patch       |
| `feat(<scope>):`                                      | minor       |
| `feat(<scope>)!:` o `BREAKING CHANGE:` en el cuerpo   | major       |
| `refactor`, `docs`, `style`, `test`, `chore` y `ci`   | sin versión |

> El `!` sobre cualquier tipo sube el `major`, igual que `BREAKING CHANGE:` en el cuerpo.

Mientras desde la última etiqueta solo haya cambios sin versión, Release Please no abre ningún PR.

### Qué llega al changelog

Los ocho tipos son los de `.commitlintrc.json`, que Husky revisa en cada commit y `pr-title-check.yml` en cada
título de PR. Los ocho aparecen en `CHANGELOG.md`, cada uno en su sección.

| Tipo       | Sección                |
| ---------- | ---------------------- |
| `feat`     | Features               |
| `fix`      | Bug Fixes              |
| `refactor` | Code Refactoring       |
| `docs`     | Documentation          |
| `chore`    | Miscellaneous Chores   |
| `ci`       | Continuous Integration |
| `test`     | Tests                  |
| `style`    | Styles                 |

Los encabezados van en inglés porque lo que va debajo son títulos de PR, que siempre se escriben en inglés.

## Arreglo urgente

Un arreglo urgente es un PR `fix` normal contra `main`. Al fusionarlo llega a cada instalación con
`keepalive update`, y Release Please deja el PR de versión con un `patch`.

Para pedir un número exacto, el commit lleva el pie `Release-As:`.

```text
fix(cron): keep the schedule when the agents change

Release-As: 1.0.2
```

## Si Release Please deja de correr

Release Please solo corre con un push a `main`. `.github/workflows/release-guard.yml` revisa cada día a las
09:00, hora de Ciudad de México, que el último commit de `main` tenga su corrida. A un commit de menos de una
hora le da tiempo. Cuando falta la corrida, o falló, la guardia lanza Release Please otra vez y espera hasta
20 minutos. Solo si ese reintento también falla abre el issue «Release Please is not processing main», con la
etiqueta `bug`, y lo cierra en cuanto Release Please vuelve a procesar `main`.

Para lanzarlo a mano, `gh workflow run release-please.yml --ref main`.

## Lo que el repositorio necesita

- **Settings → Actions → General** con «Allow GitHub Actions to create and approve pull requests» encendido,
  para que Release Please abra su PR.
- **Settings → General → Pull Requests** con solo **Allow squash merging**, el mensaje «Default to pull request
  title» y el borrado automático de la rama al fusionar.

## Nota sobre el changelog

La 1.0.0 se publicó a mano, con lo que había en `main` el 2026-10-21, y desde ahí cuenta Release Please. Los
commits anteriores siguen en el historial de git.
