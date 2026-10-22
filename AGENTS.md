# agent-keepalive

Opens the usage window of AI coding agents (Claude Code, Codex and OpenCode) at the hours the person picks: a
cron sends each agent a short message, up to three times a day, and logs how it went. Plain bash on Ubuntu or
Debian, with cron, and no daemons. The repository is `JDCloud-Ecosystem/agent-keepalive` on GitHub,
public.

---

## Non-Negotiable Rules

| #   | Rule                                                                                                                        |
| --- | --------------------------------------------------------------------------------------------------------------------------- |
| 1   | **NO COMMITS**; never `git add`, `git commit`, `git tag`, `git merge` or `git push`. The developer runs the commit guide.   |
| 2   | **`main` always works.** Every install follows it with `keepalive update` (`git pull --ff-only`), so a merge is a release. |
| 3   | **LF line endings.** `.gitattributes` enforces them; a script saved with CRLF breaks on Linux.                              |
| 4   | **Spanish only.** Every string a person sees is Spanish, and there is no language to pick.                                  |
| 5   | **No secrets in output.** Never print a token, `.claude-token` or a login screen's code; log the account and the result.   |
| 6   | **Never touch a real install while testing.** `test.sh` runs on a machine the developer chose, never on someone's server.   |
| 7   | **pnpm only**, and only for the commit checks. The tool itself never needs Node to run its scripts.                         |

---

## Agent Challenge Discipline

Before any non-trivial action (editing 2+ files, changing behavior, running a command with side effects, a
design decision), be able to state **what** you will do, **how** and **why**. If you cannot, stop and ask. When
the request is ambiguous, name what is unclear and propose the most likely reading so the developer can confirm
it in one reply. Correct mistakes directly and always with the technical why.

---

## Key Paths

| File                 | What it is                                                         |
| -------------------- | ------------------------------------------------------------------ |
| `keepalive`          | The command and its menu; `install.sh` links it into `~/.local/bin` |
| `lib.sh`             | What the scripts share: agents, accounts, the cron and the screens |
| `session-starter.sh` | What the cron runs, one send per agent                             |
| `login.sh`           | Connects Claude for a year                                         |
| `install.sh`         | Installs what is missing and registers the cron                    |
| `update-schedule.sh` | The schedule and agents screen                                     |
| `terminal-rc.sh`     | Startup file of the menu's terminal, where `menu` goes back        |
| `test.sh`            | The full live test, on a real machine                              |
| `uninstall.sh`       | Removes everything                                                 |
| `version.txt`        | The version; Release Please writes it                              |

---

## Verification Commands

```bash
for s in ./*.sh keepalive; do bash -n "$s"; done   # every script parses
shellcheck -x --severity=error ./*.sh keepalive     # what CI runs
keepalive test                                      # the live test, on a machine the developer chose
```

CI (`.github/workflows/ci.yml`) runs the first two on every pull request and on `main`. Warnings stay visible
with `shellcheck -x ./*.sh keepalive`; a change does not add new ones.

---

## Git Flow

```
main                          trunk; what every install pulls with keepalive update
feature/{english-slug}        feat commits, off main
fix/{english-slug}            fix commits, off main
refactor/{english-slug}       refactor commits, off main
chore/{english-slug}          chore and ci commits, off main
docs/{english-slug}           docs commits, off main
```

1. Create the branch off `main`.
2. Make the change and run the verification commands.
3. Write `tmp/{english-slug}/commit-guide.md` and `tmp/{english-slug}/pr-body.md`, when the developer asks.
4. The developer commits, pushes the branch and opens the pull request.
5. The developer merges it with **Squash and merge**, the only button enabled. The pull request title becomes
   the one commit on `main` and its line in `CHANGELOG.md`.
6. Release Please opens or updates the release PR. Merging it tags `v<version>` and publishes the release. The
   whole process is in `docs/RELEASE.md`.

**Commit messages and pull request titles** follow [Conventional Commits](https://www.conventionalcommits.org/),
in English:

```
<type>(<scope>): <description>    # max 100 chars; scope is REQUIRED
```

Types: `feat`, `fix`, `refactor`, `style`, `docs`, `test`, `chore`, `ci`. The scope names the area, in lower
case, such as `install`, `login`, `logout`, `schedule`, `status`, `cron`, `lib`, `docs`, `release`, `workflows`,
`conventions` or `deps`. commitlint and Husky check each commit once `pnpm install` has run, and
`pr-title-check.yml` checks the pull request title. A `feat` or `fix` title is read by whoever updates, so write
it for that person.

The commit guide is one title line and one `bash` block with no headings, prose or comments: the branch, every
`git add <paths> && git commit -m "…"`, the push and `gh pr create`. Whoever runs it may be on Windows, macOS or
Linux, in any terminal, so it holds plain `git` and `gh` and nothing else, never `$(…)`, pipes, `cp`, `sed` or
`sha256sum`. Work prepared off `main` ships as `tmp/{english-slug}/changes.patch`, applied with `git apply`.
`git add` names paths, never `-A` or `.`. It never changes the version or tags.

---

## Docs

- **Spanish prose, English file names.** `README.md`, `CONTRIBUTING.md` and `docs/` are Spanish. `AGENTS.md` and
  `CLAUDE.md` stay English because they are protocol files for agents.
- **Edits state the destination.** Write the new state as if authored from scratch; the reason for a change goes
  in the pull request, never in the file.

---

## Code Quality

- **KISS and YAGNI.** The simplest bash that works; nothing for a hypothetical future.
- **Root cause first.** A symptom fix is a failure.
- **Match the scripts.** `set -uo pipefail` in the scripts a person runs, section headers as `# ── Name ──…`,
  functions in `lib.sh` when two scripts need them.
- **One look for every screen.** The `ui_` functions of `lib.sh` draw them all. The title goes in capitals between
  two rules, options are numbered under small headings and lists are tables (`ui_table`). An option nothing else
  starts with is taken with one key, with no Enter (`ui_choose`), and `0` goes back from every screen. Tags are
  coloured text, never a background. No whiptail.
- **Plain Spanish on screen.** No colon or semicolon inside a sentence, no em dash, no ellipsis; a comma, a
  period or parentheses take their place.
- **Comments in English**, only for a non-obvious why. Never narrate the change, never commented-out code.
- **No magic numbers.** Name the constant.
