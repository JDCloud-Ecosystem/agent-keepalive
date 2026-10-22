---
name: finishing-a-development-branch
description: >
  Use when the work for an issue is done and verified and its pull request is next, and for every change
  that lands after that pull request is open. Detects whether the branch already has a pull request, then
  either writes the commit guide and the pull request body or hands the developer a single commit line in
  chat. The agent never runs git add, git commit or git push.
---

# Finishing a Development Branch

## Overview

The developer commits; the agent never does. What the agent owes depends on the phase. Before the pull request
exists, a guide the developer can run top to bottom without thinking about what goes where, and the body of the
pull request it opens. After it exists, one commit line in chat.

**Core principle:** every changed file lands in exactly one commit, or is named as left out on purpose.
**Core principle:** no pull request without evidence that the checks are green.

## When to Use

- The spec's tasks are checked off and `verification-before-completion` passed in this session.
- A change lands on a branch whose pull request is already open, such as a review fix.
- The developer asks for the commit guide, the pull request body or a commit message, or accepts the offer.

Not before the checks are green, and never on the agent's own initiative. Not for merging; the developer merges.

## Process

### 1. Detect the phase

```bash
gh pr view --json number,state,url 2>/dev/null
```

| Result                 | Phase   | What the developer gets              |
| ---------------------- | ------- | ------------------------------------ |
| Empty output, exit 1   | Pre-PR  | The guide and the body, steps 2 to 7 |
| The PR as JSON, exit 0 | Post-PR | One commit line in chat, step 8      |

Run it on the issue's branch, or with the branch name as its argument. The agent decides the phase itself; it
never asks which one it is.

### 2. Verify

Run the checks from `AGENTS.md` → "Verification Commands" and show their output. Any failure stops here and goes
to `systematic-debugging`. Set the spec to `status: done` in this same pull request.

### 3. Read the state

```bash
git status --short
```

Every changed and untracked file has to land in exactly one commit, or be named to the developer as left out on
purpose. A file that two open issues both change belongs to the first guide; the second one ships its part as
`tmp/{N}/changes.patch`, applied with `git apply` right after its branch is created.

### 4. Group the changes

One commit per reason to change, in the order a reader would follow: the code with its tests first, then the
docs that describe it, then the tooling. A doc edit that only follows a code change goes with that code. The spec
goes in its own `docs(specs)` commit.

### 5. Write each message

- `<type>(<scope>): <description>`, in English, imperative, at most 100 characters.
- Types and scopes from `AGENTS.md` → "Git Flow". The scope is required.
- Subject only, no body, no footer, no AI attribution.
- The pull request title follows the same rules, and with Squash and merge it is the one commit `main` keeps. A
  `feat` or `fix` title becomes a line of `CHANGELOG.md` and of the release notes, which whoever updates reads,
  so write it for that person.

### 6. Write `tmp/{N}/commit-guide.md`

One title line and one `bash` block holding the whole guide: the branch, every `git add … && git commit`, the
push and `gh pr create`. No headings, no prose and no comments inside the block. The explanation of each commit
goes in chat, and only when the developer asks.

Whoever runs it may be on Windows, macOS or Linux, in any terminal, so the block holds plain `git` and `gh` and
nothing else: no `$(…)` or `<(…)`, no pipes, no `cp`, `sed`, `cut` or `sha256sum`. The guide never changes the
version, tags or creates a release; Release Please does.

````markdown
# Commit guide — #21

```bash
git switch main
git pull --ff-only
git switch -c feature/21-pause-for-a-day

git apply tmp/21/changes.patch

git add keepalive tests/drive.py && git commit -m "feat(menu): pause every send for one day from the menu"

git add README.md && git commit -m "docs(readme): explain how to pause the sends for a day"

git add docs/specs/features/21-pause-for-a-day.md && git commit -m "docs(specs): add spec 21, a pause for one day"

git push -u origin feature/21-pause-for-a-day

gh pr create --base main --title "feat(menu): pause every send for one day from the menu" --body-file tmp/21/pr-body.md
```
````

`git add` names paths, never `-A` or `.`, so nothing unplanned slips in. A new script that has to be executable
gets `git update-index --chmod=+x <paths>` right after its `git add`, in the same line, because on Windows
`git apply` cannot set the mark and `git add` would commit the script without it. A script already executable in
the repository keeps its mark.

### 7. Write `tmp/{N}/pr-body.md`

The suggested title and the body, nothing else, filled from `.github/PULL_REQUEST_TEMPLATE.md` in Spanish.

- The title goes on the first line as an HTML comment, so the file passes whole to `--body-file` and the title
  stays invisible in the rendered pull request.
- `Closes #{N}` under the summary.
- Name the commands, screens, scripts or files of an install it touches.
- Fill every section, and mark a Definition of Done item that does not apply as N/A with its reason.
- Screens: the ones that change, as text copied from the terminal scenarios, in order. Without anything on
  screen, `N/A, sin cambios en pantalla`.

```markdown
<!-- Título: feat(menu): pause every send for one day from the menu -->

## Resumen

[El cuerpo completo, siguiendo `.github/PULL_REQUEST_TEMPLATE.md`.]
```

Run `humanizing-text` over the body before handing it over. A person reads it, and it stays in the history.

Then hand both over in chat. Say where the files are, which version Release Please will propose (`feat` raises
the minor, `fix` the patch, the rest none), and whether an install from the previous version needs anything by
hand after it updates.

### 8. After the pull request is open

**The files freeze.** `commit-guide.md` and `pr-body.md` stay as they are; they describe the branch when the pull
request opened.

**Every later change is one commit,** handed over in chat as a single line, however many areas it touches:

```bash
git add keepalive tests/drive.py && git commit -m "fix(menu): keep the pause when the menu opens again"
```

The push is the developer's next command and needs no line, since the upstream is already set. One commit per fix
is enough, because Squash and merge leaves one commit on `main` either way.

## Rationalizations

| Excuse                                                 | Reality                                                                 |
| ------------------------------------------------------ | ----------------------------------------------------------------------- |
| "One big commit is simpler"                            | One reason per commit is what makes the pull request readable           |
| "`git add -A` is fine, I checked"                      | Name the paths. An unplanned file is how a token gets committed         |
| "The developer can fix the message"                    | The message is part of the deliverable. Write it right                  |
| "A quick `cp` or `sed` in the guide"                   | It runs in every terminal or it does not belong there. Plain git and gh |
| "The guide is stale, better regenerate it"             | It froze on purpose. The new change is one commit line in chat          |
| "This fix touches three areas, it needs three commits" | After the pull request opens it is one commit; squash hides the split   |
| "I will just check with the developer about the phase" | `gh pr view` answers it                                                 |
| "I'll just commit it for them"                         | Rule 1. The agent never commits                                         |

## Red Flags

- A guide written before the checks ran in this session.
- A changed file in no commit and not named as left out.
- `git add -A`, `git add .`, or a commit with a body or an attribution footer.
- A message in Spanish, without a scope, or over 100 characters.
- A line in the guide that only runs in one shell, or a command other than `git` and `gh`.
- A pull request body without `Closes #{N}` or without its HTML comment title.
- `commit-guide.md` or `pr-body.md` edited after the pull request opened, or a second guide for later changes.
- A pull request aimed at anything but `main`.

## Verification

- The output of the checks, from this session.
- The `gh pr view` output that decided the phase.
- `git status --short` and the list of commits in the guide, with every file accounted for.
- The paths of `tmp/{N}/commit-guide.md` and `tmp/{N}/pr-body.md`, or, after the pull request opened, the one
  commit line.

## Project Context

**Git flow and commit format:** `AGENTS.md` → "Git Flow", and the whole flow in `docs/GITHUB-WORKFLOW.md`.
commitlint and Husky reject a commit that breaks the format, and `pr-title-check.yml` a pull request title.

**One issue, one branch, one pull request.** The repository is `JDCloud-Ecosystem/agent-keepalive`, public. The
guide pushes the branch and opens the pull request; CI runs the checks; the developer merges it with Squash and
merge, the only button the repository allows. From that moment every install gets the change with its next
update. Release Please then opens or updates the release PR, and merging that one tags `v<version>` and
publishes the release with its notes.

**`tmp/` is git-ignored**, one folder per issue with `issue-body.md`, `commit-guide.md`, `pr-body.md` and, when
needed, `changes.patch`. The developer deletes it once the pull request is merged.
