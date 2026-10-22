# agent-keepalive: Qwen Code Instructions

> This file is loaded automatically by Qwen Code at session start.
> The authoritative project protocol is in `AGENTS.md`. Read it first.

## Quick orientation

**Project:** agent-keepalive, bash scripts that open the usage window of AI coding agents from cron on Ubuntu or
Debian. Tested in a Docker container with Python driving a real terminal.

**Primary rules (from AGENTS.md):**

1. NO COMMITS: never `git add`, `git commit`, `git tag`, `git merge` or `git push`
2. `main` always works, because every install follows it
3. Spec first: no implementation of a feature until the spec says `status: approved`
4. LF line endings in every script
5. Spanish only on screen, with no colon or semicolon inside a sentence
6. No tokens or login codes in logs or output
7. Never test on a real install; `tests/` runs in a container
8. No AI attribution in commits, pull requests or files

## Workflow skills

Read the matching file in `.agents/skills/` before acting:

| Situation                      | Skill                            |
| ------------------------------ | -------------------------------- |
| New feature or behavior change | `brainstorming`                  |
| Approved spec to implement     | `executing-plans`                |
| Writing code                   | `test-driven-development`        |
| Bug or failure                 | `systematic-debugging`           |
| About to say done              | `verification-before-completion` |
| Commit guide                   | `finishing-a-development-branch` |
| Prose or user-visible text     | `humanizing-text`                |
| Editing a skill                | `writing-skills`                 |
