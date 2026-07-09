# SDLC Dispatch

Mechanics for the `DISPATCH` rule in `using-superpowers/SKILL.md`. Read this
file when you (the orchestrator) are about to act on a `<!-- DISPATCH -->`
tag. Subagents do not read this file — they don't dispatch (no nesting).

## Tag Grammar

A skill's `<!-- DISPATCH: ... -->` comment carries `key=value` fields
separated by ` | `:

| Field | Meaning |
|---|---|
| `role` | The role being dispatched (e.g. `Implementer`, `Plan Reviewer`, `Fix Agent`). `inline` means: do not dispatch, stay in the orchestrator's own context. |
| `count` | How many subagents of this role to dispatch. `N` or `1+` means the number is task-dependent. |
| `model` | The tier to dispatch at: `cheap`, `Standard`, `High`, or a task-specific phrase (`most capable`, `scaled to diff`) — resolved to a concrete model in the routing sections below. |
| `parallel` | `true` if the dispatches run concurrently (see `dispatching-parallel-agents`). |
| `per_task` | `true` if this DISPATCH fires once per plan task, not once per skill invocation. |
| `condition` / `on_condition` | The DISPATCH only fires when this condition holds (e.g. `root cause identified`). Both spellings appear in the existing tag corpus and mean the same thing — no re-tagging is planned; treat them as synonyms. |
| `template` | The prompt template file to fill in for this role (e.g. `code-reviewer.md`). |
| `via` | Cross-reference to the skill that actually performs the dispatch mechanics. |
| `after` | Ordering constraint — this dispatch runs after the named milestone (e.g. `all tasks`). |
| `reason` | Why this block is `inline` (or dispatched). The most common field in the corpus — every `DISPATCH: inline` tag carries one. |
| `note` | Free-text clarification. |

## Skill Role-Class Table

Whether a skill may be invoked by a subagent, or only by the orchestrator.

**Orchestrator-only, interactive** (require your human partner in the loop):
`brainstorming`, `project-kickoff`, `finishing-a-development-branch`.

**Orchestrator-only, coordination** (dispatch or adjudicate — the act of
coordinating other agents, or the judgment call over their output, is
itself orchestrator work): `writing-plans`, `executing-plans`,
`subagent-driven-development`, `dispatching-parallel-agents`,
`requesting-plan-refine`, `requesting-code-review`, `receiving-plan-refine`,
`receiving-code-review`, `using-git-worktrees`.

**Subagent-ok** (a dispatched subagent may follow these while doing its own
work): `test-driven-development`, `systematic-debugging`,
`verification-before-completion`, `writing-skills`.

A subagent dispatched *as a reviewer* (e.g. `role=Code Reviewer` with a
`template`) is doing subagent-ok work even though the skill that dispatched
it (`requesting-code-review`) is orchestrator-only — the reviewer only ever
sees its own template and target artifact, never the coordination skill.

## Spawn-Mechanism Table

How to actually start a subagent, per provider.

| Provider | Mechanism | Notes |
|---|---|---|
| Codex | `/codex:rescue "<task>" [--model X] [--effort Y] [--background] [--resume]` for execution/investigation; `/codex:review [--base <ref>] [--background]` for read-only diff/branch review; `/codex:adversarial-review [--base <ref>] <focus text>` for a steerable challenge review | Via the `codex-plugin-cc` plugin. Requires Codex installed and authenticated — check with `/codex:setup` if unsure. |
| Claude Code | `Agent` tool, `subagent_type` + `model` parameters, prompt carries the `ROLE: subagent` header (see Dispatch Prompt Template below) | Native — always available from a Claude Code orchestrator. |
| Antigravity CLI | none | No dispatch plugin exists yet. Routing automatically skips to the next provider — this is expected, not an error. |

## Dispatch Prompt Template

Every subagent dispatch prompt starts with this header, then the task:

```
ROLE: subagent
TASK_TYPE: <task_type from assets/sdlc-model-routing.json, e.g. implementation_coding>
<task description: what to do>
<interfaces touched: exact files, function signatures, global constraints>
Rules: follow superpowers skills in subagent mode (see using-superpowers
Role Mode). Do not ask the user questions — report BLOCKED with the specific
question instead. Do not spawn further agents.
Report: status, files changed, tests run + output, blockers.
```

The header above is all a dispatch needs, *provided the superpowers skill
set is already installed on the receiving side*. On Codex that install is a
separate path from this plugin — the superpowers skills are synced into the
Codex plugin fork via `scripts/sync-to-codex-plugin.sh`; `/codex:setup`
(part of `codex-plugin-cc`) only confirms the Codex CLI itself is reachable,
it does not install or load the skill bootstrap. Claude subagents (via the
`Agent` tool) receive the bootstrap through the existing Claude Code plugin
mechanism automatically. If a dispatched subagent's report shows it never
loaded `using-superpowers`, the skill set isn't installed on that side —
fix the install, don't rely on the prompt header alone.
