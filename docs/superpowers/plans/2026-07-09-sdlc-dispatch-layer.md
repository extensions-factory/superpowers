# SDLC Dispatch Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Spec:** `docs/superpowers/specs/2026-07-09-sdlc-dispatch-design.md` — read it before starting. Decisions already settled there: no nesting (subagents never spawn subagents), DISPATCH is mandatory-with-two-escape-hatches, execution roles route offload-first (Codex → Antigravity placeholder → Claude), judgment roles route for provider diversity with Claude always as Final Reviewer plus a Codex adversarial-review pre-final gate when Claude authored most of the branch, and no changes to `assets/sdlc-model-routing.json`'s schema or the existing skill `DISPATCH` tags.

**Goal:** Turn the currently-inert `DISPATCH` tags and harness role ambiguity into an actual, followed guideline — a Role Mode block, a mandatory dispatch rule, and a reference file covering routing, spawn mechanics, and the cross-review cycle.

**Architecture:** Two edits to `skills/using-superpowers/SKILL.md` (replace `<SUBAGENT-STOP>` with a Role Mode block; add a short SDLC Dispatch rule section), one new reference file `skills/using-superpowers/references/dispatch.md` carrying all the mechanics, and one two-line addition each to `references/codex-tools.md` and `references/antigravity-tools.md` declaring their harness's default role.

**Tech Stack:** Markdown skill/reference files. No code, no automated test suite for these files — verification steps are exact `grep` checks that each edit landed as written, per this repo's established pattern for behavior-shaping prose (see `docs/superpowers/plans/2026-07-01-plan-refine-split.md`).

## Expected Outcome

After completing this plan, the developer will have:

### Working behavior

- US-1: A session spawned as a subagent (via a `ROLE: subagent` header, or by opening Codex/Antigravity CLI directly without a header) knows it must not brainstorm interactively, must not spawn further agents, and must not ask the user a question — it executes or reports `BLOCKED` instead.
- US-2: An orchestrator reading a skill file that hits a `<!-- DISPATCH: role=... -->` tag treats it as mandatory, dispatching a subagent unless one of exactly two stated escape hatches applies.
- US-3: An orchestrator dispatching an execution role (Implementer, Fix Agent, Specialist Agent, Research Agent, Documentation Agent, Test Subject) tries Codex first, Antigravity second (currently always skipped — no plugin), Claude last.
- US-4: An orchestrator dispatching a judgment role (Plan Reviewer, Code Reviewer, Task Reviewer, Final Reviewer) never assigns a reviewer that shares a provider with the artifact's author, except that the Final Reviewer is always Claude — with an additional Codex adversarial-review gate inserted first when Claude authored most of the branch.
- US-5: A counter-review (plan refine or code review) writes its findings to a file rather than returning them inline, and the orchestrator's adjudication step (`receiving-plan-refine` / `receiving-code-review`) reads that file directly.

### Artifacts

- `skills/using-superpowers/SKILL.md` — Role Mode block (role determination + subagent-mode restrictions) and SDLC Dispatch rule section (mandatory-with-escape-hatch), both short since this file loads on every session on every harness.
- `skills/using-superpowers/references/dispatch.md` — new file: tag grammar, skill role-class table, spawn-mechanism table, dispatch prompt template, offload-first execution routing, provider-diversity judgment routing, cross-review cycle, error handling.
- `skills/using-superpowers/references/codex-tools.md`, `skills/using-superpowers/references/antigravity-tools.md` — each gets a "Role Mode Default" section declaring that harness's default role.

### How to see it working

Run: `grep -n "Role Mode\|SDLC Dispatch" skills/using-superpowers/SKILL.md` and `cat skills/using-superpowers/references/dispatch.md`
Expected: `SKILL.md` shows both new section headings; `dispatch.md` exists and contains the tag grammar, skill role-class table, spawn-mechanism table, prompt template, offload-first routing table, diversity routing rule, and cross-review cycle table — all traceable back to this plan's tasks below.

## Global Constraints

- `skills/using-superpowers/SKILL.md` is injected into every session on every harness — additions there must stay minimal; all mechanics and tables belong in `references/dispatch.md`, loaded only when a dispatch decision is being made.
- No changes to `assets/sdlc-model-routing.json`'s schema, ranking, or aliases (spec Non-Goals).
- No re-tagging of the 16 skills' existing `SDLC`/`DISPATCH` labels — that work is already committed (`9a293c5`).
- No Antigravity dispatch plugin is built by this plan — Antigravity remains a documented placeholder in routing.
- No hook-level enforcement — this plan is guideline-only (prose), no `PreToolUse` hooks or env-based role signals.
- No nested dispatch — a subagent never spawns another agent, regardless of harness capability.
- Reference files in `skills/using-superpowers/references/` carry no YAML frontmatter (matches existing `codex-tools.md`, `antigravity-tools.md`, `pi-tools.md`).

---

## Foundation

Tag grammar, the skill role-class table, and the spawn-mechanism table are each read by three or more of the User Stories below (US-1's forbidden-skill check, US-3's execution routing, US-4's judgment routing, US-5's review dispatch) — none of them is a complete deliverable for any single story on its own, so they're built once here.

### Task 1: Create `references/dispatch.md` with tag grammar, role-class table, spawn table, and prompt template

**Depends on:** none

**Files:**
- Create: `skills/using-superpowers/references/dispatch.md`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: the file `skills/using-superpowers/references/dispatch.md`, which Task 2 and Task 4 (`SKILL.md`) link to, and which Tasks 5, 6, and 7 append further sections to (the file grows across tasks; each later task's `Modify` step appends after the previous task's last line).

- [ ] **Step 1: Write `skills/using-superpowers/references/dispatch.md`**

```markdown
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
| `condition` | The DISPATCH only fires when this condition holds (e.g. `root cause identified`). |
| `template` | The prompt template file to fill in for this role (e.g. `code-reviewer.md`). |
| `via` | Cross-reference to the skill that actually performs the dispatch mechanics. |
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

Codex sessions load the superpowers bootstrap automatically once installed
(`/codex:setup`) — the header above is all a Codex dispatch needs. Claude
subagents (via the `Agent` tool) receive the bootstrap through the existing
plugin mechanism the same way.
```

- [ ] **Step 2: Verify the file was created with all four sections**

Run: `grep -n "^## " skills/using-superpowers/references/dispatch.md`
Expected:
```
skills/using-superpowers/references/dispatch.md:8:## Tag Grammar
skills/using-superpowers/references/dispatch.md:22:## Skill Role-Class Table
skills/using-superpowers/references/dispatch.md:38:## Spawn-Mechanism Table
skills/using-superpowers/references/dispatch.md:47:## Dispatch Prompt Template
```
(exact line numbers may differ by a line or two — confirm all four headings are present, in this order)

- [ ] **Step 3: Commit**

```bash
git add skills/using-superpowers/references/dispatch.md
git commit -m "using-superpowers: add dispatch.md foundation (tag grammar, role-class table, spawn table, prompt template)"
```

---

## US-1: Subagent knows it's a subagent

### Task 2: Replace `<SUBAGENT-STOP>` with a Role Mode block in `SKILL.md`

**Depends on:** Task 1

**Files:**
- Modify: `skills/using-superpowers/SKILL.md:6-8`

**Interfaces:**
- Consumes: the Skill Role-Class Table in `references/dispatch.md` (Task 1) — the Role Mode block links to it for the full forbidden-skill list.
- Produces: the `## Role Mode` heading and its role-determination rule, which Task 3's harness files reference ("per `using-superpowers`'s Role Mode") and Task 4's SDLC Dispatch section depends on (it only applies when Role Mode resolves to `orchestrator`).

- [ ] **Step 1: Replace the `<SUBAGENT-STOP>` block**

In `skills/using-superpowers/SKILL.md`, replace:

```
<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, ignore this skill.
</SUBAGENT-STOP>
```

with:

```markdown
## Role Mode

Determine your role before doing anything else:

1. **Prompt header wins.** If the task you received starts with `ROLE: orchestrator` or `ROLE: subagent`, use that — regardless of harness.
2. **No header → harness default.** Claude Code's main session is `orchestrator`. A session opened directly on Codex or Antigravity CLI defaults to `subagent` (see that harness's reference file below).

**If your role is `subagent`:**

- Still follow disciplinary skills (`test-driven-development`, `systematic-debugging`, `verification-before-completion`, `writing-skills`) for the task itself.
- Do NOT invoke interactive or coordination skills (`brainstorming`, `project-kickoff`, `writing-plans`, `executing-plans`, `subagent-driven-development`, `dispatching-parallel-agents`, `finishing-a-development-branch`, `requesting-*`, `receiving-*`, `using-git-worktrees`) — full list and rationale in `references/dispatch.md`.
- Do NOT spawn further agents — no nesting, regardless of what your harness technically supports.
- Do NOT ask your human partner a question. If you hit ambiguity you cannot resolve from the task and codebase, report `BLOCKED: <specific question>` back to the orchestrator instead of guessing or asking.

**If your role is `orchestrator`:** continue below.
```

- [ ] **Step 2: Verify the replacement landed**

Run: `grep -c "SUBAGENT-STOP" skills/using-superpowers/SKILL.md || echo ABSENT`
Expected: `ABSENT`

Run: `grep -n "## Role Mode\|Prompt header wins\|BLOCKED:" skills/using-superpowers/SKILL.md`
Expected: all three strings found, in that order.

- [ ] **Step 3: Commit**

```bash
git add skills/using-superpowers/SKILL.md
git commit -m "using-superpowers: replace SUBAGENT-STOP with a Role Mode block"
```

### Task 3: Declare default role in `codex-tools.md` and `antigravity-tools.md`

**Depends on:** Task 2

**Files:**
- Modify: `skills/using-superpowers/references/codex-tools.md`
- Modify: `skills/using-superpowers/references/antigravity-tools.md`

**Interfaces:**
- Consumes: the Role Mode block's terminology (`ROLE:` header, `orchestrator`/`subagent`) from Task 2 — the declarations here must use the same terms.
- Produces: nothing consumed by later tasks; this closes out US-1's acceptance criteria on harness defaults.

- [ ] **Step 1: Add the declaration to `codex-tools.md`**

Insert as the new first section of `skills/using-superpowers/references/codex-tools.md` (before the existing `## Subagent dispatch requires multi-agent support` heading):

```markdown
## Role Mode Default

A session opened directly on Codex CLI — not dispatched with a `ROLE:` header — defaults to `subagent` per `using-superpowers`'s Role Mode. Pass `ROLE: orchestrator` explicitly if you are working here directly rather than through a dispatch.

```

- [ ] **Step 2: Add the same declaration to `antigravity-tools.md`**

Insert into `skills/using-superpowers/references/antigravity-tools.md` right after the existing intro paragraph ("Skills speak in actions...") and before the `| Action skills request | Antigravity CLI equivalent |` table:

```markdown
## Role Mode Default

A session opened directly on Antigravity CLI — not dispatched with a `ROLE:` header — defaults to `subagent` per `using-superpowers`'s Role Mode. Pass `ROLE: orchestrator` explicitly if you are working here directly rather than through a dispatch.

```

- [ ] **Step 3: Verify both files**

Run: `grep -n "Role Mode Default" skills/using-superpowers/references/codex-tools.md skills/using-superpowers/references/antigravity-tools.md`
Expected: one match in each file.

- [ ] **Step 4: Commit**

```bash
git add skills/using-superpowers/references/codex-tools.md skills/using-superpowers/references/antigravity-tools.md
git commit -m "codex-tools, antigravity-tools: declare subagent as default Role Mode"
```

**US-1 Checkpoint:**

Run: `grep -n "Prompt header wins\|Do NOT invoke interactive\|Do NOT spawn further agents\|Do NOT ask your human partner" skills/using-superpowers/SKILL.md` and `grep -n "Role Mode Default" skills/using-superpowers/references/*.md`
Expected: the `SKILL.md` grep shows all four rules present (role determined by header-or-harness-default; forbidden skills named; no spawning; no asking the user — report `BLOCKED` instead). The reference-file grep shows both `codex-tools.md` and `antigravity-tools.md` declaring `subagent` as their default.

---

## US-2: DISPATCH tag is a mandatory instruction, not decoration

### Task 4: Add the SDLC Dispatch rule to `SKILL.md`

**Depends on:** Task 2, Task 1

**Files:**
- Modify: `skills/using-superpowers/SKILL.md`

**Interfaces:**
- Consumes: `references/dispatch.md`'s existence (Task 1) — this section points to it by path.
- Produces: the `## SDLC Dispatch` heading and its two-escape-hatch rule, which US-3/US-4/US-5's Checkpoints below reference as "the rule that sends the orchestrator to `dispatch.md`."

- [ ] **Step 1: Add the section**

In `skills/using-superpowers/SKILL.md`, insert a new section after `## Platform Adaptation` and before `## User Instructions`:

```markdown
## SDLC Dispatch

When a skill block you are following is tagged `<!-- DISPATCH: role=... -->`, you MUST dispatch a subagent for that role — see `references/dispatch.md` for provider selection, spawn commands, and the prompt template. `DISPATCH: inline` means the block is deliberately scoped to stay in your own context; no dispatch decision applies there.

Skip dispatch and work inline ONLY when:

1. Your human partner has explicitly told you to work inline for this task, or
2. No provider is available for the role (checked against the spawn-mechanism table in `references/dispatch.md`).

State which of these applies before working inline. "This task looks small" is not a third reason — dispatch the same way you would for a large one.

This section applies to you only when Role Mode (above) resolved to `orchestrator`. A subagent does not dispatch further (no nesting) and ignores `DISPATCH` tags entirely.
```

- [ ] **Step 2: Verify the section landed**

Run: `grep -n "## SDLC Dispatch\|MUST dispatch a subagent\|Your human partner has explicitly told you\|No provider is available\|is not a third reason" skills/using-superpowers/SKILL.md`
Expected: all five strings found.

- [ ] **Step 3: Commit**

```bash
git add skills/using-superpowers/SKILL.md
git commit -m "using-superpowers: add mandatory-with-escape-hatch SDLC Dispatch rule"
```

**US-2 Checkpoint:**

Run: `sed -n '/## SDLC Dispatch/,/^## User Instructions/p' skills/using-superpowers/SKILL.md`
Expected: the section states dispatch is mandatory on a `DISPATCH: role=...` tag, names exactly two escape hatches (explicit human instruction; no provider available), and explicitly rejects "task looks small" as a hatch.

---

## US-3: Execution work offloads away from Claude by default

### Task 5: Append offload-first routing to `dispatch.md`

**Depends on:** Task 1

**Files:**
- Modify: `skills/using-superpowers/references/dispatch.md` (append after the `## Dispatch Prompt Template` section)

**Interfaces:**
- Consumes: the Spawn-Mechanism Table and Dispatch Prompt Template from Task 1.
- Produces: the `## Offload-First Routing (Execution Roles)` section, which Task 6 appends after (file-ordering dependency only — no content coupling).

- [ ] **Step 1: Append the section**

Append to the end of `skills/using-superpowers/references/dispatch.md`:

```markdown

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
| `scaled to diff` | pick `cheap`/`Standard`/`High` above by diff size, then resolve normally | | |

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
```

- [ ] **Step 2: Verify**

Run: `grep -n "## Offload-First Routing\|Provider order\|Model tier resolution\|scripts/model-lookup.sh\|Parallel dispatches" skills/using-superpowers/references/dispatch.md`
Expected: all five strings found.

- [ ] **Step 3: Commit**

```bash
git add skills/using-superpowers/references/dispatch.md
git commit -m "dispatch.md: add offload-first routing for execution roles"
```

**US-3 Checkpoint:**

Run: `sed -n '/## Offload-First Routing/,/Antigravity has no spawn mechanism/p' skills/using-superpowers/references/dispatch.md`
Expected: shows the execution-role list, the Codex → Antigravity → Claude provider order (with Antigravity marked as currently always-skipped), and the tier→model mapping table.

---

## US-4: Judgment work gets provider diversity

### Task 6: Append diversity routing to `dispatch.md`

**Depends on:** Task 5

**Files:**
- Modify: `skills/using-superpowers/references/dispatch.md` (append after the `## Offload-First Routing (Execution Roles)` section)

**Interfaces:**
- Consumes: nothing new from other tasks (Foundation's Spawn-Mechanism Table already covers `/codex:review`/`/codex:adversarial-review` invocation).
- Produces: the `## Diversity Routing (Judgment Roles)` section, which Task 7's Cross-Review Cycle section references for "which provider reviews which artifact."

- [ ] **Step 1: Append the section**

Append to the end of `skills/using-superpowers/references/dispatch.md`:

```markdown

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
```

- [ ] **Step 2: Verify**

Run: `grep -n "## Diversity Routing\|must differ from the artifact's author\|Final Reviewer exception\|adversarial-review --base" skills/using-superpowers/references/dispatch.md`
Expected: all four strings found.

- [ ] **Step 3: Commit**

```bash
git add skills/using-superpowers/references/dispatch.md
git commit -m "dispatch.md: add provider-diversity routing for judgment roles"
```

**US-4 Checkpoint:**

Run: `sed -n '/## Diversity Routing/,/substitute for the Claude final review/p' skills/using-superpowers/references/dispatch.md`
Expected: shows the diversity rule keyed off author provider, the "state it explicitly" fallback when only one provider exists, and the Final Reviewer exception with the adversarial-review pre-final gate condition.

---

## US-5: Cross-review cycle produces a file, not context pollution

### Task 7: Append the cross-review cycle and error handling to `dispatch.md`

**Depends on:** Task 6

**Files:**
- Modify: `skills/using-superpowers/references/dispatch.md` (append after the `## Diversity Routing (Judgment Roles)` section)

**Interfaces:**
- Consumes: the Diversity Routing rule from Task 6 (the Counter-Review beat below routes per that rule).
- Produces: the `## Cross-Review Cycle` and `## Error Handling` sections — the last content in `dispatch.md`; no later task appends further.

- [ ] **Step 1: Append the sections**

Append to the end of `skills/using-superpowers/references/dispatch.md`:

```markdown

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

## Error Handling

- Codex unavailable for an **execution** role → fall back to Claude at the
  equivalent tier (see Offload-First Routing), state the substitution.
- Codex unavailable for a **judgment** role → same fallback, additionally
  state that provider diversity was not honored.
- Antigravity selected by routing order but no spawn mechanism exists →
  automatically skip to the next provider; expected, not an error.
- A subagent reports `BLOCKED` → apply the escalation ladder from
  `subagent-driven-development`: more context, then a stronger model, then
  decompose the task, then escalate to your human partner. Never
  re-dispatch the same task unchanged.
- No provider available at all for a required dispatch → this is the
  second escape hatch in `using-superpowers`'s SDLC Dispatch rule; work
  inline and state why.
```

- [ ] **Step 2: Verify**

Run: `grep -n "## Cross-Review Cycle\|## Error Handling\|findings file at that skill's existing\|/codex:status\|escalation ladder from" skills/using-superpowers/references/dispatch.md`
Expected: all five strings found.

- [ ] **Step 3: Commit**

```bash
git add skills/using-superpowers/references/dispatch.md
git commit -m "dispatch.md: add cross-review cycle and error handling"
```

**US-5 Checkpoint:**

Run: `sed -n '/## Cross-Review Cycle/,/second escape hatch/p' skills/using-superpowers/references/dispatch.md`
Expected: shows the three-beat table (Author / Counter-Review / Adjudicate) with the findings-file output column, the note that the file mechanism reuses `requesting-plan-refine`'s existing convention, the Codex background-job poll commands, and the five-row error-handling list ending in the "no provider available" escape hatch.
