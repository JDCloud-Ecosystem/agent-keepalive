---
name: systematic-debugging
description: >
  Use when encountering any bug, test failure, build error, or unexpected behavior.
  MUST be used before proposing any fix. Random fixes waste time and create new bugs.
---

# Systematic Debugging

## Overview

Random fixes waste time and create new bugs. A quick patch hides the mechanism that
produced the failure, and the mechanism comes back.

**Core principle:** always find the root cause before attempting a fix. A symptom fix is a
failure, not a correction.

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

Phase 1 incomplete means no fix may be proposed.

## When to Use

- Any bug, crash or wrong output.
- A build error, a lint failure, a failing test.
- A command that behaved differently from what its documentation says.
- A behavior that surprised you, even if nothing is technically broken.
- CI red on something that passed locally.

## The Process

Four phases. Each one completes before the next begins.

### Phase 1: Root cause investigation

1. **Read the error carefully.** The full stack trace, line numbers, file paths, exit code.
2. **Reproduce it consistently.** If it is not reliable yet, gather more data before theorising.
3. **Check recent changes.** `git diff`, recent commits, new dependencies, config edits.
4. **Instrument the boundaries** in a multi-component path, logging what enters and what leaves each component before proposing anything.
5. **Trace the data flow.** Where does the bad value first appear? Technique: [`references/root-cause-tracing.md`](references/root-cause-tracing.md).

Read the spec's Change Log and `AGENTS.md` → "About agent-keepalive" first. A root cause found
once is written down there, and the dead ends with it.

### Phase 2: Pattern analysis

1. Find working examples of similar code in the repository.
2. Read the reference implementation completely. Never skim it.
3. List every difference between the working case and the broken one, however small.
4. Understand every dependency the broken code carries.

### Phase 3: Hypothesis and testing

1. State one hypothesis: "X is the root cause, because Y."
2. Make the smallest change that tests it.
3. One variable at a time. Never stack changes.
4. Wrong hypothesis: form a new one. Do not pile a second fix on the first.

### Phase 4: Implementation

1. Create a failing verification before fixing, whether that is lint, build or the manual reproduction.
2. Implement one fix, aimed at the root cause.
3. Confirm it resolves the issue and breaks nothing else.
4. **After three failed fixes,** stop and question the architecture. Do not attempt a fourth without talking to the developer.

Once the cause is confirmed, save it, along with the evidence that settled it and what not
to retry.

## Rationalizations

| Excuse                                      | Reality                                                      |
| ------------------------------------------- | ------------------------------------------------------------ |
| "Quick fix now, investigate later"          | Later never comes. Return to Phase 1                         |
| "Just try changing X and see"               | That is guessing with extra steps. Return to Phase 1         |
| "It's probably X"                           | Probably is not a root cause. Verify before claiming         |
| "One more fix attempt" (after two failed)   | Question the architecture instead                            |
| "I'll skip the repro, I understand the bug" | Then you cannot tell whether the fix worked                  |
| "The error message is obvious"              | The message names the symptom. The cause is usually upstream |
| "It works now, no need to know why"         | A fix you cannot explain will be undone by the next change   |
| "This one is too small to investigate"      | Small bugs sit on the same mechanisms as large ones          |

## Red Flags

- A fix proposed before the reproduction was established.
- Several changes applied at once, then tested together.
- The words "probably", "should be" or "I think" carrying the diagnosis.
- A fourth fix attempt on the same symptom.
- A workaround added while the cause stays unknown.
- The failing behavior gone, with no explanation of why.

## Verification

The phase closes on four things:

- The root cause, stated in one sentence, with the evidence that confirmed it.
- The reproduction failing, from before the fix.
- The same reproduction passing, after.
- `bash tests/lint.sh` and `bash tests/run.sh` at exit 0, proving nothing else broke.

For a fix with no automated proof, name the exact manual steps and what was observed at
each one. Contract:
[`references/verification-gates.md`](../references/verification-gates.md).

## Project Context

**Commands:** `AGENTS.md` → "Verification Commands".

**Rules that bite here:** every install follows `main`, so a fix also has to reach an install that updates from
the previous version; the cron runs with no terminal and a short `PATH`; no token in the output or the logs.
See `AGENTS.md` → "Non-Negotiable Rules".

**Where failures show:**

- `bash tests/lint.sh`: a script that does not parse, a quote missing, a variable used before it is set
- `bash tests/run.sh`: a screen, a key, a command, the crontab or a file that came out wrong
- The agent's log (`sessions.log`, `codex-sessions.log`, `<agent>-sessions.log`): every send ends in `OK`,
  `LIMIT` or an `ERROR` that names the command to run
- `crontab -l`: the lines `keepalive` writes, one per session and agent
- `keepalive test`, on a machine the developer chose: what a real agent answers
