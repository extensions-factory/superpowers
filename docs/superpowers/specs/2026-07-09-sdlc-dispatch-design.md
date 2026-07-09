---
title: SDLC Dispatch Layer
date: 2026-07-09
status: draft
---

# SDLC Dispatch Layer — Design Spec

## 1. Overview

Superpowers runs on three harnesses today: Claude Code (interactive, user-facing), the Codex plugin (`codex-plugin-cc`, real subagent dispatch via `/codex:rescue`, `/codex:review`, `/codex:adversarial-review`), and Antigravity CLI (skills installed, no dispatch plugin yet). Two pieces of prior work sit unconnected: `assets/sdlc-model-routing.json` (a lookup table of recommended models per SDLC task type) and `<!-- START SDLC -->` / `<!-- DISPATCH -->` HTML-comment tags added to 16 skill files. Neither is read by any script or enforced by any instruction — they are labels, not behavior. Separately, nothing in `using-superpowers` tells a subagent (spawned by Claude's `Agent` tool, or a session opened directly in Codex/Antigravity) that it *is* a subagent — the only signal today is `<SUBAGENT-STOP>`, which says "don't follow this bootstrap skill" but defines no alternate mode.

This spec turns the DISPATCH tags into an actual guideline an orchestrator follows, defines who is allowed to be an orchestrator vs. a subagent per harness, and specifies a cross-review cycle (author → counter-review by a different provider → orchestrator adjudicates) so review artifacts get provider diversity by default instead of by accident.

## 2. Context & Assumptions

- Claude Code is the only harness the user interacts with directly today. Codex and Antigravity are reached exclusively through dispatch (Codex: working plugin; Antigravity: not yet — no plugin exists to spawn it).
- `assets/sdlc-model-routing.json` and `scripts/model-lookup.sh` (fixed in commit `b43d882`) are the source of truth for "which model for which task type." This spec does not change that file's schema or ranking.
- The 16 skill files already carry `<!-- START SDLC: task_type -->` / `<!-- DISPATCH: ... -->` tags (added across commits `e01bcb1`, `35053d4`, `bb61a05`, and corrected in `9a293c5`). This spec defines what those tags mean operationally; it does not re-tag skills.
- `using-superpowers/SKILL.md` is injected into every session on every harness — it is the one file whose token cost is paid on every single turn, on every harness. Anything added there must earn its place; detail belongs in a reference file loaded only when dispatching.
- Assumption: the user (only one, interacting solely through Claude Code) accepts that Codex and Claude subagents may occasionally consume separate usage/billing pools when dispatched. This is already true today via the existing Codex plugin and is not a new cost introduced by this spec.
- Assumption: "no nesting" (a subagent cannot itself spawn another subagent) is acceptable even though Codex (`multi_agent`) and Antigravity (`invoke_subagent`) are technically capable of it. Confirmed with the user during brainstorming.
- Assumption: Antigravity CLI has no dispatch plugin as of this spec. The design accounts for it as a routing target (present in `sdlc-model-routing.json`) but its spawn mechanism is a documented placeholder, not implemented.

## 3. Scope

### Goals

- Define **Role Mode**: how any session (orchestrator vs. subagent) determines which mode it's in, and what subagent mode forbids (interactive skills, spawning further agents, asking the user).
- Make the `DISPATCH` tag **actionable**: a mandatory-with-escape-hatch rule in `using-superpowers`, with the full mechanics (routing, provider selection, spawn commands, prompt template) in a new reference file.
- Route **execution** roles (Implementer, Fix Agent, Specialist, Research, Documentation, Test Subject) offload-first: Codex → Antigravity (once available) → Claude subagent, in that order.
- Route **judgment** roles (reviewers) for provider diversity: reviewer must not share a provider with the artifact's author.
- Specify the **cross-review cycle** (author → counter-review-to-file → orchestrator adjudicates) as the standard shape for plan review and code review, generalized from the existing `writing-plans → requesting-plan-refine → receiving-plan-refine` and `requesting-code-review → receiving-code-review` sequences.
- Declare per-harness default role (Codex and Antigravity sessions default to subagent mode unless a prompt header overrides it).

### Non-Goals

- Not changing `assets/sdlc-model-routing.json`'s schema, ranking, or aliases — that table is out of scope here.
- Not re-auditing or re-tagging the 16 skills' `SDLC`/`DISPATCH` labels — that was completed separately (commit `9a293c5`).
- Not building an Antigravity dispatch plugin — Antigravity remains a documented placeholder in routing until that plugin exists.
- Not building hook-level enforcement (a `PreToolUse` hook that mechanically blocks an orchestrator-only skill in subagent mode). This spec is guideline-only; hook enforcement is a possible future escalation if guideline compliance proves insufficient (see Alternatives).
- Not adding nested dispatch (subagent spawning subagent). Explicitly rejected by the user.
- Not adding a `roadmap.json` entry for this feature — this repository does not yet maintain its own roadmap (see precedent in `docs/superpowers/specs/2026-07-02-project-kickoff-design.md`).
- Not generating an HTML companion for this spec — no spec in this repository's history has one, despite the skill instruction; consistent with the roadmap precedent, this repo keeps markdown as the sole spec artifact.

## 4. User Stories

### US-1: Subagent knows it's a subagent (Priority: P1)

As an orchestrator dispatching a task, I want the spawned session (whether Claude `Agent` tool, Codex, or future Antigravity) to know it is running in subagent mode, so that it doesn't try to brainstorm interactively, ask the user a question, or spawn further agents.

**Acceptance criteria:**

- GIVEN a session opened without a `ROLE:` header, on Codex or Antigravity CLI, WHEN it loads `using-superpowers`, THEN it operates in subagent mode by default.
- GIVEN a dispatch prompt with `ROLE: subagent` in its header, WHEN the spawned session (any harness) starts, THEN it operates in subagent mode regardless of harness default.
- GIVEN a session in subagent mode, WHEN it would normally invoke an interactive skill (`brainstorming`, `project-kickoff`, `finishing-a-development-branch`) or an orchestrator-only coordination skill (`writing-plans`, `executing-plans`, `subagent-driven-development`, `dispatching-parallel-agents`, `requesting-*`, `receiving-*`, `using-git-worktrees`), THEN it refuses and reports the mismatch to the orchestrator instead.
- GIVEN a session in subagent mode that hits ambiguity it cannot resolve from the task and codebase, WHEN it would normally ask the user, THEN it reports `BLOCKED` with the specific question back to the orchestrator instead.

### US-2: DISPATCH tag is a mandatory instruction, not decoration (Priority: P1)

As an orchestrator reading a skill file, I want a `DISPATCH` tag to carry the same force as any other MUST-follow skill instruction, so that I don't rationalize inlining execution work that should be offloaded.

**Acceptance criteria:**

- GIVEN a skill block tagged `<!-- DISPATCH: role=X ... -->`, WHEN the orchestrator reaches that point in the skill, THEN it dispatches a subagent for role X rather than doing the work inline.
- GIVEN the same situation, WHEN the user has explicitly said to work inline, THEN the orchestrator may skip dispatch and states that it is doing so and why.
- GIVEN the same situation, WHEN no provider is available for role X (checked against the spawn-mechanism table), THEN the orchestrator may work inline and states that it is doing so and why.
- GIVEN neither escape hatch applies, WHEN the orchestrator considers "this task looks small," THEN that is not a valid reason to skip dispatch.

### US-3: Execution work offloads away from Claude by default (Priority: P1)

As the user who wants to conserve Claude usage and context, I want execution-role dispatches (Implementer, Fix Agent, etc.) to prefer Codex, then Antigravity, then Claude as a last resort, so that Claude's context and usage are spent on orchestration and judgment, not bulk execution.

**Acceptance criteria:**

- GIVEN an execution-role DISPATCH (`role=Implementer`, `Fix Agent`, `Specialist Agent`, `Research Agent`, `Documentation Agent`, `Test Subject`), WHEN the orchestrator selects a provider, THEN it tries Codex first (via the Codex plugin), Antigravity CLI second (once a spawn mechanism exists), and Claude `Agent` tool last.
- GIVEN Codex is chosen, WHEN the orchestrator picks a model within Codex, THEN it uses the DISPATCH tag's tier (`cheap`/`Standard`/`High`) mapped to that provider's models per `sdlc-model-routing.json`.
- GIVEN Codex is unavailable (not installed, not authenticated, rate-limited) WHEN dispatching an execution role, THEN the orchestrator falls back to the next provider in order and states the substitution.

### US-4: Judgment work gets provider diversity (Priority: P1)

As the user relying on review to catch mistakes, I want a reviewer to never share a provider with the artifact's author, so that review isn't just the same model checking its own work.

**Acceptance criteria:**

- GIVEN an artifact authored by the orchestrator (Claude) — e.g. a plan or spec — WHEN a judgment-role DISPATCH (`role=Plan Reviewer`, `Code Reviewer`) fires for it, THEN the reviewer is dispatched to a non-Claude provider (Codex by default).
- GIVEN an artifact authored by a Codex execution subagent — e.g. implementation code — WHEN a judgment-role DISPATCH fires for it, THEN the reviewer is dispatched to a non-Codex provider (Claude subagent by default).
- GIVEN the diversity rule cannot be honored (only one provider available), WHEN the orchestrator proceeds with a same-provider reviewer, THEN it states explicitly that provider diversity was not honored and why.
- GIVEN any review is complete, WHEN the whole-branch final review runs, THEN it is always dispatched to Claude, per the user's standing decision.

### US-5: Cross-review cycle produces a file, not context pollution (Priority: P2)

As an orchestrator running review after review across a long session, I want counter-review output to land in a file rather than in my own context, so that a review round doesn't cost me a growing block of read/re-read tokens on every later turn.

**Acceptance criteria:**

- GIVEN the orchestrator finishes an artifact (a plan via `writing-plans`, or code via an execution subagent), WHEN it dispatches counter-review, THEN the review role writes findings to a file at a conventional path rather than returning them inline.
- GIVEN a counter-review file exists, WHEN the orchestrator adjudicates (`receiving-plan-refine`, `receiving-code-review`), THEN it reads that file directly rather than requesting the findings be repeated in chat.
- GIVEN adjudication is happening, WHEN any finding needs a decision, THEN only the orchestrator makes accept/reject calls — this step is never itself dispatched.

## 5. Approach

Docs-only guideline layer: extend `using-superpowers/SKILL.md` with a short, always-loaded Role Mode block and an SDLC Dispatch rule (~8 lines, mandatory-with-escape-hatch), and move all mechanics — the skill role-class table, offload-first routing algorithm, per-provider spawn table, prompt template, and the cross-review cycle — into a new `skills/using-superpowers/references/dispatch.md`, loaded only when a dispatch decision is actually being made. Two-line role declarations are added to the existing `codex-tools.md` and `antigravity-tools.md` reference files. No code, no hooks, no changes to `sdlc-model-routing.json`'s schema.

This was chosen over building machine-readable routing metadata into the JSON (more consistency, but doubles the surface that can drift — the exact failure just fixed in `quick_lookup`/`best_for`) and over hook-level enforcement (real teeth, but no evidence yet that guideline compliance is insufficient, and hook mechanisms differ across harnesses in ways that would multiply this into a much larger project). The chosen approach can ship immediately, gets exercised in real sessions, and gives the data needed to justify escalating to a heavier approach later if agents rationalize their way around it.

### Alternatives considered

| Option | Why rejected |
|--------|--------------|
| Guideline + machine-readable JSON extension (role class, offload policy, provider availability flags added to `sdlc-model-routing.json`) | Adds a second data surface that must stay in sync with the skill tags and the guideline text — the same drift pattern that produced 31 missing `quick_lookup` aliases and 16 `best_for` contradictions, just fixed this session. No current evidence the plain-text guideline is insufficient. |
| Hook-level enforcement (env-based role signal, `PreToolUse` hook blocking orchestrator-only skills in subagent mode) | Real mechanical enforcement, but hook models differ substantially across Claude Code, Codex, and Antigravity — some of the needed hook points may not exist on every harness. Large scope increase to solve a problem (agents ignoring the tag) not yet observed in practice. |
| Nested dispatch (subagent may spawn its own subagents) | Rejected directly by the user. Loses orchestration visibility — the orchestrator would no longer have a full picture of what's running, and cost/usage tracking gets harder to reason about. |

## 6. Design

### Architecture

```
Claude Code (orchestrator, user-facing)
  reads skill → hits <!-- DISPATCH --> tag
  → consults references/dispatch.md for role class + provider order
  → picks provider by role class (execution: offload-first; judgment: diversity)
  → spawns subagent with ROLE: subagent header + task
       ├─ Codex   → /codex:rescue or /codex:review (existing plugin, real)
       ├─ Claude  → Agent tool, model param
       └─ Antigravity → [no spawn mechanism yet — provider skipped]
  subagent runs in Role Mode: subagent
       → follows disciplinary skills (TDD, systematic-debugging, verification-before-completion)
       → forbidden: interactive/coordination skills, further spawning, asking the user
       → on ambiguity: reports BLOCKED to orchestrator, does not guess or ask
  subagent reports back (status, files changed, tests run, blockers)
  orchestrator adjudicates (receiving-*), never delegates adjudication
```

### Components & Interfaces

**Role Mode block** (`using-superpowers/SKILL.md`, replaces `<SUBAGENT-STOP>`): determines role from a `ROLE:` prompt header if present, else from harness default (Claude Code main session = orchestrator; Codex/Antigravity session = subagent, per that harness's reference file). Defines what subagent mode forbids. This is the only role-mode text loaded on every turn on every harness — kept to a fixed, small block; anything more belongs in `dispatch.md`.

**SDLC Dispatch rule** (`using-superpowers/SKILL.md`, new section, ~8 lines): states the DISPATCH tag is mandatory, names the two escape hatches (explicit user instruction to work inline; no provider available), and states that "the task looks small" is not a valid third hatch. Points to `references/dispatch.md` for mechanics. Applies to orchestrator only; a subagent reading a skill ignores DISPATCH tags entirely (it cannot dispatch — no nesting).

**`references/dispatch.md`** (new file), covering:
- Tag grammar: formal definition of `role`, `count`, `model`, `parallel`, `per_task`, `condition`, `template`, `via`, `note`.
- Skill role-class table: which skills are orchestrator-only (interactive: `brainstorming`, `project-kickoff`, `finishing-a-development-branch`; coordination: `writing-plans`, `executing-plans`, `subagent-driven-development`, `dispatching-parallel-agents`, `requesting-*`, `receiving-*`, `using-git-worktrees`) vs. subagent-ok (`test-driven-development`, `systematic-debugging`, `verification-before-completion`, `writing-skills`, and any role dispatched with a reviewer template).
- Offload-first routing for execution roles: Codex → Antigravity (placeholder) → Claude, with tier→model mapping per provider sourced from `sdlc-model-routing.json` via `scripts/model-lookup.sh`.
- Diversity routing for judgment roles: reviewer provider ≠ author provider; Final Reviewer always Claude.
- Spawn-mechanism table per provider (Codex: `/codex:rescue`, `/codex:review`, `/codex:adversarial-review`, background + `--resume`; Claude: `Agent` tool; Antigravity: none yet, documented placeholder).
- Dispatch prompt template with `ROLE:`/`TASK_TYPE:` header.
- The cross-review cycle (below).
- Error handling: Codex unavailable → same-tier Claude subagent, state substitution; diversity broken → state it explicitly; subagent `BLOCKED` → orchestrator follows the existing SDD escalation ladder (more context → stronger model → decompose → ask human).

**Harness reference files** (`codex-tools.md`, `antigravity-tools.md`): two-line addition each declaring the harness's default role.

### Data Model & Flow — the Cross-Review Cycle

Standard three-beat shape for any reviewed artifact:

```
[Author]  --artifact-->  [Counter-Review]  --findings file-->  [Adjudicate]
```

| Beat | Who | Mechanism | Output |
|---|---|---|---|
| Author | Orchestrator (plan/spec) or execution subagent (code) | `writing-plans`, implementer dispatch | artifact (plan file, diff, spec) |
| Counter-Review | Provider different from author | `requesting-plan-refine` / `requesting-code-review`, dispatched per the diversity rule | findings file at the skill's existing conventional path |
| Adjudicate | Orchestrator, always | `receiving-plan-refine` / `receiving-code-review` | accept/reject per finding, fixes applied, user informed |

This generalizes the sequence already implicit in the existing skill pair names — `writing-plans → requesting-plan-refine → receiving-plan-refine` and the code equivalent — by making explicit which beat runs on which provider and enforcing that the review beat is never same-provider as the author beat when an alternative exists. The mechanism itself (findings-to-file, not inline) is not new — `requesting-plan-refine` already writes to a directory with a `.gitignore`; this spec generalizes the pattern and ties it to provider selection rather than introducing a new file convention. Codex-side counter-review runs as a background job; the orchestrator polls via `/codex:status` and retrieves via `/codex:result`.

### Error Handling

- Codex unavailable (not installed/authenticated/rate-limited) for an execution role → fall back to Claude subagent at the equivalent tier, state the substitution to the user.
- Codex unavailable for a judgment role → same fallback, but additionally flag that provider diversity was not honored.
- Antigravity selected by routing order but no spawn mechanism exists → automatically skip to the next provider; this is expected today, not an error state.
- Subagent reports `BLOCKED` → orchestrator applies the existing subagent-driven-development escalation ladder (more context, stronger model, decompose, escalate to human) rather than re-dispatching unchanged.
- No provider available at all for a required dispatch → this is the second escape hatch; orchestrator works inline and states why.

### Edge Cases

- A prompt explicitly opens a Codex or Antigravity session as `ROLE: orchestrator` (the user working there directly rather than through Claude): Role Mode honors the header override, DISPATCH tags apply normally in that session.
- A skill block has `DISPATCH: inline` (not a role dispatch): this is not a tag violation — it's the tag documenting that this particular block was deliberately scoped to stay in-context (e.g. interactive Q&A, RED/GREEN same-context steps in TDD). No dispatch decision is triggered.
- Multiple execution subagents dispatched in parallel (`dispatching-parallel-agents`): each gets independent provider selection per the offload-first order; they do not coordinate with each other (no nesting means no cross-subagent spawning either).

## 7. Testing Strategy

Per `writing-skills` methodology — pressure-scenario testing with subagents, RED (no guidance) vs. GREEN (with guidance):

1. **US-1**: Spawn a subagent with a task that tempts interactive brainstorming (e.g. an ambiguous feature request). Verify it executes directly / reports BLOCKED instead of invoking `brainstorming` or asking the user.
2. **US-2**: Present the orchestrator with a DISPATCH-tagged block and a task that is small enough to rationalize inlining (e.g. "just fix this one line"). Verify it dispatches rather than inlining, absent either escape hatch.
3. **US-3 / US-4**: Present the orchestrator with an execution dispatch and a judgment dispatch in sequence for the same artifact. Verify provider order (execution: Codex-first) and diversity (judgment: reviewer ≠ author provider) are both honored.
4. **US-5**: Run `writing-plans` to produce a plan, then verify the orchestrator's next move is dispatching `requesting-plan-refine` to a different provider rather than self-reviewing, and that adjudication reads a findings file rather than requesting inline repetition.

Full pressure-scenario runs go through subagent testing first; escalate to the `evals/` harness only if micro-test results are ambiguous.

## 8. Success Criteria

- SC-1: A subagent spawned without a `ROLE:` header on Codex or Antigravity, or via Claude's `Agent` tool, never invokes an interactive or coordination-only skill and never poses a question to the user — it either executes or reports `BLOCKED`.
- SC-2: In pressure testing, the orchestrator dispatches on a DISPATCH-tagged block at least as reliably as it currently follows other mandatory skill instructions (baseline: existing Red-Flags-table-guarded behaviors), and any inline execution is accompanied by a stated escape-hatch reason.
- SC-3: Across a sample of execution dispatches, Codex is selected first whenever available; Claude is only selected when Codex is unavailable or exhausted, and the substitution is stated.
- SC-4: Across a sample of judgment dispatches, no reviewer shares a provider with its artifact's author unless diversity was explicitly stated as unavailable.
