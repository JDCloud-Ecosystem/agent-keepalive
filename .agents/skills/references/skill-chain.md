# Skill chain

The order the skills run in, and the one trigger that opens each. `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`
and `QWEN.md` all follow this file.

```
using-skills → brainstorming → executing-plans → test-driven-development
             → systematic-debugging (on any failure)
             → verification-before-completion → finishing-a-development-branch

humanizing-text: cross-cutting; it opens whenever prose or user-visible text is written, in any phase.
```

| Skill                            | Trigger                                                |
| -------------------------------- | ------------------------------------------------------ |
| `using-skills`                   | A session starts, or it is unclear which skill applies |
| `brainstorming`                  | A new feature or a behavior change is asked for        |
| `executing-plans`                | A spec says `status: approved`                         |
| `test-driven-development`        | Implementation code is about to be written             |
| `systematic-debugging`           | A test, a check or a real install fails or surprises   |
| `verification-before-completion` | About to say done, or to write the commit guide        |
| `finishing-a-development-branch` | The work is verified and the commit guide is next      |
| `humanizing-text`                | Prose or user-visible text is written or edited        |
| `writing-skills`                 | A skill is created, renamed or changed                 |
