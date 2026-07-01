# Plan-Refine Split Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the mandatory `refining-plans` hand-off after `writing-plans` with an optional `requesting-plan-refine` / `receiving-plan-refine` review loop, matching the existing `requesting-code-review` / `receiving-code-review` pattern.

**Architecture:** Two prose edits to `writing-plans/SKILL.md` (the US-audit cross-reference line, and the "Refine Handoff" section becomes an "Execution Handoff" section offering Refine-or-Execute), two new skill folders (`requesting-plan-refine/` with a `SKILL.md` + `plan-reviewer.md` template; `receiving-plan-refine/` with a `SKILL.md`), and deletion of `skills/refining-plans/`.

**Tech Stack:** Markdown skill files. No code, no automated test suite for these files.

**Spec:** `docs/superpowers/specs/2026-07-01-plan-refine-split-design.md` — read it before starting. Decisions already settled there: findings are scratch artifacts (`.superpowers/plan-refine/`, not committed), the US vertical-slice audit is preserved as one review criterion, no HTML companion or roadmap entry for the findings file, and light (not full pressure-test) verification is sufficient since this is a workflow-shape change, not a discipline-enforcing rule.

**These are behavior-shaping prose files, not code.** There are no unit tests for them. Each task's verification steps are exact `grep`/`cat` checks that the edit landed as written.

## Global Constraints

- Skill frontmatter `name` must use only letters, numbers, and hyphens.
- Skill frontmatter `description` starts with "Use when..." / "Use after...", states triggering conditions only — never a workflow summary (per `writing-skills` SDO rules).
- Cross-references to other skills use the `**REQUIRED SUB-SKILL:** Use superpowers:<name>` marker, never `@`-links.
- The plan-refine scratch workspace is `.superpowers/plan-refine/`, created with a self-ignoring `.gitignore` (same mechanism as `subagent-driven-development/scripts/sdd-workspace`), so it works regardless of the host project's own `.gitignore`.

---

### Task 1: Update `writing-plans/SKILL.md` — US cross-reference and Execution Handoff

**Files:**
- Modify: `skills/writing-plans/SKILL.md`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: the handoff phrasing that Task 2's `requesting-plan-refine` and Task 3's `receiving-plan-refine` are invoked from (`superpowers:requesting-plan-refine`), and the execution-mode choice text (`superpowers:subagent-driven-development` / `superpowers:executing-plans`) that Task 3 must reproduce verbatim at its own terminal step.

- [ ] **Step 1: Update the US-audit cross-reference.** In the "Organize Tasks Under User Stories" section, replace:

```
Use `## US-N: [feature name]` headings, with that US's `### Task N` entries
nested beneath. The `refining-plans` skill audits this slicing after the plan
is written, so getting the US boundaries roughly right here saves a round trip.
```

with:

```
Use `## US-N: [feature name]` headings, with that US's `### Task N` entries
nested beneath. An optional refine pass (`requesting-plan-refine`) can audit
this slicing after the plan is written, so getting the US boundaries roughly
right here saves a round trip.
```

- [ ] **Step 2: Replace the "Refine Handoff" section.** Replace the entire section (from `## Refine Handoff` to the end of the file):

```markdown
## Refine Handoff

After saving the plan, do NOT jump to execution. Hand off to the refining
step, which audits the User Story slicing and gets the human's approval before
any code is written:

**"Plan complete and saved to `docs/superpowers/plans/<filename>.md`. Next I'll refine it into vertical-slice User Stories and get your approval."**

- **REQUIRED SUB-SKILL:** Use superpowers:refining-plans

`refining-plans` is the only skill you invoke after writing-plans. It handles
the execution handoff (subagent-driven vs inline) once the User Stories are
approved.
```

with:

```markdown
## Execution Handoff

After the self-review, do NOT jump to execution. Ask the user to choose:

**"Plan complete and saved to `docs/superpowers/plans/<filename>.md`. Two options:**

**1. Refine** — get an independent review pass (gaps, ambiguity, User Story slicing) before execution

**2. Execute** — go straight to execution

**Which would you like?"**

**If Refine chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:requesting-plan-refine

**If Execute chosen**, ask which execution mode:

**"Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?"**

- If Subagent-Driven chosen: **REQUIRED SUB-SKILL:** Use superpowers:subagent-driven-development
- If Inline Execution chosen: **REQUIRED SUB-SKILL:** Use superpowers:executing-plans
```

- [ ] **Step 3: Verify the edit landed**

Run: `grep -c "refining-plans" skills/writing-plans/SKILL.md || echo ABSENT`
Expected: `ABSENT`

Run: `grep -n "## Execution Handoff\|requesting-plan-refine\|subagent-driven-development\|executing-plans" skills/writing-plans/SKILL.md`
Expected: `## Execution Handoff` heading present, `superpowers:requesting-plan-refine`, `superpowers:subagent-driven-development`, and `superpowers:executing-plans` all present.

- [ ] **Step 4: Commit**

```bash
git add skills/writing-plans/SKILL.md
git commit -m "writing-plans: make refine optional, hand off to requesting-plan-refine"
```

---

### Task 2: Create the `requesting-plan-refine` skill

**Files:**
- Create: `skills/requesting-plan-refine/SKILL.md`
- Create: `skills/requesting-plan-refine/plan-reviewer.md`

**Interfaces:**
- Consumes: invoked via `superpowers:requesting-plan-refine` (Task 1's handoff phrasing).
- Produces: a findings file at `.superpowers/plan-refine/<plan-basename>-findings.md`; hands off to `superpowers:receiving-plan-refine` (Task 3 consumes this handoff and the findings-file path convention).

- [ ] **Step 1: Write `skills/requesting-plan-refine/SKILL.md`**

```markdown
---
name: requesting-plan-refine
description: Use after writing-plans, when the user chooses to get an independent review pass on the plan before execution
---

# Requesting Plan Refine

Dispatch a fresh, context-free subagent to review a written implementation
plan before execution — surfacing gaps, ambiguity, and structural issues the
planning agent may not see in its own work.

**Core principle:** A plan is safest to execute after someone other than its
author has read it critically.

**Announce at start:** "I'm using the requesting-plan-refine skill to get an
independent review of the plan."

## When to Use

Invoked when the user picks "Refine" at the `writing-plans` handoff, or again
when `receiving-plan-refine`'s loop continues. Optional — skip when the user
chooses to execute directly.

## How to Request

**1. Locate the plan (and spec, if any):**

```bash
PLAN_FILE=docs/superpowers/plans/<filename>.md
SPEC_FILE=docs/superpowers/specs/<filename>-design.md   # if one exists
```

**2. Prepare the scratch workspace:**

```bash
root=$(git rev-parse --show-toplevel)
dir="$root/.superpowers/plan-refine"
mkdir -p "$dir"
printf '*\n' > "$dir/.gitignore"
```

**3. Dispatch a `general-purpose` subagent, filling the template at
[plan-reviewer.md](plan-reviewer.md):**

**Placeholders:**
- `{PLAN_FILE}` - path to the plan
- `{SPEC_FILE}` - path to the spec, or "None — no spec was written for this
  plan" if absent
- `{FINDINGS_FILE}` - `.superpowers/plan-refine/<plan-basename>-findings.md`

**4. Receive the result:** the subagent returns only the findings file path
and a one-line summary — never paste findings text into your own context.

## Next Step

Hand off to `superpowers:receiving-plan-refine` with the findings file path.

- **REQUIRED SUB-SKILL:** Use superpowers:receiving-plan-refine

## Red Flags

**Never:**
- Read the plan yourself and call it a review — the value is a fresh,
  independent read
- Paste the subagent's full findings into your own context — pass the file
  path instead
- Skip dispatching because "the plan looks fine" — that's the planning
  agent's own bias

## Integration

**Required workflow skills:**
- **superpowers:writing-plans** - Creates the plan this skill reviews
- **superpowers:receiving-plan-refine** - Consumes this skill's findings file
```

- [ ] **Step 2: Write `skills/requesting-plan-refine/plan-reviewer.md`**

````markdown
# Plan Reviewer Prompt Template

Use this template when dispatching a plan reviewer subagent.

**Purpose:** Review a written implementation plan for gaps, ambiguity, and
structural issues before it's executed — catching problems while they're
still cheap to fix.

```
Subagent (general-purpose):
  description: "Review implementation plan for gaps and ambiguity"
  prompt: |
    You are a Senior Engineer reviewing an implementation plan before anyone
    starts executing it. Your job is to find what's missing, unclear, or
    structurally wrong — not to implement anything.

    ## Plan to Review

    Read: {PLAN_FILE}

    ## Spec / Requirements

    {SPEC_FILE}

    ## Read-Only Review

    Do not edit the plan, the spec, or any other file. Do not run
    implementation code. This is a read-only review of a document.

    ## What to Check

    **Spec coverage** (skip if no spec was provided):
    - Does every requirement in the spec map to at least one task in the plan?
    - List any spec requirement with no corresponding task.

    **Placeholders and ambiguity:**
    - Any "TBD", "TODO", "implement later", "handle edge cases", "add
      appropriate error handling", or similar non-instructions?
    - Any step that describes what to do without showing how (missing code
      in a code step)?
    - Any requirement that could reasonably be read two different ways?

    **Cross-task consistency:**
    - Do types, function/method names, and signatures used in later tasks
      match what earlier tasks defined? (e.g. `clearLayers()` in Task 3 but
      `clearFullLayers()` in Task 7 is a bug.)
    - Does every task reference only types/functions defined in some task
      (not invented mid-air)?

    **User Story vertical-slice audit:**
    - Is every `## US-N` heading one feature, not several unrelated
      capabilities mixed together? (Feature-mixed — flag it, e.g. "US: login
      + profile editing" should split.)
    - Is every US usable/testable on its own — i.e. it includes whatever
      data, logic, and UI it needs end-to-end? (Layer-split — flag it, e.g.
      "US-1: data types", "US-2: business logic", "US-3: UI" is three
      technical layers, not features; none is independently usable.)

    ## Calibration

    Categorize findings by actual impact. Not everything is blocking.
    Acknowledge what the plan does well before listing findings — accurate
    praise helps the plan's author trust the rest of the feedback.

    ## Output Format

    Write your full findings to: {FINDINGS_FILE}

    Use this structure in that file:

    ### Strengths
    [What's well-scoped, well-specified? Be specific.]

    ### Findings

    #### Blocking (plan cannot be executed as-is)
    [Missing tasks for spec requirements, undefined types/functions
    referenced later, contradictory instructions]

    #### Should Fix (would cause rework or confusion during execution)
    [Ambiguous steps, layer-split or feature-mixed User Stories, placeholder
    text]

    #### Minor (worth a look, not blocking)
    [Style, small naming inconsistencies]

    For each finding: which task/US it's in, what's wrong, why it matters,
    and a concrete suggestion if the fix isn't obvious.

    ## Your Response

    After writing the file, return ONLY: the findings file path and a
    one-line summary (e.g. "3 blocking, 2 should-fix — see {FINDINGS_FILE}").
    Do not repeat the findings in your response.
```

**Placeholders:**
- `{PLAN_FILE}` - path to the plan being reviewed
- `{SPEC_FILE}` - path to the spec, or a note that none exists
- `{FINDINGS_FILE}` - path the subagent should write findings to
````

- [ ] **Step 3: Verify both files landed**

Run: `test -f skills/requesting-plan-refine/SKILL.md && test -f skills/requesting-plan-refine/plan-reviewer.md && echo BOTH_PRESENT`
Expected: `BOTH_PRESENT`

Run: `grep -n "^name:\|^description:" skills/requesting-plan-refine/SKILL.md`
Expected: `name: requesting-plan-refine` and a `description:` line starting with `Use after`

Run: `grep -c "User Story vertical-slice audit" skills/requesting-plan-refine/plan-reviewer.md`
Expected: `1`

- [ ] **Step 4: Commit**

```bash
git add skills/requesting-plan-refine/
git commit -m "Add requesting-plan-refine skill"
```

---

### Task 3: Create the `receiving-plan-refine` skill

**Files:**
- Create: `skills/receiving-plan-refine/SKILL.md`

**Interfaces:**
- Consumes: the findings-file path handed off from Task 2's `requesting-plan-refine`; reproduces Task 1's execution-mode choice text verbatim at its own terminal step.
- Produces: invocation of `superpowers:subagent-driven-development` / `superpowers:executing-plans` (unchanged, pre-existing skills) or a loop back into `superpowers:requesting-plan-refine`.

- [ ] **Step 1: Write `skills/receiving-plan-refine/SKILL.md`**

```markdown
---
name: receiving-plan-refine
description: Use after requesting-plan-refine, when a plan-refine findings file is ready to evaluate and address
---

# Receiving Plan Refine

## Overview

Evaluate plan-refine findings with the same rigor as code review feedback —
verify before implementing, push back on findings that don't hold up, fix
what does.

**Core principle:** Verify before implementing. Ask before assuming.
Technical correctness over blind acceptance.

**Announce at start:** "I'm using the receiving-plan-refine skill to
evaluate the refine findings."

## The Process

1. **Read** the findings file (path handed off from `requesting-plan-refine`).
2. **For each finding:**
   - Restate what it's claiming, in your own words
   - Verify against the plan, the spec (if any), and the codebase — a
     finding about a "missing task" might be wrong if the task exists under
     a different heading; a finding about a "layer-split US" might be wrong
     if the US is genuinely one feature
   - If it holds up: fix it directly in the plan file
   - If it doesn't: note why in your summary, don't apply it
3. **Regenerate the plan's HTML companion** (per `writing-plans`) since the
   plan changed.
4. **Report and ask:**

> "Findings addressed in `<plan path>`: [N] fixed, [M] declined (with
> reasons). Continue refining, or move to executing?"

- **Refine again** → invoke `superpowers:requesting-plan-refine` for another
  pass.
- **Execute** → present the execution-mode choice:

> "Two execution options: **1. Subagent-Driven (recommended)** — dispatch a
> fresh subagent per task, review between tasks. **2. Inline Execution** —
> execute tasks in this session using executing-plans, batch execution with
> checkpoints. Which approach?"

- If Subagent-Driven: **REQUIRED SUB-SKILL:** Use
  superpowers:subagent-driven-development
- If Inline Execution: **REQUIRED SUB-SKILL:** Use superpowers:executing-plans

## Forbidden Responses

Same as `receiving-code-review`:

**NEVER:** "You're absolutely right!" / "Great point!" / apply a finding
without verifying it first.

## Red Flags

**Never:**
- Apply every finding without checking whether it's actually true of this
  plan
- Silently drop a finding without recording why it was declined
- Skip the continue-refining-or-execute question
- Forget to regenerate the plan's HTML companion after editing

## Integration

**Required workflow skills:**
- **superpowers:requesting-plan-refine** - Produces the findings file this
  skill consumes
- **superpowers:subagent-driven-development** / **superpowers:executing-plans**
  - Terminal execution skills this hands off to
```

- [ ] **Step 2: Verify the file landed**

Run: `grep -n "^name:\|^description:" skills/receiving-plan-refine/SKILL.md`
Expected: `name: receiving-plan-refine` and a `description:` line starting
with `Use after`

Run: `grep -c "Continue refining, or move to executing" skills/receiving-plan-refine/SKILL.md`
Expected: `1`

- [ ] **Step 3: Commit**

```bash
git add skills/receiving-plan-refine/
git commit -m "Add receiving-plan-refine skill"
```

---

### Task 4: Delete `refining-plans` and sweep for dangling references

**Files:**
- Delete: `skills/refining-plans/SKILL.md` (and the now-empty `skills/refining-plans/` directory)

**Interfaces:**
- Consumes: Tasks 1-3 must already be committed (this task's grep sweep checks the whole repo, so it needs the new content in place to pass).
- Produces: nothing further downstream.

- [ ] **Step 1: Delete the skill**

```bash
git rm skills/refining-plans/SKILL.md
```

- [ ] **Step 2: Sweep for dangling references**

Run: `grep -rn "refining-plans" --include="*.md" . || echo CLEAN`
Expected: `CLEAN`

- [ ] **Step 3: Commit**

```bash
git commit -m "Remove refining-plans skill (superseded by requesting/receiving-plan-refine)"
```

## Self-Review Notes

- **Spec coverage:** every Design item in the spec (writing-plans handoff,
  requesting-plan-refine + template, receiving-plan-refine, deletion of
  refining-plans) maps to Task 1-4 above.
- **Placeholder scan:** no TBD/TODO in any task; every step shows the exact
  text to write or replace.
- **Type/name consistency:** `requesting-plan-refine`, `receiving-plan-refine`,
  `{PLAN_FILE}`/`{SPEC_FILE}`/`{FINDINGS_FILE}` placeholders, and the
  `.superpowers/plan-refine/` path are spelled identically across Tasks 1-3.
