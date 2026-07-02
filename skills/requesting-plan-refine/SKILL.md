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

**3. Dispatch a subagent, filling the template at
[plan-reviewer.md](plan-reviewer.md):**

**Placeholders:**
- `{PLAN_FILE}` - path to the plan
- `{SPEC_FILE}` - path to the spec, or "None — no spec was written for this
  plan" if absent
- `{FINDINGS_FILE}` - `.superpowers/plan-refine/<plan-basename>-findings.md`

**4. Receive the result:** the subagent returns only the findings file path
and a one-line summary — never paste findings text into your own context.

## Next Step

**User Review Gate:**
After the review, Report to User:

> "Review complete and saved to `.superpowers/plan-refine/<plan-basename>-findings.md`."

## Red Flags

**Never:**
- Read the plan yourself and call it a review — the value is a fresh,
  independent read
- Paste the subagent's full findings into your own context — pass the file
  path instead
- Skip dispatching because "the plan looks fine" — that's the planning
  agent's own bias
