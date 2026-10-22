# Architecture Decision Records

Registro de las decisiones arquitectónicas de agent-keepalive.

Un ADR captura el contexto que generó la decisión, contra qué factores se midió, las alternativas
evaluadas, la decisión tomada, sus consecuencias y cómo se comprueba que se sigue cumpliendo. Se crea uno
por decisión relevante y nunca se borra. Si una decisión cambia, se crea un ADR nuevo y el anterior pasa a
`superseded by ADR-NNNN`.

**Estos ADR siguen [MADR 4.0.0](https://adr.github.io/madr/)** (Markdown Any Decision Records). La
plantilla está más abajo y la decisión de adoptarlo es el [ADR 0000](./0000-use-madr-for-adrs.md).

**La carpeta es el índice.** Los archivos están numerados y su título va en el encabezado, así que un
listado a mano solo añadiría una copia que se desincroniza. El estado y la spec de origen de cada decisión
viven en su propio frontmatter.

Cuándo una decisión amerita un ADR, y dónde va si no lo amerita: [`CONTRIBUTING.md`](../../CONTRIBUTING.md).

## Cómo crear un nuevo ADR

1. Copiar la plantilla de abajo.
2. Nombrar el archivo `NNNN-titulo-en-ingles-con-guiones.md` con el siguiente número disponible.
3. Completar las secciones obligatorias, sin «TBD». Las opcionales se eliminan si no aportan.
4. Declarar en `spec` la spec que originó la decisión, y repetirla como «Origen» al final de «Más información».
5. Nacer en `proposed`. Solo el desarrollador lo pasa a `accepted`.

### Extensiones locales del estándar

Dos añadidos sobre MADR 4.0.0, por si alguien compara con la plantilla original:

- **Campo `spec` en el frontmatter.** La trazabilidad va a la spec que originó la decisión. Un ADR sin spec
  lleva `spec: ~` y declara su origen real, como su issue, en «Más información».
- **«Confirmación» es obligatoria**, aunque el estándar la marque opcional. Una decisión sin forma de
  verificarla se incumple sin que nadie lo note, y cuando no existe control automático hay que decirlo.
  Eso convierte la ausencia en trabajo identificable.

### Idioma

Prosa y encabezados en español; nombre de archivo en inglés, igual que las specs. El frontmatter conserva
las claves y los valores del estándar en inglés porque es metadato legible por máquina.

| `status`                 | Significado                                     |
| ------------------------ | ----------------------------------------------- |
| `proposed`               | Escrito, esperando aprobación del desarrollador |
| `accepted`               | Vigente, rige el código de hoy                  |
| `rejected`               | Se evaluó y se decidió no hacerlo               |
| `deprecated`             | Ya no aplica, y nada lo reemplaza               |
| `superseded by ADR-NNNN` | Reemplazado por la decisión que indica          |

## Plantilla

Traducción de la plantilla larga de MADR 4.0.0. Las secciones marcadas como opcionales se eliminan cuando
no aportan; «Confirmación» se espera en todos los ADR de este repositorio.

<!-- prettier-ignore -->
```markdown
---
status: "{proposed | rejected | accepted | deprecated | superseded by ADR-NNNN}"
date: {YYYY-MM-DD de la última actualización}
decision-makers: {quiénes tomaron la decisión}
spec: {"NN" de la spec de origen, o ~}
---

# {título corto, que represente el problema resuelto y la solución encontrada}

## Contexto y planteamiento del problema

{El contexto y el problema en dos o tres frases, o como una historia ilustrativa. Hacer explícito el
alcance de la decisión.}

<!-- Opcional -->

## Factores de decisión

- {factor 1, una cualidad deseada, una preocupación, una restricción o una fuerza}
- {factor 2}

## Opciones consideradas

- {título de la opción 1}
- {título de la opción 2}

## Resultado de la decisión

Opción elegida: «{título de la opción 1}», porque {justificación}.

<!-- Opcional -->

### Consecuencias

- Bien, porque {consecuencia positiva}
- Mal, porque {consecuencia negativa}
- Neutral, porque {consecuencia que no pesa a favor ni en contra}

<!-- Se espera en este repositorio -->

### Confirmación

{Cómo se comprueba el cumplimiento de la decisión. Si no existe control automático, decirlo.}

<!-- Opcional -->

## Ventajas y desventajas de las opciones

### {título de la opción 1}

- Bien, porque {argumento}
- Neutral, porque {argumento}
- Mal, porque {argumento}

<!-- Opcional -->

## Más información

{Evidencia adicional, cuándo revisar la decisión, enlaces a otras decisiones.}
```
