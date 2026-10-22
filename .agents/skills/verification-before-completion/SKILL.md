---
name: verification-before-completion
description: >
  Use before claiming any work is complete, fixed or passing, and before writing the commit
  guide. Runs the verification commands, shows the edge-case analysis and checks what an install
  that updates from the previous version sees. Evidence before assertions, always.
---

# Verification Before Completion

## Overview

Claiming work is complete without verification is dishonesty, not efficiency.

**Core principle:** evidence before claims, always.

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If the command did not run in this message, the claim cannot be made.

## When to Use

- About to say done, fixed, working, passing, ready or green.
- About to write the commit guide.
- Ending a session, whatever state the work is in.

## Process

### 1. Run the gate

```
BEFORE claiming any status:

1. IDENTIFY: which command proves this claim?
2. RUN:      execute it in full, fresh
3. READ:     the whole output, the exit code, the failure count
4. VERIFY:   does the output confirm the claim?
             → No:  state the actual status, with the evidence
             → Yes: state the claim, with the evidence attached
5. ONLY THEN: make the claim
```

Which command proves which claim is in [`references/verification-gates.md`](../references/verification-gates.md).

### 2. Run the checks

```bash
bash tests/lint.sh
bash tests/run.sh
```

Paste each result, the summary line and the exit code. A new shellcheck warning counts as a failure.

### 3. Show the edge-case analysis

The checks prove the code runs. They say nothing about the paths nobody thought of, and that is the half
a closing task drops most often.

Before the claim, produce the list: the cron with no terminal and a short `PATH`, no network, an agent not
installed or signed out, two sends in the same minute, a narrow terminal, a config edited by hand, an empty
or odd answer from an agent, an install from the previous version updating to this one. Then say, for every
case, which of the two happened:

- **Tested**, naming the scenario.
- **Analysed and discarded**, with the reason, recorded in the spec, section 4.

A case on neither side is a hole.

### 4. Check what an update does

Every install follows `main`. For a change to anything an install keeps (the crontab, `config.sh`, a log, the
token, the path a cron line calls), start from the previous version, update the way that version updates, and
say what it sees after. The scenario that proves it lives in `tests/`.

### 5. Check it with a real agent, when it needs one

The terminal scenarios run in a clean Ubuntu with stand-in agents. When the change depends on what a real agent
answers, the developer runs `keepalive test` on a machine they chose and says what it answered. Never on
someone else's server.

## Rationalizations

| Excuse                                  | Reality                                                    |
| --------------------------------------- | ---------------------------------------------------------- |
| "Should work now"                       | Run the verification                                       |
| "I'm confident"                         | Confidence is not evidence                                 |
| "The tests passed earlier"              | Earlier is not this message. Run them again                |
| "It works in my terminal"               | The cron has no terminal and a short `PATH`. Test that one |
| "Nobody runs the old version anymore"   | Every install updates from wherever it is. Test the jump   |
| "The stand-in agents are enough"        | They answer what we told them. A real one may not          |

## Red Flags

- "Done", "fixed" or "ready" with no command output in the same message.
- A check skipped because it "takes too long".
- The edge-case list missing, or a case on it with no verdict.
- A change to what an install keeps, with no word on what an update from the previous version does.

## Verification

- Every command in step 2, with its output, in this message.
- The edge-case list with a verdict for every case.
- What an install from the previous version sees after updating, when the change touches what it keeps.
- What a real agent answered, when the change needed one.

## Project Context

**Commands:** `AGENTS.md` → "Verification Commands". **Done:** `AGENTS.md` → "Definition Of Done".

**A merge is a release.** Every install picks up `main` with its next update, so the claim covers the update
too.
