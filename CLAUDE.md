@AGENTS.md

# agent-keepalive — Skill Protocol

> This file is loaded automatically by Claude Code at session start.
> Project rules and key paths are imported above from `AGENTS.md`.

## Mandatory: Read the applicable skill before acting

Skills live in `.agents/skills/<name>/SKILL.md`. Read them with the `Read` tool.
**If there is even a 1% chance a skill applies, read it first, before any action, including before asking
clarifying questions.**

| Situation                                              | Read this file                                                                |
| ------------------------------------------------------ | ----------------------------------------------------------------------------- |
| New feature, contribution, or behavior change          | `.agents/skills/brainstorming/SKILL.md`                                       |
| A structural decision with real alternatives weighed   | `CONTRIBUTING.md` → «Decisiones de arquitectura (ADR)»; propose it unprompted |
| Any bug, error, or unexpected behavior                 | `.agents/skills/systematic-debugging/SKILL.md`                                |
| Writing implementation code                            | `.agents/skills/test-driven-development/SKILL.md`                             |
| Writing prose: docs, a spec, an ADR, a screen          | `.agents/skills/humanizing-text/SKILL.md`                                     |
| Spec is approved, ready to implement                   | `.agents/skills/executing-plans/SKILL.md`                                     |
| About to claim work done                               | `.agents/skills/verification-before-completion/SKILL.md`                      |
| Generating the commit guide                            | `.agents/skills/finishing-a-development-branch/SKILL.md`                      |
| Creating or editing a skill file                       | `.agents/skills/writing-skills/SKILL.md`                                      |
| Anything about bash, cron or a screen                  | `AGENTS.md` → "Code Quality", then the scripts themselves                     |

### Red flags — stop and read the skill first

| Thought                               | Reality                                            |
| ------------------------------------- | -------------------------------------------------- |
| "This is too simple for a skill"      | Check anyway. Simple tasks have applicable skills. |
| "I remember what the skill says"      | Skills evolve. Read the current file.              |
| "Let me start and check skills later" | Skills tell you HOW to start. Read first.          |
| "I need more context first"           | Skills tell you HOW to gather context.             |

### Before any non-trivial action

See **AGENTS.md → Agent Challenge Discipline**. Before editing multiple files, changing behavior, running
commands with side effects, or making a design decision, confirm you can state _what / how / why_.

### Skill priority

1. **Process skills first** (`brainstorming`, `systematic-debugging`, `test-driven-development`).
2. **The rules of `AGENTS.md` second.** They say how this repository does each thing.

`humanizing-text` is cross-cutting: it runs inside whichever phase produced the text. The canonical order
of the whole chain is in `.agents/skills/references/skill-chain.md`, and the evidence each phase owes is in
`.agents/skills/references/verification-gates.md`.

## Writing style

**Em dash (—):** sparingly, only for a genuine parenthetical break. Never as a generic separator in lists
or table cells.

**Colon (:):** never inside a sentence. A comma, a period or a rewritten clause takes its place. Markdown
scaffolding is exempt (a label opening a line or list item, a heading, the line before a list or code
block), and so is syntax that requires it, such as a Conventional Commit subject, YAML or code. In Spanish
text the word after a colon starts uppercase.

**Lists:** tight bullets with one-line items. If an item needs explanation, give it a follow-up sentence.

**Responses:** in Spanish, matched to the task. Do not restate what the developer already said.

**Edits state the destination:** write the new value clean, as if it had always been so. The why goes in
chat, never in the file.
