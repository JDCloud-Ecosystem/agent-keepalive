---
status: "proposed"
date: 2026-10-22
decision-makers: el desarrollador
spec: ~
---

# Cada cambio pasa por una issue y un pull request

## Contexto y planteamiento del problema

Cada instalación de agent-keepalive sigue a `main`, así que un merge llega a todas con su próxima actualización.
Hasta la 1.0.1 los cambios entraron por pull requests con una rama sin número, sin issue que dijera qué se pidió
ni con qué criterio se daba por terminado, sin spec y sin un lugar para las decisiones. Tampoco había una prueba
que repitiera lo que una persona hace en el menú, solo la sintaxis y shellcheck. El desarrollador pidió llevar
el repositorio al flujo de issue, spec, rama y pull request, con las pruebas de la terminal en el CI.

## Factores de decisión

- Que cada cambio tenga un lugar donde se pidió, con su criterio de completado.
- Que el CI pruebe un cambio, menú y cron incluidos, antes de que llegue a `main` y de ahí a cada instalación.
- Que el changelog que lee quien actualiza salga de títulos revisados.
- Que la IA siga sin hacer commits y que la guía corra igual en cualquier terminal.

## Opciones consideradas

- Issue, spec con el número de la issue, rama y pull request con Squash and merge
- Pull request sin issue, como hasta la 1.0.1
- Commits directos a `main`

## Resultado de la decisión

Opción elegida: «Issue, spec con el número de la issue, rama y pull request con Squash and merge», porque es la
única que deja escrito el pedido y su criterio, prueba el cambio antes de `main` y revisa el título que se
convierte en la línea del changelog.

### Consecuencias

- Bien, porque cada issue se cierra con su pull request, y el camino de la idea al release queda completo.
- Bien, porque `ci.yml` corre las pruebas de la terminal en cada pull request, y `pr-title-check.yml` revisa el
  título que queda en `main`.
- Bien, porque la spec toma el número de su issue, que existe antes que la rama.
- Mal, porque un cambio chico también lleva issue y pull request.
- Neutral, porque el pull request de versión lo abre `github-actions[bot]` y no lleva issue, como ya pasaba.

### Confirmación

`.github/ISSUE_TEMPLATE/config.yml` no permite issues en blanco, `pr-title-check.yml` rechaza un título fuera de
Conventional Commits, `ci.yml` corre `tests/lint.sh` y `tests/run.sh` en cada pull request y el repositorio solo
permite Squash and merge. Que cada pull request lleve `Closes #N` no tiene control automático, lo revisa quien lo
fusiona.

## Ventajas y desventajas de las opciones

### Issue, spec con el número de la issue, rama y pull request con Squash and merge

- Bien, porque el pedido, la spec, la rama y el pull request comparten un número.
- Bien, porque el CI y la revisión del título corren antes del merge.
- Mal, porque suma un paso a cada cambio, abrir la issue.

### Pull request sin issue, como hasta la 1.0.1

- Bien, porque el CI corre antes de `main`.
- Mal, porque el pedido y su criterio quedan sueltos en el cuerpo del pull request, y la spec no tiene un número
  estable antes de abrir la rama.

### Commits directos a `main`

- Bien, porque es el camino más corto.
- Mal, porque un error llega a cada instalación antes de que el CI lo vea.

## Más información

El flujo completo está en [`docs/GITHUB-WORKFLOW.md`](../GITHUB-WORKFLOW.md).

**Origen:** la issue #12.
