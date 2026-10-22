---
spec: "N"
type: Menu | Cron | Accounts | Install | Chore | Docs | Test
status: draft | approved | in-progress | done
approved_at: ~
---

<!-- N es el número de la issue de la spec. Elegir un valor por campo. type admite combos con " / ". approved_at: fecha al pasar a approved. -->

# N: {Título descriptivo en español}

**Responsable:** @{usuario} · **Issue:** #N · **Branch:** `{feature|fix|refactor|chore|docs}/N-{english-slug}`
**Inicio:** YYYY-MM-DD · **Cierre estimado:** YYYY-MM-DD
**Depende de:** — · **Lo necesita:** —

> **Regla Spec-First:** no iniciar implementación hasta que `status: approved` esté en el frontmatter.
> Una vez aprobada, ejecutar con la skill `executing-plans`.

---

## 1. Visión general

<!-- Desde la perspectiva de quien usa agent-keepalive. ¿Qué problema resuelve y cómo? -->

### Objetivos

<!-- Máximo 3 o 4 puntos concretos. -->

- Sin definir

### Fuera de alcance

<!-- Qué NO se hará en esta spec. Ser explícito previene que el alcance crezca solo. -->

- Sin definir

### Criterios de aceptación

<!-- Condiciones verificables. Formato: "Dado [...], cuando [...], entonces [...]" -->

- [ ] Dado [...], cuando [...], entonces [...]

---

## 2. Experiencia en la terminal

<!-- Si la función no muestra nada, reemplazar toda esta sección por: "No aplica." -->

### Dónde aparece

<!-- El comando (keepalive <comando>), la opción del menú y la pantalla que abre. -->

- Sin definir

### Flujo de interacción

<!-- Secuencia: tecla o comando de la persona → lo que muestra keepalive. Las opciones de una tecla no piden Enter, y 0 vuelve. -->

- Sin definir

### Textos

<!-- Cada texto nuevo, en español. Dos puntos tras una etiqueta, al final de una pregunta y antes de un comando o una lista; nunca punto y coma. Que quepa en 72 columnas. -->

- Sin definir

### Sin terminal

<!-- Qué pasa cuando lo corre el cron o un programa, sin terminal. Si nada cambia: "Sin cambios." -->

- Sin definir

---

## 3. Envíos y datos de la instalación

<!-- Si la función es solo de pantalla, reemplazar toda esta sección por: "No aplica." -->

### Cron

<!-- Líneas que se agregan, cambian o quitan de la crontab. Si no hay: "Sin cambios en el cron." -->

- Sin definir

### Agentes

<!-- Qué comando corre cada agente, qué responde y cómo se lee su respuesta (OK, LIMIT o ERROR). -->

- Sin definir

### Lo que guarda la instalación

<!-- config.sh, logs, token, cuenta. Archivo, formato y quién lo lee. Si no hay: "Sin cambios." -->

- Sin definir

### Actualización

<!-- Qué ve una instalación de la versión anterior después de actualizar, y qué se mueve o se migra solo. -->

- Sin definir

---

## 4. Escenarios de prueba

<!-- El análisis es exhaustivo, la codificación es selectiva. Criterio en AGENTS.md → «Tests That Earn Their Place». -->

### Casos codificados

| Escenario   | Acción | Resultado esperado |
| ----------- | ------ | ------------------ |
| Sin definir | -      | -                  |

### Casos analizados y descartados

<!-- Una tabla vacía significa que el análisis no se hizo, no que no había casos. -->

| Caso        | Qué pasaría si falla | Por qué no lleva test |
| ----------- | -------------------- | --------------------- |
| Sin definir | -                    | -                     |

---

## 5. Plan de implementación

> No iniciar hasta que `status: approved` esté en el frontmatter.

### Tarea 1: {Nombre}

**Archivos:**

- Crear: `...`
- Modificar: `...`

- [ ] **Paso 1.1:** {acción}

  Esperado: `{salida}`

- [ ] **Paso 1.2: Verificar**

  ```bash
  bash tests/run.sh
  ```

  Esperado: todos los escenarios en PASS

---

## 6. Decisiones técnicas

| Decisión    | Alternativas consideradas | Razón |
| ----------- | ------------------------- | ----- |
| Sin definir | -                         | -     |

---

## 7. Archivos afectados

<!-- Completar al terminar la implementación. -->

| Archivo                                   | Acción | Descripción |
| ----------------------------------------- | ------ | ----------- |
| `docs/specs/features/N-{english-slug}.md` | Creado | Esta spec   |

---

## 8. Definition of Done

- [ ] Las verificaciones de `AGENTS.md` → «Verification Commands», todas en verde
- [ ] Casos límite enumerados en §4, cada uno codificado o descartado con su motivo
- [ ] Probado sin terminal, como lo corre el cron, si toca un envío
- [ ] Una instalación de la versión anterior sigue enviando después de actualizar
- [ ] Cada texto nuevo en español, con dos puntos solo donde el español los espera y sin punto y coma
- [ ] `README.md`, `keepalive help` y «About agent-keepalive» de `AGENTS.md` al día

---

## 9. Notas y pendientes

- Sin definir

---

## 10. Registro de cambios

<!-- No modificar las secciones aprobadas; registrar el cambio aquí. -->

| Fecha      | Sección afectada | Cambio | Razón |
| ---------- | ---------------- | ------ | ----- |
| YYYY-MM-DD | -                | -      | -     |
