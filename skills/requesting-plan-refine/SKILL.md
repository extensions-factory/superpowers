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

**3. Dispatch the review, filling the template at
[plan-reviewer.md](plan-reviewer.md):**

**Placeholders:**
- `{PLAN_FILE}` - path to the plan
- `{SPEC_FILE}` - path to the spec, or "None — no spec was written for this
  plan" if absent
- `{FINDINGS_FILE}` - `.superpowers/plan-refine/<plan-basename>-findings.md`

<!-- created by riso-tech -->
**Route through the registry.** If `~/.agents/routing.json` exists, resolve
the `plan-reviewer` role via superpowers:delegating-to-workers instead of
defaulting to an internal subagent. The plan's author is usually Claude, so
this role is pinned to an external worker for a genuinely adversarial,
cross-vendor read — an internal Claude subagent shares the author's blind
spots. When it resolves to a bridge worker, follow that skill's
bridge-dispatch protocol: dispatch `/codex:adversarial-review` (read-only by
construction) with focus text naming `{PLAN_FILE}`, `{SPEC_FILE}`, and the
instruction to write findings to `{FINDINGS_FILE}` in the plan-reviewer.md
format. The findings-file path is the only interface `receiving-plan-refine`
needs — it is unchanged. Without `routing.json`, dispatch an internal
context-free subagent exactly as below.
<!-- end created by riso-tech -->


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
