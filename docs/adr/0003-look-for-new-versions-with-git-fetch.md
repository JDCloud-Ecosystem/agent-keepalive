---
status: "proposed"
date: 2026-10-22
decision-makers: el desarrollador
spec: "13"
---

# Buscar versiones nuevas con un git fetch de main

## Contexto y planteamiento del problema

Una instalación solo se enteraba de una versión nueva si alguien corría `keepalive update` por su cuenta. La spec
13 pide que la herramienta lo busque sola, una vez al día, y que diga qué trae cada versión antes de actualizar.
Hay que decidir de dónde sale esa información y qué parte del sistema la busca. La herramienta corre en
servidores sin nadie mirando, a veces sin red, y cada instalación ya es un clon de git del repositorio.

## Factores de decisión

- Cero llaves, cuentas o dependencias nuevas; la máquina ya tiene git.
- Que sin red no se trabe nada, ni el menú ni un envío.
- Que mostrar si hay versión nueva, y qué trae, no dependa de la red en ese momento.
- Que llegue también a las instalaciones donde nadie abre el menú.
- Que no sume nada que desinstalar ni que migrar.

## Opciones consideradas

- Un `git fetch` de main, lanzado por cada envío y por el menú, a lo más una vez cada 20 horas
- La API de releases de GitHub, consultada con `curl`
- Una línea propia en el crontab que revise una vez al día

## Resultado de la decisión

Opción elegida: «Un `git fetch` de main, lanzado por cada envío y por el menú, a lo más una vez cada 20 horas»,
porque usa el clon que ya existe y deja en `origin/main` la versión y el `CHANGELOG.md` nuevos, de modo que el menú
los lee sin red. El envío lo lanza en segundo plano, así que llega a cada instalación que tiene sesiones activas
sin una línea más en el crontab.

### Consecuencias

- Bien, porque no hay llaves ni límites de la API, y una instalación sin acceso a GitHub simplemente no se entera.
- Bien, porque la fecha de `FETCH_HEAD` es el reloj de la última revisión, sin un archivo de estado aparte.
- Bien, porque el changelog que se muestra es el de la misma rama que se va a instalar.
- Mal, porque una instalación sin días ni sesiones activas solo revisa cuando alguien abre el menú.
- Neutral, porque un fetch baja también los commits nuevos, que la actualización usa después.

### Confirmación

`check_update` en `lib.sh` es la única que busca, y `tests/drive.py` (`t_update_scenarios`) prueba que sin red
la actualización lo dice, que con un remoto que no responde ni el menú ni un envío esperan, y que una revisión
reciente no se repite.

## Ventajas y desventajas de las opciones

### Un `git fetch` de main, desde los envíos y el menú

- Bien, porque usa el clon y la autenticación que la instalación ya tiene.
- Mal, porque depende de que haya envíos o de que alguien abra el menú.

### La API de releases de GitHub

- Bien, porque trae las notas de cada release ya separadas.
- Mal, porque solo ve versiones publicadas, no lo que llegó a `main` sin número, y tiene un límite de consultas sin
  llave.
- Mal, porque el changelog tendría que bajarse aparte, y sin red el menú no tendría qué mostrar.

### Una línea propia en el crontab

- Bien, porque revisa aunque no haya envíos.
- Mal, porque es una línea más que escribir, migrar en cada instalación existente y quitar al desinstalar.

## Más información

**Origen:** la spec [13](../specs/features/13-update-check-and-changelog.md), issue #13.
