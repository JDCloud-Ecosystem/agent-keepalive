# Root Cause Tracing

Trace bugs backward through the call stack to find the original trigger.

## The Technique

Start from the error. Work backward.

```
Error: Cannot read property 'x' of undefined
  at ComponentA.render (ComponentA.jsx:42)
  at ...
```

**Step 1:** Identify the immediate failure point.
→ Line 42 of ComponentA.jsx: something is `undefined` that shouldn't be.

**Step 2:** Ask "what provides this value?"
→ `props.data` — provided by parent.

**Step 3:** Trace to the provider.
→ Parent passes `data={response.items}`. Is `response` undefined?

**Step 4:** Continue until you reach the origin.
→ API call returns `null` when no items found. Caller assumed array, got null.

**Root cause:** API response contract violated — caller expected `[]`, got `null`.

**Fix at source:** Make the API always return `[]` when empty, or make the caller
handle `null` explicitly (YAGNI: fix at source is cleaner).

## Layers in agent-keepalive

When a send does not happen, or a screen shows the wrong thing, instrument these layers in order:

1. **The crontab**, `crontab -l`. Is the line there, at that hour and day, with the right path?
2. **The config**, the values `load_config` ends with. Did a hand edit or an older key change them?
3. **The agent**, the command `session-starter.sh` runs, from a shell with no terminal. What did it answer?
4. **The log**, the agent's last entry. Which of `OK`, `LIMIT` or `ERROR` did the answer become?
5. **The screen**, what `describe_run` and the table made of that entry.

Log at each boundary to find where the data diverges from expected.
