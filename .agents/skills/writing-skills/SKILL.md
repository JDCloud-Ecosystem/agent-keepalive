---
name: writing-skills
description: >
  Use when creating a new skill or modifying an existing skill in .agents/skills/.
  Enforces the fixed anatomy, a trigger-shaped description, verification with real
  evidence, and propagation to every document that lists the skills.
---

# Writing Skills

## Overview

A skill is a process, not a reference document. It tells an agent what to do next, in what
order, and how to prove the step happened. Anything the agent has to interpret before
acting is prose that belongs somewhere else.

**Core principle:** the `description` field is the trigger. Write it so any agent can
match it against the task at hand and know whether to open the file.

Two rules carry most of the quality. Skills link to the single source instead of copying
it, because two copies of a rule diverge on the first edit and the wrong one wins. And
every skill closes on evidence, because a phase that closes on a claim closes on nothing.

## When to Use

- Creating a new skill under `.agents/skills/`.
- Modifying an existing `SKILL.md`.
- Renaming a skill, or changing what triggers it.
- Adding or changing a shared checklist in `.agents/skills/references/`.

Not for installing external skills.

## Process

### 1. Write the file at `.agents/skills/<name>/SKILL.md`

The folder name and the `name` field match. Shared checklists that more than one skill
consumes go to `.agents/skills/references/`, not into the skill folder.

### 2. Follow the fixed anatomy

Seven sections, these headings, this order. A reader who knows one skill knows where to
look in all of them.

```markdown
---
name: <kebab-case-slug>
description: >
  <When to invoke: the trigger condition, the key action, and the outcome.>
---

# <Skill Title>

## Overview

<What this prevents or enables, and the core principle. Two or three sentences.>

## When to Use

<Explicit triggers as a bullet list. Concrete scenarios, plus what it is NOT for.>

## Process

<Numbered steps. Executable, in order, no tool-specific syntax.>

## Rationalizations

<Table: the excuse the agent uses to skip a step, and its refutation.>

## Red Flags

<Observable anti-patterns in work already done. Table or bullets.>

## Verification

<The evidence that closes the phase. Command plus observable output.>

## Project Context

<Project-specific: commands, paths, conventions, links to the source of each rule.>
```

A skill may add its own sections, such as `The Iron Law` after `Overview` or a checklist
before `Process`. Extra sections never displace the seven or reorder them.

Some skills use `The Process` rather than `Process`. Both read the same; keep whichever
the file already has.

### 3. Keep `Rationalizations` and `Red Flags` apart

They get merged all the time and they catch different failures.

| Section            | Catches                                                      | Shape               |
| ------------------ | ------------------------------------------------------------ | ------------------- |
| `Rationalizations` | The excuse the agent tells itself **before** skipping a step | Excuse → refutation |
| `Red Flags`        | The anti-pattern visible **after** the work is done          | Observable symptom  |

"Too simple to verify" is a rationalization. "Marked the task complete before the output
confirmed it" is a red flag. A skill needs both.

### 4. Write `Verification` with evidence, not with a checkbox

Name the command and the observable output for each claim the phase makes. "Confirm it
works" is not verification. The evidence contract, and what each phase owes, are in
[`references/verification-gates.md`](../references/verification-gates.md).

### 5. Process, not prose

Every step tells the agent what to do. If a paragraph explains a concept the agent does
not act on, it belongs in `docs/` and the skill links to it. Rules that already live in
[`AGENTS.md`](../../../AGENTS.md) or [`CONTRIBUTING.md`](../../../CONTRIBUTING.md) are linked, never restated.

### 6. Load references only when needed

`SKILL.md` holds the complete process. Material a skill needs occasionally, or shares with
other skills, goes to `.agents/skills/references/` and is linked from the step that uses
it. The session pays for the skill file every time; it pays for the reference only when
the step comes up.

### 7. Propagate

Adding, renaming or retiring a skill means editing every document that lists them.
Miss one and the next session gets a different chain depending on which file it read.

| #   | Document                                   | What to update there                        |
| --- | ------------------------------------------ | ------------------------------------------- |
| 1   | `.agents/skills/references/skill-chain.md` | The chain and the trigger table. Canonical  |
| 2   | `AGENTS.md`                                | The methodology skills table                |
| 3   | `CLAUDE.md`                                | The situation-to-skill table                |
| 4   | `GEMINI.md`                                | The workflow skills table                   |
| 5   | `QWEN.md`                                  | The workflow skills table                   |
| 6   | `.agents/skills/using-skills/SKILL.md`     | The trigger list                            |
| 7   | `.agents/skills/writing-skills/SKILL.md`   | This table, if the set of documents changed |

## Rationalizations

| Excuse                                          | Reality                                                              |
| ----------------------------------------------- | -------------------------------------------------------------------- |
| "The description is close enough"               | The description is the trigger. Vague means the skill never opens    |
| "This rule is important, better repeat it here" | Two copies diverge. Link to the source and the skill stays correct   |
| "Verification is obvious for this skill"        | Then write the one line. Obvious steps are the ones that get skipped |
| "I will update the other documents later"       | Later is how the list got incomplete. Propagate in the same change   |
| "Red Flags already covers the excuses"          | They catch different failures. See step 3                            |
| "The anatomy does not fit this skill"           | Add sections, do not drop them. Seven headings is the whole contract |

## Red Flags

- A `SKILL.md` missing one of the seven sections, or carrying them out of order.
- `TBD`, `TODO`, or a step that says what to do without saying how.
- A rule copied from `AGENTS.md` or `CONTRIBUTING.md`.
- Platform-specific tool names in the process, so no `Agent tool`, no `Skill tool`, no `TaskCreate`.
- A skill referenced with a namespace prefix such as `superpowers:`. Name only.
- A new skill that reached `AGENTS.md` and nowhere else.

## Verification

- Every one of the seven sections is present and in order.
- `name` matches the folder name; `description` states the trigger condition.
- No `TBD` and no placeholder steps.
- Each rule either lives here or links to its source, with no rule in both places.
- `Verification` names a command and its observable output.
- The seven documents in step 7 all carry the change.

Every relative link in the changed files opens the file it names.

## Project Context

**Location:** `.agents/skills/<name>/SKILL.md`. Shared checklists in `.agents/skills/references/`.

**Language:** skill files are English, like `AGENTS.md` and `CLAUDE.md`. Templates, specs and `docs/` are
Spanish.

**Prose quality:** a skill file is prose a person reads. Run
[`humanizing-text`](../humanizing-text/SKILL.md) over it before closing.

**The chain:** [`references/skill-chain.md`](../references/skill-chain.md).
