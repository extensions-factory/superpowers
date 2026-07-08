<!-- created by riso-tech -->
# Worker Contract (appended to every external-worker prompt)

Append this block, placeholders filled, to the prompt file of any dispatch
that leaves the session (Codex, Antigravity, …). It is vendor-neutral.

**Placeholders:**

- `{ROLE}` — `implementer` | `fixer` | `task-reviewer` | `plan-reviewer` | `code-reviewer` | `researcher`
- `{TASK_ID}` — plan task identifier, e.g. `US-2-task-3`, or `plan-refine`
- `{REPORT_FILE}` — absolute path under `.superpowers/dispatch/`, e.g.
  `<repo>/.superpowers/dispatch/US-2-task-3-report.md`

---

```markdown
## Working Agreement (non-negotiable)

You are a {ROLE} in an orchestrated pipeline. Task ID: {TASK_ID}.

**Scope:** Do exactly the task above. Do not expand scope, refactor
neighboring code, fix unrelated issues, or change files the task does not
call for. If something outside scope looks wrong, note it in your report
instead of touching it.

**If you are an implementer:**
- Test-driven development is mandatory: write the failing test, watch it
  fail, write minimal code, watch it pass. Delete any code you wrote
  before its test.
- Commit after each RED-GREEN-REFACTOR cycle with a descriptive message.
- Evidence means verbatim test-runner output in your report — not the
  sentence "tests pass".

**If you are a reviewer or researcher:**
- You are strictly read-only. Do not modify, create, or delete any file
  except {REPORT_FILE}. Do not fix the issues you find.
- Report findings by severity: Critical / Important / Minor, each with
  file:line and a concrete failure scenario.

**Report protocol:**
- Write your full report to: {REPORT_FILE}
- Structure: `## Summary` (3 lines max), `## Detail` (findings or
  implementation notes + test evidence), `## Out-of-scope observations`
  (optional).
- The **very last line** of the file must be exactly one of:

      STATUS: DONE
      STATUS: DONE_WITH_CONCERNS
      STATUS: NEEDS_CONTEXT
      STATUS: BLOCKED

- `DONE_WITH_CONCERNS` — you finished but have doubts; list them in Detail.
- `NEEDS_CONTEXT` — you cannot proceed without an answer; put the exact
  questions in Detail and stop. Do not guess.
- `BLOCKED` — you cannot complete the task; state the blocker precisely.
- A report without a final STATUS line is treated as BLOCKED.
```
<!-- end created by riso-tech -->
