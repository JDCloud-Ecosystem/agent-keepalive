---
status: "proposed"
date: 2026-10-22
decision-makers: el desarrollador
spec: ~
---

# Usar MADR 4.0.0 como plantilla de todos los ADR

## Contexto y planteamiento del problema

agent-keepalive tiene decisiones que siguen mandando mucho después del cambio que las trajo, como que cada
instalación siga a `main`, dónde guarda cada instalación su configuración o cómo se publica una versión. Hasta
ahora vivían en el README, en `AGENTS.md` o en el cuerpo de un pull request, sin las alternativas que se
descartaron ni una forma de comprobar que se cumplen.

## Factores de decisión

- Que el lector distinga una decisión medida de una preferencia.
- Que cada ADR diga cómo se comprueba que se sigue cumpliendo.
- Un formato conocido, que una persona o un agente lea sin aprender una plantilla nueva.
- Cero herramientas nuevas; los ADR son archivos Markdown en git.

## Opciones consideradas

- **MADR 4.0.0**
- **ADR de Nygard**, el formato original de 2011
- **Sin ADR**; las decisiones solo en las specs y en el README

## Resultado de la decisión

Opción elegida: **MADR 4.0.0**, porque trae las secciones de factores de decisión y de confirmación, y es un
estándar publicado con su plantilla y sus convenciones.

### Consecuencias

- Bien, porque un ADR nuevo se escribe rellenando una plantilla que no hay que diseñar.
- Bien, porque «Confirmación» obliga a nombrar el mecanismo que sostiene la decisión.
- Neutral, porque los ADR son más largos que una nota; se leen pocas veces y se consultan durante años.
- Mal, porque nada valida automáticamente que un ADR siga la plantilla.

### Confirmación

No hay control automático. Quien escribe un ADR lo contrasta con la plantilla de
[`README.md`](./README.md), y el desarrollador lo revisa antes de pasarlo a `accepted`.

## Ventajas y desventajas de las opciones

### MADR 4.0.0

- Bien, porque separa factores, opciones, resultado y confirmación en secciones con nombre propio.
- Neutral, porque su ejemplo canónico está en inglés y aquí la prosa va en español.

### ADR de Nygard

- Bien, porque es mínimo.
- Mal, porque no tiene lugar para las alternativas descartadas ni para la confirmación.

### Sin ADR

- Bien, porque es un archivo menos por decisión.
- Mal, porque una spec terminada se congela, y la decisión que seguía mandando queda enterrada en ella.

## Más información

- [MADR](https://adr.github.io/madr/), plantilla y convenciones.
- **Origen:** la issue #12.
