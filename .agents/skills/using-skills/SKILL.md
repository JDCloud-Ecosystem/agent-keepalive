---
name: using-skills
description: >
  Use at the start of any session or when unsure which skill applies to the current task.
  Explains how to discover, read and invoke skills from .agents/skills/, and when
  to check for an applicable skill before taking any action.
---

# Using Skills

## Overview

Skills are process guides in `.agents/skills/`. They say HOW to approach a task, and they
close each phase on evidence rather than on a claim.

**Core principle:** check for an applicable skill BEFORE any significant action. A 1%
chance one applies is enough to check.

## When to Use

At the start of every session, and any time the applicable skill is not obvious.

Before any of these, open the skill named next to it:

- Starting a new feature or task → `brainstorming`
- Implementing an approved spec → `executing-plans`
- Encountering a bug or failure → `systematic-debugging`
- Writing implementation code → `test-driven-development`
- Writing prose or user-visible copy → `humanizing-text`
- About to say "done", or about to push → `verification-before-completion`
- Handing over the commit guide → `finishing-a-development-branch`
- Creating or editing a skill → `writing-skills`

The full chain and one trigger per skill: [`references/skill-chain.md`](../references/skill-chain.md).

## Process

### 1. Read what the repository already knows

Before re-reading the code, read `AGENTS.md` → "About agent-keepalive" and the spec in progress,
with its Change Log. Prior sessions already paid for the root causes and the dead ends there.

### 2. Find the skill

```bash
ls .agents/skills/
```

Each `SKILL.md` carries a `description` in its frontmatter that states when it applies.
Read that field.

### 3. Read it, then act

Read the `SKILL.md` and follow its process. Claude Code invokes it by name; other CLIs
read `.agents/skills/<name>/SKILL.md` directly.

### 4. Apply the priority order

When more than one skill fits:

1. **Process skills first:** `brainstorming`, `systematic-debugging`, `test-driven-development`. They decide how the task is approached.
2. **Implementation guidance second:** the rules of `AGENTS.md` and the Bash manual. They guide execution.

`humanizing-text` is cross-cutting and runs inside whichever phase produced the text.

## Rationalizations

| Excuse                                     | Reality                                          |
| ------------------------------------------ | ------------------------------------------------ |
| "This is simple, no skill needed"          | Check anyway. Simple tasks have skills too       |
| "I remember what the skill says"           | Skills evolve. Read the current version          |
| "Let me just start and check skills later" | Skills tell you HOW to start. Check first        |
| "I need more context first"                | Skills tell you HOW to gather context            |
| "No time to recall memory"                 | Re-deriving what a past session found costs more |

## Red Flags

- Files edited before any skill was opened.
- A phase declared done with no evidence attached.
- The repository re-indexed without a memory recall first.
- A skill quoted from memory instead of read.

## Verification

- The applicable skill was read in this session, not recalled.
- Project memory was recalled before the repository was indexed.
- Each phase closed with the evidence its skill asks for. Contract:
  [`references/verification-gates.md`](../references/verification-gates.md).

## Project Context

**Where things are:** `AGENTS.md` → "Key Paths". Specs in `docs/specs/features/`, decisions in `docs/adr/`,
the terminal tests in `tests/`.

**Commands:** `AGENTS.md` → "Verification Commands".

**Rules that bite here:** `main` always works because every install pulls it, LF line endings, Spanish only and
plain punctuation on every screen, no secrets in the output, and never a real install while testing. See
`AGENTS.md` → "Non-Negotiable Rules".

**No shared memory store.** What a session learns that the code does not say goes in `AGENTS.md` →
"About agent-keepalive", in the spec's Change Log, or in an ADR.
