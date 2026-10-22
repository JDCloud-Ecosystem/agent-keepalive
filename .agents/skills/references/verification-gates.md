# Verification gates

Which command proves which claim, and what each phase owes before it closes. A claim without its evidence
in the same message is not made.

## Claim → evidence

| Claim                              | Command                                              | Evidence                                                        |
| ---------------------------------- | ---------------------------------------------------- | --------------------------------------------------------------- |
| Every script parses                | `bash -n` on each script, as in `AGENTS.md`          | No output, exit 0                                               |
| No shellcheck error                | `shellcheck -x --severity=error` on each script      | Exit 0                                                          |
| No new shellcheck warning          | `shellcheck -x` on each script                       | The same count as on `main`, or fewer                           |
| The screens and commands work      | `bash tests/run.sh`                                  | The summary line, every scenario passed                         |
| An install from before still works | The upgrade scenario of `tests/`                     | Its cron, config and logs after the update                      |
| It works on a real machine         | `keepalive test`, on a machine the developer chose   | «Todas las pruebas pasaron.» and each agent's send              |
| Nothing secret leaks               | Read the test output and the logs                    | No token, `.claude-token` content or login code anywhere        |

## What each phase owes

| Phase                            | Owes                                                                    |
| -------------------------------- | ----------------------------------------------------------------------- |
| `brainstorming`                  | The spec file, every section filled, approved by the developer          |
| `executing-plans`                | Each task's verification output, the Change Log, `status: done`         |
| `test-driven-development`        | The failing proof before the code, the passing one after                |
| `systematic-debugging`           | The root cause in one sentence, the reproduction failing then passing   |
| `verification-before-completion` | The checks, the edge-case list with verdicts, the scenarios that ran    |
| `finishing-a-development-branch` | The checks green, every file in a commit, the guide's and body's paths  |
