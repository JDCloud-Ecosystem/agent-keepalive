---
spec: "13"
type: Menu / Install
status: done
approved_at: 2026-10-22
---

# 13: Avisar cuando hay una versión nueva, con su changelog, y actualizar aunque cambie la historia

**Responsable:** @JohnyDeCoder · **Issue:** #13 · **Branch:** `feature/13-update-check-and-changelog`
**Inicio:** 2026-10-22 · **Cierre estimado:** 2026-10-22
**Depende de:** #12 · **Lo necesita:** #11, #14

> **Regla Spec-First:** no iniciar implementación hasta que `status: approved` esté en el frontmatter.
> Una vez aprobada, ejecutar con la skill `executing-plans`.

---

## 1. Visión general

Hoy una instalación solo se entera de una versión nueva si alguien corre `keepalive update`, y entonces la baja
sin decir qué trae. Además, ese `git pull --ff-only` deja de avanzar si la historia de `main` se reescribe, aunque
los archivos sean los mismos. Con esta spec la herramienta revisa sola una vez al día, el menú avisa cuando hay
una versión nueva, la actualización muestra los cambios de cada versión y pregunta, y avanza también después de
una reescritura.

### Objetivos

- Revisar GitHub una vez al día sin demorar ningún envío ni el menú.
- Decir en el menú la versión instalada y si hay una nueva, y a qué versión lleva la opción de actualizar.
- Mostrar los cambios de cada versión nueva en una tabla antes de preguntar si actualizar.
- Actualizar aunque `main` se haya reescrito con el mismo contenido, sin perder nada de la persona.

### Fuera de alcance

- Actualizar solo, sin preguntar. La revisión avisa, la persona decide.
- Traducir el changelog. Las entradas son los títulos de los pull requests, en inglés.
- Mover la configuración o los logs fuera del código, que es el #14.

### Criterios de aceptación

- [x] Dada una versión nueva en `main`, cuando corre la revisión, entonces el menú la anuncia con su número
- [x] Dada la opción de actualizar, cuando hay versión nueva, entonces muestra sus cambios en una tabla antes de preguntar
- [x] Dado un repositorio con la historia reescrita y el mismo contenido, cuando se actualiza, entonces avanza al `main` nuevo sin tocar la configuración
- [x] Dada una copia con commits propios, cuando se actualiza, entonces no se borra nada y lo dice
- [x] Sin red, la revisión termina en segundos y el menú no espera

---

## 2. Experiencia en la terminal

### Dónde aparece

- El resumen de arriba del menú y de `keepalive status` suma la línea `Versión`, con «hay una nueva, la X» en
  amarillo cuando la hay.
- La opción 7 del menú dice «Actualizar agent-keepalive a la X» cuando hay versión nueva.
- La pantalla ACTUALIZAR AGENT-KEEPALIVE, desde la opción 7 o con `keepalive update`.
- La pantalla CAMBIOS DE CADA VERSIÓN, con `keepalive changelog`.

### Flujo de interacción

- `7` → «Buscando la versión más reciente en GitHub.» → si no hay nada nuevo, «Ya tienes la versión más
  reciente» y `0` vuelve.
- Con versión nueva → «Hay una versión nueva, la X. Tienes la Y.», la tabla de cambios y «¿Actualizar ahora?
  (s o n)», que se contesta con una tecla.
- `n` → «No se actualizó.» y `0` vuelve al menú, que sigue mostrando el aviso.
- `s` → «Actualizado de Y a X. Tu horario sigue igual.» y el menú se abre otra vez con la versión nueva.
- `keepalive update --yes`, o sin terminal, no pregunta.

### Textos

- `Versión        1.1.0, hay una nueva, la 1.2.0`
- `Actualizar agent-keepalive a la 1.2.0`
- `Buscando la versión más reciente en GitHub.`
- `Hay una versión nueva, la 1.2.0. Tienes la 1.1.0.` (sin número instalado, solo la primera frase)
- `Hay cambios nuevos en main que todavía no tienen número de versión.`
- `¿Actualizar ahora?` y `No se actualizó. La opción sigue en el menú para cuando quieras.`
- `Tus cambios a mano en los archivos quedaron guardados, y git stash list los muestra.`
- `Esta copia tiene commits propios que no están en GitHub, así que no se tocó nada.`
- `No se pudo revisar GitHub. Revisa la conexión y vuelve a intentarlo. Esto respondió git.`
- La tabla lleva `Versión`, `Tipo` y `Cambio`. Los tipos son Nuevo, Arreglo, Importante, Resumen e Interno, y
  debajo va `Cada cambio va como quedó en CHANGELOG.md, en inglés.`

### Sin terminal

- `keepalive update` actualiza sin preguntar, para los programas que lo corren por alguien.
- La revisión diaria corre desde el envío del cron, en segundo plano y sin salida.

---

## 3. Envíos y datos de la instalación

### Cron

- Sin cambios en el cron. `session-starter.sh` lanza `check_update --if-stale` en segundo plano al empezar.

### Agentes

- Sin cambios. El envío no espera a la revisión.

### Lo que guarda la instalación

- `~/.config/agent-keepalive/update.lock`, el candado de la revisión, vacío.
- `origin/main` y `FETCH_HEAD` del clon, que git ya mantenía. La fecha de `FETCH_HEAD` dice cuándo fue la última
  revisión.
- La configuración, los logs y el token no cambian.

### Actualización

- Una instalación de la versión anterior actualiza con su propio `git pull --ff-only` y queda con este código.
  Desde ahí, cada actualización usa el camino nuevo.
- Si `main` ya se reescribió, la versión anterior no puede avanzar sola. El README deja los dos comandos que la
  ponen al día.
- Después de mover el clon, la actualización corre `keepalive migrate` con el código nuevo, que reescribe el
  crontab con las rutas de esa versión.

---

## 4. Escenarios de prueba

### Casos codificados

| Escenario                         | Acción                                                     | Resultado esperado                                          |
| --------------------------------- | ---------------------------------------------------------- | ----------------------------------------------------------- |
| Al día                            | `7` en el menú                                             | «Ya tienes la versión más reciente»                         |
| Versión nueva                     | Publicar 9.9.9 con su changelog, `7`                       | Tabla con Nuevo y Arreglo, sin enlaces ni lo interno        |
| Decir que no                      | `n`                                                        | «No se actualizó», el menú sigue avisando la 9.9.9          |
| Decir que sí                      | `7` y `s`                                                  | «Actualizado de 1.0.1», el menú se abre en la 9.9.9         |
| Historia reescrita, mismo contenido | `filter-branch` arriba, `keepalive update --yes`         | «Ya tienes», HEAD igual a `origin/main`, `config.sh` igual  |
| Historia reescrita y versión nueva | Lo mismo con una versión encima                           | «Actualizado», el crontab apunta al código nuevo            |
| Solo cambios internos             | Una versión con solo Documentation                         | Una fila Interno                                            |
| Copia adelante de main            | Un commit local con la 99.0.0                              | «Ya tienes la versión más reciente, 99.0.0»                 |
| Sin número instalado              | Sin `version.txt`                                          | Solo «Hay una versión nueva, la X.», con todas las versiones |
| Commits propios                   | Un commit local y una versión nueva arriba                 | Sale con error, «commits propios», nada se movió            |
| Cambios a mano                    | Editar `README.md` y actualizar                            | «quedaron guardados», el stash existe, el archivo al día    |
| Sin red                           | Remoto inexistente                                         | «No se pudo revisar GitHub», nada se movió                  |
| Revisión reciente                 | `FETCH_HEAD` de hoy y remoto roto, `check_update --if-stale` | No revisa y sale bien                                     |
| Remoto que no responde            | Remoto que tarda 50 s, abrir el menú y hacer un envío      | El menú aparece en menos de 5 s y el envío termina en OK    |
| El changelog                      | `keepalive changelog`                                      | 1.0.1 con su arreglo y 1.0.0 con su resumen, en 74 columnas |

### Casos analizados y descartados

| Caso                                              | Qué pasaría si falla                                   | Por qué no lleva test                                         |
| ------------------------------------------------- | ------------------------------------------------------ | ------------------------------------------------------------- |
| La 1.0.1 publicada actualiza a este código        | La instalación no recibiría la revisión                | Se probó a mano con la 1.0.1 de GitHub; la prueba fija va en el #14, que es el que mueve datos |
| Dos envíos en el mismo minuto                     | Dos fetch a la vez                                     | `flock -n` los pone en fila y git aguanta dos fetch seguidos  |
| Un remoto por SSH que pide la huella del servidor | El fetch se quedaría esperando una respuesta           | `BatchMode=yes` lo hace fallar al momento, y el límite de un minuto lo corta igual |
| Un changelog con una versión `Unreleased`         | Una fila sin número                                    | Release Please no la escribe                                  |
| Archivos nuevos sin seguimiento que la versión nueva trae | El fast-forward fallaría                       | El reset posterior los reemplaza por los de la versión         |
| Un clon superficial, sin historia                 | No sabría reconocer una reescritura                    | El README instala con un clon completo                         |

---

## 5. Plan de implementación

### Tarea 1: La revisión

**Archivos:**

- Modificar: `lib.sh`, `session-starter.sh`

- [x] **Paso 1.1:** `installed_version`, `latest_version`, `version_newer`, `newer_version` y `check_update` en
  la sección Updates de `lib.sh`.
- [x] **Paso 1.2:** `session-starter.sh` lanza `check_update --if-stale` en segundo plano.

### Tarea 2: El aviso, la tabla y la actualización

**Archivos:**

- Modificar: `keepalive`

- [x] **Paso 2.1:** La línea `Versión` en `_overview` y la etiqueta de la opción 7.
- [x] **Paso 2.2:** `_changelog_entries`, `_wrap` y `_changes_table`.
- [x] **Paso 2.3:** `update [--yes]` con `_move_to_main`, y los comandos `changelog` y `migrate`.

### Tarea 3: Pruebas y documentación

**Archivos:**

- Modificar: `tests/drive.py`, `README.md`, `AGENTS.md`
- Crear: `docs/adr/0003-look-for-new-versions-with-git-fetch.md`

- [x] **Paso 3.1: Verificar**

  ```bash
  bash tests/lint.sh
  bash tests/run.sh
  ```

  Esperado: `4 shellcheck warnings, at most 4 allowed.` y `16/16 passed`

---

## 6. Decisiones técnicas

| Decisión                              | Alternativas consideradas                     | Razón                                                          |
| ------------------------------------- | --------------------------------------------- | -------------------------------------------------------------- |
| `git fetch` desde los envíos y el menú | API de GitHub, una línea propia en el crontab | ADR 0003                                                       |
| La fecha de `FETCH_HEAD` como reloj   | Un archivo de estado en `~/.config`           | git ya la mantiene, y nada queda que borrar                    |
| Reconocer la reescritura por el árbol | Comparar mensajes o buscar la etiqueta        | El árbol de HEAD en la historia de main prueba que el contenido es el mismo |
| Correr `keepalive migrate` del código nuevo | Seguir con el código que ya está en memoria | Solo la versión nueva sabe qué guarda una instalación de su versión |
| El changelog en inglés, tal cual      | Traducir, o cambiar los títulos de los PR     | Los títulos siguen Conventional Commits en inglés, y traducir sin red no se puede |

---

## 7. Archivos afectados

| Archivo                                             | Acción     | Descripción                                               |
| --------------------------------------------------- | ---------- | --------------------------------------------------------- |
| `lib.sh`                                            | Modificado | La revisión y las versiones                               |
| `session-starter.sh`                                | Modificado | Lanza la revisión en segundo plano                        |
| `keepalive`                                         | Modificado | La línea de versión, la tabla, la actualización y dos comandos |
| `tests/drive.py`                                    | Modificado | Los escenarios de la actualización y del changelog        |
| `README.md`                                         | Modificado | «Versiones nuevas», los comandos y el arreglo de una instalación vieja |
| `AGENTS.md`                                         | Modificado | Cómo se busca y cómo se actualiza                         |
| `docs/adr/0003-look-for-new-versions-with-git-fetch.md` | Creado | La decisión de buscar con `git fetch`                     |
| `docs/specs/features/13-update-check-and-changelog.md` | Creado  | Esta spec                                                 |

---

## 8. Definition of Done

- [x] Las verificaciones de `AGENTS.md` → «Verification Commands», todas en verde
- [x] Casos límite enumerados en §4, cada uno codificado o descartado con su motivo
- [x] Probado sin terminal, como lo corre el cron, si toca un envío
- [x] Una instalación de la versión anterior sigue enviando después de actualizar
- [x] Cada texto nuevo en español, sin dos puntos ni punto y coma dentro de una oración
- [x] `README.md`, `keepalive help` y «About agent-keepalive» de `AGENTS.md` al día

---

## 9. Notas y pendientes

- La reescritura del #11 va después de este cambio, cuando las instalaciones que administra el desarrollador ya
  tengan esta versión.

---

## 10. Registro de cambios

| Fecha      | Sección afectada | Cambio | Razón |
| ---------- | ---------------- | ------ | ----- |
| 2026-10-22 | -                | -      | -     |
