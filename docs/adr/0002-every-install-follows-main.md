---
status: "proposed"
date: 2026-10-22
decision-makers: el desarrollador
spec: ~
---

# Cada instalación sigue a `main`

## Contexto y planteamiento del problema

agent-keepalive se instala clonando el repositorio, y `keepalive update` lo pone al día. Hay que decidir a qué
apunta esa actualización, si a `main` o a la última versión publicada. La herramienta vive en servidores donde
nadie la revisa a diario, y lo que se espera de ella es que siga enviando, así que un arreglo tiene que llegar sin
que alguien tenga que esperar una versión.

## Factores de decisión

- Que un arreglo llegue a cada instalación en cuanto se fusiona.
- Que actualizar sea un solo comando, sin elegir una versión.
- Que una instalación pueda volver a una versión conocida si algo sale mal.
- Cero piezas nuevas para publicar, sin paquetes ni servidor de descargas.

## Opciones consideradas

- Cada instalación sigue a `main`, y las versiones son etiquetas de lo que ya llegó
- Cada instalación sigue la última etiqueta `v*`
- Un paquete (deb o tarball) por versión

## Resultado de la decisión

Opción elegida: «Cada instalación sigue a `main`, y las versiones son etiquetas de lo que ya llegó», porque es la
única con la que un arreglo llega sin esperar el PR de versión, y deja de todos modos una etiqueta por versión a
la que volver.

### Consecuencias

- Bien, porque actualizar es traer `main` con git, sin paquetes ni descargas aparte.
- Bien, porque Release Please sigue numerando y escribiendo el changelog de lo que llegó.
- Mal, porque un merge roto llega a todas las instalaciones. Por eso `main` siempre funciona y el CI corre las
  pruebas de la terminal antes de cada merge, como pide el [ADR 0001](0001-every-change-through-an-issue-and-a-pull-request.md).
- Neutral, porque la versión instalada puede llevar cambios que todavía no tienen número.

### Confirmación

`keepalive update` lleva la copia a `origin/main`, y `ci.yml` corre en cada pull request a `main`. Que un
cambio no rompa una instalación de la versión anterior lo revisa la skill `verification-before-completion`, y lo
prueba un escenario de `tests/` cuando el cambio toca lo que guarda la instalación.

## Ventajas y desventajas de las opciones

### Cada instalación sigue a `main`

- Bien, porque el arreglo llega con el merge.
- Mal, porque no hay una etapa de prueba entre el merge y las instalaciones.

### Cada instalación sigue la última etiqueta `v*`

- Bien, porque solo llega lo que ya tiene número.
- Mal, porque un arreglo espera a que alguien fusione el PR de versión, y la actualización tiene que buscar la
  etiqueta.

### Un paquete por versión

- Bien, porque se instala sin git.
- Mal, porque suma un paso de publicación y un lugar de descarga que mantener.

## Más información

El proceso de versiones está en [`docs/RELEASE.md`](../RELEASE.md).

**Origen:** la issue #12, que deja por escrito una decisión que el repositorio sigue desde la 1.0.0.
