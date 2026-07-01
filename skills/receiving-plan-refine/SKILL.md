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

> "Two execution options: **1. Subagent-Driven (recommended)** - I dispatch a
> fresh subagent per task, review between tasks, fast iteration. **2. Inline
> Execution** - Execute tasks in this session using executing-plans, batch
> execution with checkpoints. Which approach?"

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
