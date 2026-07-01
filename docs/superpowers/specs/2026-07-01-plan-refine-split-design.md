# Split `refining-plans` into request/receive-plan-refine

Replace the mandatory `refining-plans` gate after `writing-plans` with an optional review-style loop, matching the existing `requesting-code-review` / `receiving-code-review` pattern.

## Problem

`refining-plans` is a hard `REQUIRED SUB-SKILL` invoked unconditionally after every plan. It bundles two different jobs — auditing User Story slicing and gating execution on human approval — into one skill, and it's the only place in the workflow that doesn't follow the request/receive review pattern already established for code. That inconsistency makes it harder to reason about, and it forces a review pass even on plans where one isn't wanted.

## Goals

- Refine becomes optional: after `writing-plans` finishes, the user picks "refine" or "execute" directly — no forced hand-off.
- The refine pass is a fresh, context-free subagent review (like code review), not an audit the planning agent does to itself.
- Findings surface as a file the main agent evaluates and can push back on — not a silent auto-fix.
- The user can loop (refine again) or proceed to execution after each pass.
- The vertical-slice User Story check from `refining-plans` is preserved as one review criterion, not dropped.

## Non-goals

- No change to `subagent-driven-development` or `executing-plans` themselves — only how they're reached.
- No change to the `writing-plans` plan format (User Story headings, task structure) — only its handoff section.
- Findings are scratch artifacts (not committed docs) — no HTML companion, no roadmap entry for this internal review pass.

## Design

### 1. `skills/writing-plans/SKILL.md` — replace the "Refine Handoff" section

After the existing plan self-review, stop and ask:

> "Plan complete and saved to `docs/superpowers/plans/<filename>.md`. Two options: **1. Refine** — get an independent review pass before execution. **2. Execute** — go straight to execution. Which would you like?"

- **Execute** → present the existing execution-mode choice (subagent-driven-development vs executing-plans) directly.
- **Refine** → invoke `superpowers:requesting-plan-refine`.

### 2. New skill: `skills/requesting-plan-refine/`

- `SKILL.md`: announces, dispatches a fresh `general-purpose` subagent using `plan-reviewer.md`, passing the plan file path (and spec path if known). The subagent reads the plan (and codebase as needed) and writes findings to `.superpowers/plan-refine/<plan-basename>-findings.md` (scratch workspace, self-ignoring `.gitignore`, same mechanism as `subagent-driven-development/scripts/sdd-workspace` — so it works regardless of the host project's own `.gitignore`). The subagent returns only the file path + one-line summary, never the findings text itself.
- `plan-reviewer.md`: reviewer prompt template, sibling to `requesting-code-review/code-reviewer.md`, checking:
  - Spec coverage (if a spec is available): can you point to a task for each requirement?
  - Placeholders/ambiguity: "TBD", vague steps, missing code in code-steps
  - Cross-task type/interface consistency (signatures, names used later matching what earlier tasks defined)
  - **User Story vertical-slice audit** (carried over from `refining-plans`): flag layer-split US (data-only / logic-only / UI-only) and feature-mixed US (two unrelated capabilities in one US)
  - Output format: Strengths / Findings (grouped, with file:line-equivalent task references) — no severity theater, just what's missing or unclear and why it matters
- Hands off to `superpowers:receiving-plan-refine`.

### 3. New skill: `skills/receiving-plan-refine/`

- Reads the findings file.
- Applies the `receiving-code-review` response pattern per finding: verify against the plan/spec/codebase before acting, push back (in the report, to the user) on findings that don't hold up rather than implementing them anyway.
- Fixes legitimate issues directly in the plan file (and regenerates the plan's HTML companion, per `writing-plans`' existing rule).
- Ends by asking: "Findings addressed in `<plan path>`. Continue refining, or move to executing?"
  - **Refine again** → loop back to `superpowers:requesting-plan-refine`.
  - **Execute** → present the same execution-mode choice as `writing-plans` (subagent-driven-development vs executing-plans).

### 4. Delete `skills/refining-plans/`

Its content is fully absorbed: the US audit into `plan-reviewer.md`, the approval-gate framing into the optional refine/execute choice, the execution handoff into both new skills' terminal step.

## Verification

Since this is a workflow-shape change to a process skill (not a discipline-enforcing rule like TDD), full pressure-testing per `writing-skills` is not required. Instead:
- Read through the full chain (`writing-plans` → `requesting-plan-refine` → `receiving-plan-refine` → execution skills) and confirm every cross-reference (skill names, file paths, `REQUIRED SUB-SKILL` markers) resolves to something that actually exists.
- `grep -rn "refining-plans"` across the repo returns no hits after the change.
- Plugin infrastructure tests (`tests/`) still pass.
