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

## Offload-First Routing (Execution Roles)

**Execution roles:** `Implementer`, `Fix Agent`, `Specialist Agent`,
`Research Agent`, `Documentation Agent`, `Test Subject`.

**Provider order:** try Codex first, then Antigravity CLI, then Claude —
in that order, taking the first one available:

1. **Codex** — available if installed and authenticated (`/codex:setup`
   confirms this). Try first for every execution role.
2. **Antigravity CLI** — available once a dispatch plugin exists. Until
   then, always unavailable; skip automatically, this is not an error.
3. **Claude** (`Agent` tool) — last resort. Use when Codex is unavailable
   and Antigravity has no spawn mechanism.

**Model tier resolution**, once a provider is chosen:

| DISPATCH `model=` tier | Codex | Claude Code | Antigravity CLI (once available) |
|---|---|---|---|
| `cheap` | `gpt-5.4-mini` | `haiku` | Gemini 3.5 Flash (Low) |
| `Standard` | `gpt-5.4` | `sonnet` | Gemini 3.5 Flash (Medium) |
| `High` | `gpt-5.5` | `opus` | Gemini 3.5 Flash (High) |
| `most capable` | `gpt-5.5` | `fable` | Claude Opus 4.6 (Thinking) |
| `scaled to diff` / `by complexity` | resolve to a fixed tier via the complexity bands below, then read across normally | | |

**Complexity bands** (for `scaled to diff` and `by complexity` tiers —
pick the highest band the task reaches):

- `cheap` — a single-function or single-file mechanical change: renames, a
  localized bug fix, a config edit, an isolated test.
- `Standard` — a few related files with real logic, but a bounded blast
  radius the implementer can hold in context at once. This is the default
  when unsure.
- `High` — cross-cutting or architectural: touches many files, changes a
  shared interface, or needs design judgment about how pieces fit.

When a task straddles two bands, take the higher one — an under-powered
implementer that stalls costs more than the tier saved.

Then cross-check against `scripts/model-lookup.sh <task_type>` (the
`task_type` named in the skill's `<!-- START SDLC: task_type -->` tag): if
the tier-mapped model for the chosen provider appears in that task type's
ranked list, use it. If the chosen provider has no entry for that task
type, use the tier-mapped model directly — `sdlc-model-routing.json`'s
ranking is a refinement of this table, not a replacement for it.

**Substitution:** if Codex is unavailable (not installed, not
authenticated, rate-limited), fall back to Claude at the equivalent tier
and state the substitution before dispatching.

**Parallel dispatches:** when multiple execution subagents are dispatched
at once (see `dispatching-parallel-agents`), each gets independent
provider selection per this order — they do not coordinate with each
other, since no nesting means no cross-subagent spawning either.

## Diversity Routing (Judgment Roles)

**Judgment roles:** `Plan Reviewer`, `Code Reviewer`, `Task Reviewer`,
`Final Reviewer`.

**Rule:** the reviewer's provider must differ from the artifact's author's
provider. Track the author provider from the dispatch that produced the
artifact (e.g. "this diff came from a Codex Implementer dispatch") — that's
already known at review time, no new bookkeeping required.

- Artifact authored by the orchestrator (Claude) — a plan or spec — review
  it on Codex by default (`/codex:rescue` with the reviewer template, or
  `/codex:review`/`/codex:adversarial-review` for code diffs).
- Artifact authored by a Codex execution subagent — implementation code —
  review it on a Claude subagent by default.
- If only one provider is available, proceed with a same-provider
  reviewer, but state explicitly that provider diversity was not honored
  and why.

**Final Reviewer exception:** the whole-branch Final Reviewer is always
Claude, regardless of who authored the branch — this is the one place the
diversity rule is deliberately overridden, per standing user decision.
When Claude authored most of the branch, run
`/codex:adversarial-review --base <ref>` as an *additional* pre-final gate
before dispatching the Claude Final Reviewer — this is additive, not a
substitute for the Claude final review.

## Cross-Review Cycle

Standard three-beat shape for any reviewed artifact — a plan, a spec, or
code:

```
[Author]  --artifact-->  [Counter-Review]  --findings file-->  [Adjudicate]
```

| Beat | Who | Mechanism | Output |
|---|---|---|---|
| Author | Orchestrator (plan/spec) or execution subagent (code) | `writing-plans`, an Implementer dispatch | artifact (plan file, diff, spec) |
| Counter-Review | Provider different from author, per Diversity Routing above | `requesting-plan-refine` / `requesting-code-review` | findings file at that skill's existing conventional path (e.g. `.superpowers/plan-refine/<plan-basename>-findings.md`) |
| Adjudicate | Orchestrator, always | `receiving-plan-refine` / `receiving-code-review` | accept/reject per finding, fixes applied, human partner informed |

The findings-file convention is not new — `requesting-plan-refine` already
writes there. This section only ties the *provider* of that review step to
the Diversity Routing rule above; the file mechanism is unchanged.

Codex-side counter-review runs as a background job: dispatch with
`--background`, poll with `/codex:status`, retrieve with `/codex:result`
(which also returns the Codex session ID for `codex resume` if needed).
