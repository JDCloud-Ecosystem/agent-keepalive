# Flujo de trabajo en GitHub

Cómo llega un cambio a agent-keepalive, de la issue al release. Vale igual para quien trabaja con IA y para quien
no. La decisión de trabajar así es el [ADR 0001](adr/0001-every-change-through-an-issue-and-a-pull-request.md).

---

## Flujo completo

```text
  ┌──────────┐     ┌──────────────────┐     ┌─────────────────────────────┐
  │  IDEA    │────▶│  Issue           │────▶│  Spec (solo funcionalidad)  │
  │          │     │  con su plantilla│     │  docs/specs/features/N-*.md │
  └──────────┘     └──────────────────┘     └──────────────┬──────────────┘
                                                           │
                                                           ▼
                   ┌───────────────┐     ┌─────────────────────────────────┐
                   │ ready-to-code │◀────│ status: approved en la spec     │
                   └───────┬───────┘     │ (Spec Review si hace falta)     │
                           │             └─────────────────────────────────┘
                           ▼  rama {tipo}/N-{english-slug}
                   ┌───────────────┐     ┌────────────────────────────────┐
                   │ Implementar   │────▶│ PR a main, con su plantilla    │
                   │ y verificar   │     │ CI y título revisados          │
                   └───────────────┘     └───────────────┬────────────────┘
                                                         │ Squash and merge
                                                         ▼
                   ┌──────────────────────────────────────────────────────┐
                   │ Cada instalación lo recibe con su próxima            │
                   │ actualización, y Release Please arma el PR de versión│
                   └──────────────────────────────────────────────────────┘
```

**Paso a paso**

1. Abrir la issue con la plantilla que corresponde.
2. Si es una funcionalidad, escribir la spec en `docs/specs/features/{N}-{english-slug}.md`, con `N` el número de
   la issue.
3. El desarrollador aprueba la spec (`status: approved`) y la issue pasa a `ready-to-code`. Si alguien más debe
   revisarla, se abre una issue de Spec Review.
4. Crear la rama desde `main`, `{tipo}/{N}-{english-slug}`.
5. Implementar y pasar las verificaciones de `AGENTS.md`.
6. Abrir el PR a `main` con la plantilla y `Closes #N`. El CI y la revisión del título corren solos.
7. Fusionar con **Squash and merge**. El título del PR queda como el commit de `main` y cierra la issue.
8. Cada instalación recibe el cambio con su próxima actualización, y Release Please deja lista la versión, como
   cuenta [RELEASE.md](RELEASE.md).

---

## 1. Plantillas de issue

En **New issue** hay cuatro plantillas. Las issues en blanco están apagadas, así que siempre se usa una.

### Vertical Slice (`feature.yml`)

**Cuándo.** Una funcionalidad nueva o un cambio de comportamiento. Cada Slice entrega algo completo para quien
usa la herramienta, sea un comando, una pantalla, un envío o lo que guarda la instalación.

| Campo                   | Qué poner                                                          |
| ----------------------- | ------------------------------------------------------------------ |
| Spec asociado           | La ruta en `docs/specs/features/`, con el número de la issue       |
| Prioridad               | P0, crítico, a P3, bajo                                            |
| Tipo de cambio          | Menú y comandos, envío de sesiones, datos de la instalación        |
| Parte afectada          | El menú, el cron, las cuentas, la instalación y la actualización   |
| Descripción             | Qué hace el Slice, con el flujo completo                           |
| Criterios de aceptación | Condiciones medibles, Dado, Cuando, Entonces                       |
| Casos límite            | Todo lo que puede salir mal, no solo lo que se va a probar         |

Pone solas las labels `feature` y `needs-spec`.

### Bug Report (`bug-report.yml`)

**Cuándo.** Algo no funciona como debería. Pide los pasos para reproducirlo, lo esperado y lo que pasa, la
pantalla, las versiones de agent-keepalive y de los agentes, el log y si pasa desde el cron o a mano. Pone la
label `bug`.

### Chore (`chore.yml`)

**Cuándo.** Trabajo que no le entrega nada nuevo a quien usa la herramienta, como un refactor, dependencias,
configuración, el CI o la documentación técnica. No necesita spec, pero sí justificación y un criterio de
completado claro. Pone la label `chore`.

### Spec Review (`spec-review.yml`)

**Cuándo.** La spec está escrita y alguien más tiene que revisarla antes de programar. Trae la lista de lo que
una spec de agent-keepalive debe cubrir. Pone la label `needs-spec`.

### Rama y PR por plantilla

Cada plantilla termina con su bloque «Rama y PR». Esta tabla es la que ese bloque resume.

| Plantilla      | Rama                                                                                            | Título del PR        |
| -------------- | ----------------------------------------------------------------------------------------------- | -------------------- |
| Vertical Slice | `feature/{N}-{english-slug}`                                                                    | `feat(<scope>): …`   |
| Bug Report     | `fix/{N}-{english-slug}`                                                                        | `fix(<scope>): …`    |
| Chore          | según el tipo de tarea, `refactor/`, `chore/`, `docs/`, `test/` o `ci/`, y `{N}-{english-slug}` | `<type>(<scope>): …` |
| Spec Review    | No aplica, la rama sale de la issue de funcionalidad                                            | No aplica            |

Todas salen de `main` y el PR apunta a `main`. El slug va en inglés y coincide con el número de la issue y con
el de la spec.

### Issues creadas por la IA

La IA crea las issues con `gh`. Escribe el cuerpo en Markdown con los mismos campos de la plantilla, como
`### Campo` y su respuesta, lo guarda en `tmp/{N}/issue-body.md` y lo pasa entero a `gh`.

```bash
gh issue create --title "[Slice]: Pausar los envíos por un día desde el menú" --label feature --label needs-spec --body-file tmp/21/issue-body.md
```

**El cuerpo va limpio.** Solo los campos de la plantilla, sin ejemplos ni el bloque de rama y PR. Si conviene
dejar la rama y el título del PR como referencia, van en un comentario HTML al final, que no se ve.

```markdown
<!-- Rama: feature/21-pause-for-a-day, PR: feat(menu): pause every send for one day from the menu -->
```

Cada issue entra al tablero [agent-keepalive Project](https://github.com/orgs/JDCloud-Ecosystem/projects/1). La
IA la agrega al crearla y le pone su **Status** y su **Priority**, que repite la prioridad de la issue.

```bash
gh project item-add 1 --owner JDCloud-Ecosystem --url https://github.com/JDCloud-Ecosystem/agent-keepalive/issues/21
```

| Status        | Cuándo                                                |
| ------------- | ----------------------------------------------------- |
| `Backlog`     | Abierta, todavía sin spec aprobada                    |
| `Ready`       | Lista para construir, con la spec aprobada si la pide |
| `In progress` | Con su rama abierta                                   |
| `In review`   | Con su pull request abierto                           |
| `Done`        | Con el pull request fusionado                         |

---

## 2. Labels

Las de tipo y estado se usan a lo largo del flujo.

| Label           | Uso                                             |
| --------------- | ----------------------------------------------- |
| `feature`       | Funcionalidad nueva                             |
| `bug`           | Error o comportamiento inesperado               |
| `chore`         | Tarea técnica, configuración, dependencias o CI |
| `docs`          | Documentación                                   |
| `refactor`      | Refactor sin cambio de comportamiento           |
| `testing`       | Pruebas o cobertura                             |
| `needs-spec`    | Falta la spec aprobada antes de programar       |
| `ready-to-code` | Spec aprobada, lista para construir             |
| `in-review`     | PR abierto, en revisión                         |
| `blocked`       | Bloqueada por algo externo                      |
| `P0-critical`   | Incidente activo, como instalaciones sin enviar |

| Momento                  | Labels                                     |
| ------------------------ | ------------------------------------------ |
| Se abre la funcionalidad | `feature` y `needs-spec`                   |
| Spec aprobada            | `needs-spec` se cambia por `ready-to-code` |
| PR abierto               | Se suma `in-review`                        |
| PR fusionado             | La issue se cierra sola con `Closes #N`    |

---

## 3. Spec-First

**Sin spec aprobada no se escribe código.** La spec es la fuente de verdad de lo que se construye.

- Se escribe con la skill `brainstorming`, desde `docs/specs/features/_TEMPLATE.md`, en español.
- El archivo es `docs/specs/features/{N}-{english-slug}.md`, con `N` el número de su issue y el mismo slug de la
  rama.
- Su prosa pasa por la skill `humanizing-text` antes de pedir la aprobación.

```text
Issue #21 «Pausar los envíos por un día desde el menú»
  → docs/specs/features/21-pause-for-a-day.md
  → rama feature/21-pause-for-a-day
```

| `status` en el frontmatter | Significa                      |
| -------------------------- | ------------------------------ |
| `draft`                    | En redacción, no se implementa |
| `approved`                 | Aprobada, lista para programar |
| `in-progress`              | Implementación en curso        |
| `done`                     | Implementada y verificada      |

Si el plan cambia durante la implementación, las secciones aprobadas no se tocan. El cambio se anota en la
sección 10, «Registro de cambios».

---

## 4. Plantilla de PR

Cada PR se abre con `.github/PULL_REQUEST_TEMPLATE.md`.

- **Resumen**, de 2 a 4 puntos concretos, con los comandos, pantallas o archivos que tocó, y `Closes #N`.
- **Tipo de cambio** y **Spec asociado**, o «N/A» en un chore o un arreglo sin spec.
- **Definition of Done**, lo obligatorio siempre y lo condicional que aplique.
- **Cómo verificar manualmente** en una máquina de prueba.
- **Pantallas** copiadas como texto cuando cambia algo en la terminal.
- **Notas para el reviewer**, las decisiones difíciles y lo que queda pendiente.

El título del PR sigue Conventional Commits, en inglés y con scope. `pr-title-check.yml` lo revisa, porque con
Squash and merge ese título es el commit que queda en `main` y, si es `feat` o `fix`, la línea del changelog que
lee quien actualiza.

---

## 5. Nombres de rama

```text
<tipo>/<número-de-issue>-<descripción-en-inglés>
```

| Issue         | Rama        | Tipo de commit | Ejemplo                                  |
| ------------- | ----------- | -------------- | ---------------------------------------- |
| Funcionalidad | `feature/`  | `feat`         | `feature/13-update-check-and-changelog`  |
| Bug           | `fix/`      | `fix`          | `fix/15-night-session-skips-sundays`     |
| Refactor      | `refactor/` | `refactor`     | `refactor/14-tidy-repository-layout`     |
| Configuración | `chore/`    | `chore`        | `chore/20-update-commitlint`             |
| Documentación | `docs/`     | `docs`         | `docs/12-issue-and-pull-request-flow`    |
| Pruebas       | `test/`     | `test`         | `test/22-update-from-every-version`      |
| CI            | `ci/`       | `ci`           | `ci/23-run-the-tests-on-debian`          |

**Reglas**

- Toda rama sale de `main`, que es el tronco y lo que sigue cada instalación. No hay rama `develop`.
- Una issue, una rama. El trabajo de dos issues no se junta.
- Ramas cortas, que lleguen a `main` cuanto antes.
- El PR se fusiona con **Squash and merge**, el único botón que el repositorio permite.
- Ningún commit lleva atribución a una IA, ni en el mensaje ni como coautor.
- Los agentes de IA nunca hacen commits ni push. Escriben la guía de commits en `tmp/{N}/commit-guide.md` y el
  cuerpo del PR en `tmp/{N}/pr-body.md`, una carpeta por issue, cuando el desarrollador lo pide.
- La guía es un solo bloque `bash` con la rama, cada `git add … && git commit`, el `git push` y el
  `gh pr create`. Solo lleva `git` y `gh`, así que corre igual en Windows, macOS o Linux, en cualquier terminal.
- Con el PR abierto, esos dos archivos ya no cambian. Cada arreglo posterior es un solo commit, que la IA da en
  el chat en una línea. Con Squash and merge el historial de `main` queda igual.

```bash
git switch main
git pull --ff-only
git switch -c feature/21-pause-for-a-day
```

---

## 6. Versiones

Las publica Release Please con cada push a `main`. El proceso completo está en [RELEASE.md](RELEASE.md).

---

## 7. Referencia rápida

```bash
gh issue create --title "[Chore]: ..." --label chore --body-file tmp/N/issue-body.md
gh issue edit N --remove-label needs-spec --add-label ready-to-code
gh pr create --base main --title "<type>(<scope>): ..." --body-file tmp/N/pr-body.md
gh pr view --json number,state,url
gh pr checks
gh workflow run release-please.yml --ref main
```
