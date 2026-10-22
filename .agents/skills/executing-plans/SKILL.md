---
name: executing-plans
description: >
  Use when you have an approved spec+plan to execute.
  Loads the spec from docs/specs/features/, verifies it is approved, executes
  implementation tasks one at a time, and verifies each step before proceeding.
  Documents any plan deviation in the spec's Change Log section.
---

# Executing Plans

## Overview

Load the spec, confirm it is approved, execute every task, report when it is done.

**Core principle:** evidence of approval before touching code. Evidence of passing before
marking anything complete.

**Announce at start:** "I'm using the executing-plans skill to implement this spec."

## When to Use

- A spec at `docs/specs/features/{number}-{slug}.md` carries `status: approved`.
- Work resumes on a spec already at `in-progress`.

Not when the spec says `draft`. Not for work with no spec, which goes back to
`brainstorming`.

## The Process

### Step 1: Load and confirm approval

1. Read the spec file.
2. Check the frontmatter. `status` must be `approved`. If it says `draft`, stop and tell the developer to approve it.
3. Review the Implementation Plan critically. Raise questions before starting, not halfway.
4. No concerns: set `status: in-progress` and proceed.

Read the spec's Change Log before re-reading the repository. A previous session may already
have hit the dead end you are about to walk into.

### Step 2: Execute the tasks

For each task in the Implementation Plan:

1. Mark it in progress and check off sub-steps as they land.
2. Follow each step as written. No improvisation.
3. Run every verification command the step specifies.
4. Mark it complete only after the output confirms it.

Writing implementation code opens
[`test-driven-development`](../test-driven-development/SKILL.md): the failing proof comes
first. A failure of any kind opens
[`systematic-debugging`](../systematic-debugging/SKILL.md) before any fix.

### Step 3: Handle deviations

When implementation needs a meaningful departure from the spec:

1. **Stop before deviating.**
2. Write it into the spec's **Change Log**:

   | Date       | Section        | What changed       | Reason                         |
   | ---------- | -------------- | ------------------ | ------------------------------ |
   | YYYY-MM-DD | Task N, Step X | [what you changed] | [why the plan needed updating] |

3. Tell the developer and confirm before continuing.

A dead end goes to memory as well as to the Change Log, with what was tried, why it failed
and what not to retry.

### Step 4: Complete

1. Set `status: done` in the frontmatter.
2. Move to [`finishing-a-development-branch`](../finishing-a-development-branch/SKILL.md).

## When to Stop and Ask

- `status` is not `approved`.
- A required dependency is missing.
- A verification step fails and the root cause is unclear.
- An instruction is ambiguous, or contradicts another.
- A non-trivial action comes up that the spec does not cover. Confirm the what/how/why first. See `AGENTS.md` → Agent Challenge Discipline.
- Two or more fixes for the same problem have failed.
- The implementation clearly has to deviate. Document, then ask.

Ask. Never guess through a blocker.

## Rationalizations

| Excuse                                        | Reality                                                                      |
| --------------------------------------------- | ---------------------------------------------------------------------------- |
| "The dev approved it in chat"                 | Approval is `status: approved` in the frontmatter. Nowhere else              |
| "This step will obviously pass"               | Then the command costs nothing. Run it                                       |
| "Small deviation, not worth the Change Log"   | The Change Log is how the next session learns the plan moved                 |
| "I'll batch the verifications at the end"     | A failure at step 9 then has nine candidate causes                           |
| "The spec is wrong here, I'll fix it as I go" | Stop, write the deviation, ask. Silent fixes are how a spec stops being true |
| "Two fixes failed, the third will work"       | Three failures means the architecture is the problem                         |

## Red Flags

- Implementation started while `status` is `draft`.
- A verification skipped because "it should pass".
- Several fixes applied before any verification runs.
- A task marked complete before its output confirmed it.
- A deviation not written to the Change Log.
- Work started directly on `main` instead of a branch.

## Verification

Per task, the verification command the step names, with its output.

Before handing off:

```bash
bash tests/lint.sh   # every script parses, no shellcheck error, no new warning
bash tests/run.sh    # every terminal scenario passes, in Docker
```

Also confirm every task is checked off, every deviation is in the Change Log, and the
frontmatter reads `status: done`. Contract:
[`references/verification-gates.md`](../references/verification-gates.md).

## Project Context

**Commands:** `AGENTS.md` → "Verification Commands".

**Rules that bite here:** every install follows `main`, so a merged change reaches everyone at once; an install
from before keeps sending after it updates; Spanish only, with plain punctuation on screen; no secret in the
output or the logs. See `AGENTS.md` → "Non-Negotiable Rules".

**Before handing off:**

```bash
bash tests/lint.sh   # every script parses, no shellcheck error, no new warning
bash tests/run.sh    # every terminal scenario passes, in Docker
```

Plus `keepalive test` on a machine the developer chose, when the change touches the sends, the logins or the
schedule.
