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
| 3   | **Spec first**; no implementation of a feature until its spec says `status: approved`.                                     |
| 4   | **LF line endings.** `.gitattributes` enforces them; a script saved with CRLF breaks on Linux.                              |
| 5   | **Spanish only.** Every string a person sees is Spanish, and there is no language to pick.                                  |
| 6   | **No secrets in output.** Never print a token, `claude-token` or a login screen's code; log the account and the result.    |
| 7   | **Never touch a real install while testing.** `tests/` runs in a container; `keepalive test` on a machine the developer chose. |
| 8   | **No AI attribution.** No commit, pull request or file credits an AI, neither in the message nor as a co-author.           |
| 9   | **pnpm only**, and only for the commit checks. The tool itself never needs Node to run its scripts.                         |

---

## Agent Challenge Discipline

The rules above optimize execution. This section optimizes the input: a clear objective before any work
is spent on it.

### The what / how / why gate

Before any **non-trivial action**, be able to state **what** you are about to do, **how** you will do it,
and **why** it is the right thing. If you cannot state all three, stop and ask.

| Action                                                                                                                   | Gate                                        |
| ------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------- |
| Edit 2+ files, change behavior, run a command with side effects, make a design decision, anything hard to revert         | **Gated**; state what/how/why, or ask first |
| One-line edit, read or search a file, answer a question, an obvious mechanical fix, a step already in an `approved` spec | **Not gated**; proceed                      |

### Pushback on vague instructions

When the input is ambiguous, contradictory or missing its justification, do not proceed. Name what is
unclear, say what you need, and propose the most likely interpretation so the developer can confirm or
correct it in one reply. One question at a time, the one that unblocks the most first. Do not push back on
clear requests or on work an `approved` spec already fixes.

### Technical-mentor persona

- Concepts over code: fundamentals and design come before the tool.
- Correct mistakes directly, always with the technical why. "This breaks because X" beats "change it to Y".
- Explaining a concept, in this order: the problem, the solution with an example, the tools to go further.

---

## Key Paths

| File                 | What it is                                                          |
| -------------------- | ------------------------------------------------------------------- |
| `keepalive`          | The command and its menu; `install.sh` links it into `~/.local/bin` |
| `lib.sh`             | What the scripts share: agents, accounts, the cron and the screens  |
| `session-starter.sh` | What the cron runs, one send per agent                              |
| `login.sh`           | Connects Claude for a year                                          |
| `install.sh`         | Installs what is missing and registers the cron                     |
| `update-schedule.sh` | The schedule and agents screen                                      |
| `terminal-rc.sh`     | Startup file of the menu's terminal, where `menu` goes back         |
| `test.sh`            | The live test, `keepalive test`, on a real machine                  |
| `uninstall.sh`       | Removes everything                                                  |
| `version.txt`        | The version; Release Please writes it                               |
| `tests/`             | The terminal scenarios and the lint, run in a clean Ubuntu container |
| `docs/specs/`        | One spec per feature, from `docs/specs/features/_TEMPLATE.md`       |
| `docs/adr/`          | The decisions that outlive their feature                            |

---

## Verification Commands

```bash
bash tests/lint.sh    # every shell script parses, no shellcheck error, no new warning
bash tests/run.sh     # the terminal scenarios in a clean Ubuntu container, with stand-in agents (needs Docker)
keepalive test        # the live test with real agents, on a machine the developer chose
```

CI (`.github/workflows/ci.yml`) runs the first two on every pull request and on `main`. `tests/lint.sh` fails when
shellcheck reports more warnings than `MAX_WARNINGS`; a change never raises that number. On Windows, run them
from Git Bash with Docker Desktop.

---

## AI Tools & Skills

### Methodology Skills

Process skills live in `.agents/skills/`. Read the relevant one before acting; its `description` says
when it applies. Every skill has the same seven sections in the same order: `Overview`, `When to Use`,
`Process`, `Rationalizations`, `Red Flags`, `Verification`, `Project Context`.

| Skill                            | When to use                                                  |
| -------------------------------- | ------------------------------------------------------------ |
| `using-skills`                   | At session start; orient yourself on the skill system        |
| `brainstorming`                  | Before any new feature or behavior change; produces the spec |
| `executing-plans`                | When an approved spec exists to implement                    |
| `test-driven-development`        | Before writing any implementation code                       |
| `systematic-debugging`           | On any bug, failure, or unexpected behavior                  |
| `verification-before-completion` | Before claiming work done, before the commit guide           |
| `finishing-a-development-branch` | When the work is done and the commit guide is next           |
| `humanizing-text`                | Whenever prose or user-visible text is written or edited     |
| `writing-skills`                 | When creating or modifying skills                            |

**The canonical chain:**

```
using-skills → brainstorming → executing-plans → test-driven-development
             → systematic-debugging (on any failure)
             → verification-before-completion → finishing-a-development-branch

humanizing-text: cross-cutting; it opens whenever prose or user-visible text is written, in any phase.
```

`.agents/skills/references/` holds what more than one skill consumes: the chain and its triggers
(`skill-chain.md`) and the evidence each phase owes (`verification-gates.md`).

### Multi-CLI Consumption

The skills are plain Markdown, so they work in any agent CLI. Claude Code reads `CLAUDE.md`, which imports
this file; Gemini CLI reads `GEMINI.md`, Qwen Code `QWEN.md`, and Codex and OpenCode this file directly.

---

## Git Flow

Every change starts as an issue and reaches `main` through a pull request merged with **Squash and merge**, the
only button the repository allows ([ADR 0001](docs/adr/0001-every-change-through-an-issue-and-a-pull-request.md)).
`.github/workflows/ci.yml` runs the verification commands on every pull request and every push to `main`, and
`pr-title-check.yml` checks each pull request's title. Every install follows `main`
([ADR 0002](docs/adr/0002-every-install-follows-main.md)), so a merge reaches everyone with their next update.
The whole flow, with the issue templates, the labels and the board, is in `docs/GITHUB-WORKFLOW.md`.

```
main                              trunk; what every install pulls with keepalive update
feature/{N}-{english-slug}        feat, from a Vertical Slice issue, off main
fix/{N}-{english-slug}            fix, from a Bug Report issue, off main
refactor/{N}-{english-slug}       refactor, from a Chore issue, off main
chore/{N}-{english-slug}          chore, from a Chore issue, off main
docs/{N}-{english-slug}           docs, from a Chore issue, off main
test/{N}-{english-slug}           test, from a Chore issue, off main
ci/{N}-{english-slug}             ci, from a Chore issue, off main
```

`{N}` is the issue's number. The slug is always English, and a feature's spec carries the same
`{N}-{english-slug}`.

1. Open the issue with its template. The agent creates it with `gh issue create`, the body in Spanish with the
   template's fields, kept in `tmp/{N}/issue-body.md`, and adds it to the
   [agent-keepalive Project](https://github.com/orgs/JDCloud-Ecosystem/projects/1) board with its Status and
   Priority.
2. A feature gets its spec with `brainstorming`. The developer sets `status: approved`, and the issue moves from
   `needs-spec` to `ready-to-code`.
3. Create the branch off `main`.
4. Implement with `executing-plans` and `test-driven-development`.
5. Verify with `verification-before-completion`.
6. Write `tmp/{N}/commit-guide.md` and `tmp/{N}/pr-body.md` with `finishing-a-development-branch`, when the
   developer asks.
7. The developer runs the guide, which pushes the branch and opens the pull request with `Closes #{N}`, and
   merges it with Squash and merge once its checks are green. The title becomes the one commit on `main`.
8. Release Please opens or updates the release PR, with the next version in `version.txt` and the `CHANGELOG.md`
   entry from the `feat` and `fix` titles. Merging it tags `v<version>` and publishes the release. The whole
   process is in `docs/RELEASE.md`.

**Commit messages and pull request titles** follow [Conventional Commits](https://www.conventionalcommits.org/),
in English:

```
<type>(<scope>): <description>    # max 100 chars; scope is REQUIRED
```

Types: `feat`, `fix`, `refactor`, `style`, `docs`, `test`, `chore`, `ci`. The scope names the area, in lower
case: `menu`, `install`, `update`, `login`, `logout`, `schedule`, `status`, `cron`, `lib`, `tests`, `docs`,
`readme`, `specs`, `adr`, `skills`, `github`, `release`, `workflows`, `conventions` or `deps`. commitlint and
Husky check each commit once `pnpm install` has run, and `pr-title-check.yml` checks the pull request title. A
`feat` or `fix` title becomes a line of `CHANGELOG.md` that whoever updates reads, so write it for that person.
Nobody edits the version or `CHANGELOG.md` by hand; Release Please does.

The commit guide is one title line and one `bash` block with no headings, prose or comments: the branch, every
`git add <paths> && git commit -m "…"`, the push and `gh pr create`. Whoever runs it may be on Windows, macOS or
Linux, in any terminal, so it holds plain `git` and `gh` and nothing else, never `$(…)`, pipes, `cp`, `sed` or
`sha256sum`. Work prepared off `main` ships as `tmp/{N}/changes.patch`, applied with `git apply`. `git add` names
paths, never `-A` or `.`. It never changes the version or tags.

---

## Docs, specs and ADRs

- **Spanish prose, English file and folder names.** Specs, ADRs, `docs/`, `README.md` and `CONTRIBUTING.md` are
  Spanish. `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `QWEN.md` and `.agents/skills/` stay English because they are
  protocol files for agents.
- **The spec is the plan.** One file per feature, from `docs/specs/features/_TEMPLATE.md`.
- **ADRs.** When a decision is structural, outlives its feature and had real alternatives, propose an ADR in that
  same reply, unprompted. The rule is in `CONTRIBUTING.md` → «Decisiones de arquitectura (ADR)»; the template is
  in `docs/adr/README.md`. Write it with `status: "proposed"`; only the developer sets `accepted`. Always fill
  «Confirmación».
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
- **The cron has no terminal.** Everything `session-starter.sh` calls works with no terminal, no input and the
  short `PATH` that `write_crontab` sets.
- **Comments in English**, only for a non-obvious why. Never narrate the change, never commented-out code.
- **No magic numbers.** Name the constant.

---

## Tests That Earn Their Place

**Analysis is exhaustive, codification is selective.** Every break path of a feature is listed in its spec,
section 4. A case becomes a scenario in `tests/` when its failure would cost a person something real:

| The failure would                                                        | Verdict |
| ------------------------------------------------------------------------ | ------- |
| Stop the sends, or send at the wrong hour or day                         | Test    |
| Lose the schedule, the history or an account after an update             | Test    |
| Show a token or a login code                                             | Test    |
| Leave a screen with no way back, or a key that does something else       | Test    |
| Break an install that updates from the previous version                  | Test    |
| Show the wrong wording or colour                                         | No test |
| Re-prove what bash, cron or git already guarantee                        | No test |

Removing a test is gated: the proposal names each scenario and its reason, and the developer approves it first.

---

## Definition Of Done

- [ ] `bash tests/lint.sh` and `bash tests/run.sh` pass
- [ ] Edge cases listed in the spec, section 4, each one tested or recorded as analysed and discarded
- [ ] Works from the cron, with no terminal, when it touches a send
- [ ] An install from the previous version keeps sending after it updates, with its schedule and history
- [ ] Every new string in Spanish, with no colon or semicolon inside a sentence
- [ ] `README.md`, `keepalive help` and "About agent-keepalive" below match what the tool does; `CHANGELOG.md`
      comes from the pull request titles
- [ ] No token or login code in the output or the logs

---

## About agent-keepalive

Keep this section current when the tool changes: what it does, how it is put together, and the decisions that
are not obvious from the code.

- **What it does:** at each enabled time (`MORNING`, `AFTERNOON`, `NIGHT` in `config.sh`) and day (`WEEKDAYS`, cron
  numbering), the cron runs `session-starter.sh <session> <agent>` once per agent in `AGENTS`. It sends a short
  prompt with no terminal and logs one entry that ends in `OK`, `LIMIT` or an `ERROR` naming the command that
  fixes it. A limit is not a failure, since an open window is what the send is for.
- **Where things live:** the code and `config.sh` in the clone, usually `~/projects/agent-keepalive`; the logs next
  to them (`sessions.log` for Claude and `codex-sessions.log` for Codex keep their historical names, the rest are
  `<agent>-sessions.log`); the Claude token, its date and its account in `~/.config/agent-keepalive/`, mode 700.
- **The crontab:** `write_crontab` rewrites only its own lines, each under a `# Agent session - <agent>
  <session>` comment, keeps every other line of the person's crontab, and adds a `PATH=` line when there is none.
  It runs on every schedule change and every update.
- **Claude's login:** `login.sh` runs `claude setup-token`, which prints a token that lasts a year through a UI
  that breaks it into lines as wide as the terminal. `token_from_screen` puts it back together; the token goes to
  `claude-token` and is exported as `CLAUDE_CODE_OAUTH_TOKEN` for each send. Codex and OpenCode use their own
  logins, read from their own auth files.
- **The menu:** `keepalive` with no arguments, only in a terminal; without one it prints `status`. Three
  environment variables let a host program frame it: `KEEPALIVE_HEADER` (base64, drawn above every title),
  `KEEPALIVE_NOTICE` (base64, shown once) and `KEEPALIVE_EXIT_LABEL` (the label of option `0`).
- **Updates:** `keepalive update` is `git pull --ff-only` on the clone, `chmod +x` on the scripts and a fresh
  `write_crontab`. `core.fileMode false` keeps a mode change from blocking the pull.
- **Tests:** `tests/run.sh` builds a clean Ubuntu image, puts stand-in `claude`, `codex`, `opencode` and `npm` in
  `/usr/local/bin`, installs the working tree for a user `tester` from a local bare repository, and
  `tests/drive.py` drives every screen through a real pseudo-terminal.
