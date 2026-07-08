<!-- created by riso-tech -->
# Bridge Dispatch Protocol

Mechanics for sending a dispatch to an external worker through a bridge
plugin (Codex today via `codex-plugin-cc`; Antigravity later via
`agy-plugin-cc`). External workers never see your session context —
everything crosses through files.

## Workspace (once per session)

```bash
root=$(git rev-parse --show-toplevel)
dir="$root/.superpowers/dispatch"
mkdir -p "$dir"
printf '*\n' > "$dir/.gitignore"
```

## Per Dispatch

**1. Write the prompt file** `"$dir/<task-id>-prompt.md"`:

- the calling skill's prompt template, filled as usual (for SDD
  implementers this wraps the task-brief path handoff — keep exact values
  in the brief, per that skill's File Handoffs section), plus
- the worker contract from [worker-contract.md](worker-contract.md) with
  `{ROLE}`, `{TASK_ID}`, `{REPORT_FILE}` filled. `{REPORT_FILE}` is
  `"$dir/<task-id>-report.md"`.

**2. Dispatch.** For Codex:

| Role | How |
|---|---|
| implementer, fixer, task-reviewer, researcher | Invoke the `codex:codex-rescue` subagent (Agent tool, `subagent_type: "codex:codex-rescue"`) with flags + task text: `--background --fresh [--model <resolved>] [--effort <resolved>] [--profile <only if registry pins one>] Read <prompt-file> and follow it exactly. Write your report to the path it specifies.` |
| plan-reviewer | `/codex:adversarial-review --background` with focus text naming the plan file, the spec file, and the report-file contract |
| code-reviewer (whole branch) | `/codex:review --base <merge-base> --background`, or adversarial-review when the review must challenge design, with the report-file contract in the focus text |

Review commands are read-only by construction — prefer them for reviewer
roles when they fit the target (working tree / branch vs base). Use rescue
with a reviewer prompt file when the review target is a task-scoped diff
package.

**3. Wait productively.** Check `/codex:status <job-id>` between other
work — review the previous task's report, update the ledger. Never poll in
a tight loop.

**4. Read the report file** (`{REPORT_FILE}`), not the bridge's raw
output. Extract the final `STATUS:` line and the summary. Pass findings
onward as a file path — never paste report bodies into your context.

## Status Mapping

| Observation | Treat as |
|---|---|
| Report ends `STATUS: DONE` | DONE |
| `STATUS: DONE_WITH_CONCERNS` | DONE_WITH_CONCERNS — read the concerns before proceeding |
| `STATUS: NEEDS_CONTEXT` | Answer the questions in a follow-up dispatch with `--resume` (stays on the worker's thread and account) |
| `STATUS: BLOCKED` | Apply the calling skill's blocker handling (more context / stronger tier / split task / escalate) |
| Bridge job failed or cancelled | BLOCKED; blocker = the bridge error. Walk the role's fallback list |
| Job succeeded but report missing or lacks a `STATUS:` line | Protocol violation — re-dispatch once with the contract restated; on repeat, BLOCKED. Never infer status from prose |

## Resume Discipline

A bridge thread belongs to the account that created it. Follow-ups use
`--resume` and must not pass a different `--profile` — the bridge will
refuse, by design. Fresh work omits `--profile` so rotation can balance
accounts.
<!-- end created by riso-tech -->
