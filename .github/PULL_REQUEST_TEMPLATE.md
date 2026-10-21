## Resumen

<!-- Qué cambia para quien usa agent-keepalive, en 2 a 4 puntos. -->

-

## Cómo se probó

- [ ] `bash -n` y `shellcheck -x --severity=error` sin errores
- [ ] `keepalive test` en una máquina de prueba, si cambia el envío, el inicio de sesión o el horario
- [ ] Cada texto nuevo en el bloque `es` y en el bloque `en` de su script
- [ ] Sin tokens ni códigos de inicio de sesión en la salida ni en los logs
