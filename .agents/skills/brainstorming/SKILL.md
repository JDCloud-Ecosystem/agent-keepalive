---
name: brainstorming
description: >
  Use before any new feature, component, behavior change or creative work.
  Explores user intent, requirements and design before any implementation begins.
  MUST be used before writing code, modifying existing behavior, or entering plan mode.
  Produces a single spec+plan file that also serves as the implementation guide.
---

# Brainstorming Ideas Into Specs

## Overview

Turn an idea into a spec through dialogue. Understand the context, ask one question at a
time, present the design, then write the file the developer approves before any code
exists.

**Core principle:** the spec is the plan. One file per feature, and it is what the
implementation follows.

<HARD-GATE>
Do NOT write any code, scaffold anything, or take any implementation action until
the spec file has `status: approved` set by the developer. This applies to every
request regardless of perceived simplicity.
</HARD-GATE>

## When to Use

- A new feature, component or behavior change is requested.
- An existing behavior is going to change in a way a user would notice.
- The developer describes a problem and expects work to follow.
- Before entering plan mode on anything.

Not for a mechanical fix already covered by an approved spec, and not for answering a
question about the codebase.

## Checklist

In order:

1. **Explore project context:** read the relevant files, docs and recent commits
2. **Ask clarifying questions:** one at a time; purpose, constraints, success criteria
3. **Propose 2-3 approaches:** with trade-offs and a recommendation
4. **Present the design:** section by section, confirming after each
5. **Write the spec+plan:** `docs/specs/features/{number}-{slug}.md`, from the template
6. **Self-review:** TBD, contradictions, ambiguity, scope; fix inline
7. **Request approval:** the developer sets `status: approved` in the frontmatter
8. **Transition:** after approval, use `executing-plans`

## The Process

### Understanding the idea

- If the request is vague, contradictory or missing its _why_, push back before spending questions on details. The what/how/why gate applies here too. See `AGENTS.md` → Agent Challenge Discipline.
- Check the current state first, meaning files, docs and recent commits.
- Confirm the GitHub issue number and a short English slug. They become the spec filename and the branch name.
  Without an issue, open one first with the Vertical Slice template (`docs/GITHUB-WORKFLOW.md`).
- Assess scope. A request covering several independent subsystems gets decomposed, one spec per subsystem.
- Ask one question at a time. Prefer multiple choice.
- Focus on purpose, constraints and success criteria.

### Exploring approaches

Propose two or three approaches with their trade-offs. Lead with the recommendation and
say why.

If the choice being made is structural, outlives its feature and had real alternatives, it
needs an ADR. Offer it in that same reply, unprompted. The three tests are in
`CONTRIBUTING.md` → «Decisiones de arquitectura (ADR)».

### Presenting the design

Section by section, asking after each whether it holds. Scale each section to its
complexity. Cover goal, non-goals, acceptance criteria, technical design, implementation
tasks and verification.

### Writing the spec+plan file

Copy `docs/specs/features/_TEMPLATE.md` to `docs/specs/features/{number}-{slug}.md`.

**Write the whole spec in Spanish.** The headings are already Spanish in the template;
the content, descriptions and task steps follow.

Fill every section. No TBD, no TODO, no placeholder step.

- **Goal and non-goals:** one sentence, plus the explicit exclusions.
- **Problem statement:** context and motivation.
- **Acceptance criteria:** testable Given/When/Then conditions.
- **Technical design:** affected files, edge cases, contract changes.
- **Implementation plan:** granular tasks of two to five minutes, exact code, exact commands.
- **Verification:** lint, build and the manual steps.

Then run [`humanizing-text`](../humanizing-text/SKILL.md) over it. A spec is prose a person
reads before committing a week to it.

Self-review for TBD, contradictions and ambiguity, and fix inline. Then tell the developer:

> "Spec saved to `docs/specs/features/{number}-{slug}.md`. Review it and change
> `status: draft` to `status: approved` in the frontmatter to approve."

Wait. Do not touch code.

### After approval

Load the spec and execute its Implementation Plan with `executing-plans`.

## Key Principles

- **One question at a time.** Never several in one message.
- **YAGNI ruthlessly.** Remove unnecessary features from every design.
- **Explore alternatives.** Two or three approaches before settling.
- **Incremental validation.** Confirm each section before moving on.
- **Spec is plan.** There is no second document.

## Rationalizations

| Excuse                                | Reality                                                                           |
| ------------------------------------- | --------------------------------------------------------------------------------- |
| "This is simple, skip the spec"       | Simple things grow. Every feature gets a spec                                     |
| "I need more context first"           | The clarifying questions are the context. Start them                              |
| "Let me just explore the code"        | The checklist says how to explore. Run it                                         |
| "I already know what to build"        | User intent and your assumption diverge more often than not                       |
| "The developer said OK in chat"       | OK in chat is not `status: approved` in the file                                  |
| "The request is clear enough to spec" | If the why or the success criterion is missing, push back first                   |
| "Three approaches is overkill here"   | Then the second one takes a line. Writing it is what surfaces the trade-off       |
| "The design is obvious, write it all" | Section by section catches the wrong turn on section two instead of section eight |

## Red Flags

- Code written, or files scaffolded, while the spec says `draft`.
- A spec with TBD, TODO, or a step that says "similar to task 1".
- Several questions in one message.
- One spec covering two independent subsystems.
- A design presented whole, with no confirmation between sections.
- A structural decision with real alternatives buried in the spec instead of an ADR.

## Verification

Before asking for approval:

- The file exists at `docs/specs/features/{number}-{slug}.md` and follows the template.
- Every section is filled. No TBD, no TODO, no placeholder.
- The acceptance criteria are testable, not aspirations.
- Each implementation step names its files and its verification command.
- The slug and the number match the branch name and the issue.
- `humanizing-text` ran over the prose, both passes.

Every relative link in the spec opens the file it names.

No code exists yet. That is the evidence that the gate held.

## Project Context

**Stack:** plain bash on Ubuntu and Debian, with cron and git. No daemons, and Node only for the commit checks.

**Specs:** `docs/specs/features/{N}-{english-slug}.md`, in Spanish, from `_TEMPLATE.md`. `{N}` is the number
of the spec's issue; the branch is `feature/{N}-{english-slug}`.

**Commands:** `AGENTS.md` → "Verification Commands".

**Rules that bite here:** every install follows `main`, so a merged change reaches everyone at once; Spanish only,
with plain punctuation on screen; no secret in the output or the logs. See `AGENTS.md` → "Non-Negotiable Rules".

**Design questions that always apply:** which screen or command shows it and how it looks in the shared style,
what an install from before needs so it keeps sending (its cron, its config, its logs), whether it needs the
network and what happens without it, and whether it runs from cron, where there is no terminal.
