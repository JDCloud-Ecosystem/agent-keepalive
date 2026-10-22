## Resumen

<!-- 2 a 4 puntos con qué cambia para quien usa agent-keepalive. Nombrar comandos, pantallas, scripts o archivos de la instalación. -->

-

Closes #N

## Tipo de cambio

- [ ] Funcionalidad
- [ ] Arreglo
- [ ] Refactor
- [ ] Documentación
- [ ] Chore (configuración, dependencias, CI)

## Spec asociado

<!-- Enlace a la spec si existe. Si es un chore o un arreglo sin spec, escribir "N/A". -->

[`docs/specs/features/N-{slug}.md`](../docs/specs/features/N-slug.md)

## Definition of Done

### Siempre obligatorio

- [ ] `bash tests/lint.sh` y `bash tests/run.sh` en verde
- [ ] Sin tokens ni códigos de inicio de sesión en la salida ni en los logs
- [ ] Spec actualizada si hubo cambios de alcance

### Condicional, marcar solo las que apliquen a este PR

- [ ] _(Pantallas)_ Cada texto nuevo en español, sin dos puntos ni punto y coma dentro de una oración, y cabe en 72 columnas
- [ ] _(Envío o cron)_ Probado sin terminal, como lo corre el cron
- [ ] _(Agentes)_ `keepalive test` en una máquina de prueba, con lo que respondió cada agente
- [ ] _(Datos de la instalación)_ Una instalación de la versión anterior sigue enviando después de actualizar, con su horario y su historial
- [ ] _(Comando nuevo)_ En `keepalive help`, en el README y en su prueba de `tests/`

### Cómo verificar manualmente

<!-- Pasos exactos en una máquina de prueba. Qué correr y qué observar. -->

1. `bash tests/run.sh`
2. En una máquina de prueba, `keepalive update` y luego `keepalive`
3. Elegir...
4. Ver que...

## Pantallas (si aplica)

<!-- Las pantallas que cambian, copiadas como texto de la terminal. Omitir si no hay pantallas afectadas. -->

## Notas para el reviewer

<!-- Decisiones difíciles, limitaciones conocidas, issues de seguimiento. Dejar en blanco si no aplica. -->
