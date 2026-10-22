---
name: test-driven-development
description: >
  Use when implementing any feature or bugfix, before writing implementation code.
  Define the observable proof of behavior first. Watch it fail. Implement. Watch it pass.
---

# Test-Driven Development (TDD)

## Overview

Define how the feature will be proven to work before the feature exists.

**Core principle:** if you did not watch the verification fail, you do not know it tests
the right thing.

Violating the letter of the rules is violating the spirit of the rules.

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING VERIFICATION FIRST
```

## When to Use

**Always:**

- New features and components.
- Bug fixes.
- Behavior changes.
- Command changes.

The project has a suite of terminal scenarios in `tests/`. Where a real test fits, it is a real
test. Where it does not, "verification" is one of:

- `bash tests/lint.sh` catching a syntax error or a shellcheck error
- A function of `lib/` called from `bash -c` with fixed input, and its output compared
- `keepalive test` on a machine the developer chose, for what only a real agent answers

The discipline does not change with the medium. Define the failing proof, then implement.

## What Earns A Test

Two verbs, and they are not the same size. **Analysis is exhaustive, codification is
selective.** The full rule is in [`AGENTS.md`](../../../AGENTS.md) → "Tests That Earn Their
Place"; what it means while you are writing the code is this.

**Enumerate everything.** Boundary inputs, state combinations, the external service answering
failing or answering slowly, no network, no terminal (cron), two sends at the same minute, an install
from an older version, a config file written by hand, the setting nobody filled. Write the list down before deciding what to
codify. The list is the deliverable of the analysis, and it lands in the spec.

**Codify what a failure would cost.** A case becomes a file under `tests/` when its failure
stops the sends without anyone noticing, loses the person's schedule, history or token, leaks a secret,
breaks an install from before when it updates, or leaves a screen with no way back. Everything else goes to
the spec, section 4, as an analysed and discarded case with the reason it was discarded. A case
that is written down and not codified is a decision. A case nobody enumerated is a hole.

The target shape is a small, sharp set born of failures that actually happened, not a suite that
measures its worth in files.

## The Process

RED, GREEN, REFACTOR, with a mandatory look at the failure in between.

### RED: define the failing verification

Before any implementation code, define what will prove the feature works, and confirm that
proof currently fails or does not exist.

_A new command:_

```bash
# before implementation
keepalive changelog   # keepalive no tiene el comando changelog. Con keepalive help ves los que hay.
```

_A new screen:_

```
Before implementing, its scenario in tests/drive.py fails.
Verify: `bash tests/run.sh` reports «never saw 'QUÉ TRAE LA VERSIÓN NUEVA'».
```

_A bug fix:_

```
Before fixing, reproduce the exact behavior.
Write it down: "When X, Y happens. Expected: Z."
Confirm the reproduction is consistent before touching code.
```

### Verify RED: watch it fail

**Mandatory. Never skipped.**

Run it. Confirm two things, that it fails and that it fails for the expected reason. A verification
that passes immediately is testing something that already existed. Re-examine it.

### GREEN: minimal implementation

The simplest code that makes the verification pass. No extra features, no abstraction
beyond what the verification demands. If the verification does not require it, it is not
built.

### Verify GREEN: watch it pass

Run it again. The verification passes, and `bash tests/lint.sh` plus `bash tests/run.sh` confirm
nothing else broke.

### REFACTOR: clean up

Only after green. Remove duplication, improve names, extract a helper if one is genuinely
earned. Everything stays green, and no behavior is added during refactor.

## Rationalizations

| Excuse                          | Reality                                                             |
| ------------------------------- | ------------------------------------------------------------------- |
| "Too simple to verify"          | Simple code breaks. The verification takes two minutes              |
| "I'll verify after"             | A verification that passes on first run proves nothing              |
| "Already tested it manually"    | Ad hoc is not systematic. No record, no reproduction                |
| "TDD slows me down"             | Debugging without a verification is slower                          |
| "I know this works"             | Then watching it fail costs one command and settles it              |
| "Skip TDD just this once"       | The once is always the one that breaks                              |
| "The syntax check is enough"    | `bash -n` proves it parses, not that it behaves                     |
| "Better test it just in case"   | The case has a name or it has no test. Write the name in the spec   |
| "It is cheap to write"          | Writing it is the cheap half. It is read and rerun forever          |
| "This module has no test yet"   | Then name the failure that would cost something, and test that one  |
| "I enumerated it, so I test it" | Analysis is exhaustive, codification is selective. Two lists        |
| "Deleting it is someone's job"  | Removing a test is gated. Proposal file by file, then the developer |

## Red Flags

- Implementation written before the failing verification was defined.
- A verification that passed on its first run.
- "I'll verify manually later."
- "It's too simple to need verification."
- Behavior added during the refactor step.
- Green claimed without `tests/lint.sh` and `tests/run.sh` alongside.
- A new test that asserts a copy string, a static table, or a colour.
- Edge cases discussed in chat and never written down anywhere.

## Verification

The phase closes on three things, all of them visible:

- The verification failing, before implementation, for the expected reason.
- The same verification passing, after.
- The edge-case list, written, with each case either codified or marked analysed and discarded
  with its reason.

Then:

```bash
bash tests/lint.sh   # every script parses, no shellcheck error, no new warning
bash tests/run.sh    # every terminal scenario passes, in Docker
```

Contract: [`references/verification-gates.md`](../references/verification-gates.md).

## Project Context

**Commands:** `AGENTS.md` → "Verification Commands".

**Rules that bite here:** every install follows `main`, so a merged change reaches everyone at once; an install
from before keeps sending after it updates; Spanish only, with plain punctuation on screen; no secret in the
output or the logs. See `AGENTS.md` → "Non-Negotiable Rules".

**Tests:** `tests/drive.py` drives `keepalive` through a real terminal inside an Ubuntu container with stub
agents (`tests/setup.sh`), and checks what the screen shows and the files and crontab it leaves. A new scenario
is one `t_` function. Never against a real install.

**What a scenario always covers:** the screen's title and options, `0` going back, and what changed on disk.

**A secret on screen is a bug.** A scenario that touches a login checks that no token shows.
