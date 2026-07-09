---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** If working in an isolated worktree, it should have been created via the `superpowers:using-git-worktrees` skill at execution time.

**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
- (User preferences for plan location override this default)

<!-- created by riso-tech -->
**Plan structure:** The plan MUST follow the document skeleton in `skills/writing-plans/plan-template.md` — read it before writing. The structure is fixed; the depth scales to the feature's size.
<!-- end created by riso-tech -->

<!-- created by riso-tech -->
**Human-readable HTML companion:**

- After saving the markdown plan, also generate a standalone HTML version for human readers at the same path with a `.html` extension (e.g. `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.html`).
- The markdown is the source of truth (for LLMs); the HTML is a rendered view for people — self-contained (inline CSS, no external assets) so it opens directly in a browser. Render task checkboxes as a readable checklist.
- Regenerate the HTML whenever the plan changes, and save it alongside the `.md`.
<!-- end created by riso-tech -->

<!-- START SDLC: backlog_refinement_prioritization -->
<!-- DISPATCH: inline | reason=scope assessment needs full spec context, controller decision -->
## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## Organize Tasks Under User Stories

Group the plan's Tasks under **User Story (US)** headings. Each US is one
**complete vertical slice** — a single service/feature that works end-to-end
(data + logic + UI it needs), not a technical layer.

- One US = one feature. Don't mix several features into one US.
- Never slice by layer: `US-1 data types`, `US-2 logic`, `US-3 UI` is wrong —
  none is usable alone. Slice by feature instead.
- A US contains its Tasks; the Tasks keep their bite-sized TDD steps.

Use `## US-N: [feature name]` headings, with that US's `### Task N` entries
nested beneath. An optional refine pass (`requesting-plan-refine`) can audit
this slicing after the plan is written, so getting the US boundaries roughly
right here saves a round trip.

<!-- created by riso-tech -->
- US IDs MUST reuse the spec's User Story IDs — the plan's `US-1` implements
  the spec's `US-1`; do not renumber. Every spec US gets a plan section.
- Close every US section with a `**US-N Checkpoint:**` block: the exact
  command or user action demonstrating that story end-to-end, with expected
  observable output covering each GIVEN/WHEN/THEN acceptance criterion from
  the spec (see `plan-template.md`).

## Foundation Section (Optional)

If some work blocks MORE THAN ONE user story (project scaffold, shared
schema, shared data layer), put it in a `## Foundation` section before the
first US, using the same task format. Setup needed by a single story stays
folded into that story's tasks, per Task Right-Sizing. Omit the section
entirely when nothing qualifies — it is not a setup dumping ground.
<!-- end created by riso-tech -->
<!-- END SDLC: backlog_refinement_prioritization -->

<!-- START SDLC: architecture_design -->
<!-- DISPATCH: inline | reason=file decomposition needs full spec + codebase awareness -->
## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.
<!-- END SDLC: architecture_design -->

<!-- START SDLC: sprint_planning -->
<!-- DISPATCH: inline | reason=task breakdown is core plan-writing work, needs full context -->
## Task Right-Sizing

A task is the smallest unit that carries its own test cycle and is worth a
fresh reviewer's gate. When drawing task boundaries: fold setup,
configuration, scaffolding, and documentation steps into the task whose
deliverable needs them; split only where a reviewer could meaningfully
reject one task while approving its neighbor. Each task ends with an
independently testable deliverable.

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Spec:** `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

## Expected Outcome

After completing this plan, the developer will have:

### Working behavior

- [One bullet per User Story — what a user can concretely do once it
  ships. Prefix with the story ID: "US-1: users can …"]

### Artifacts

- [Key files/modules/APIs created or changed, and the role of each]

### How to see it working

- [Exact command or user flow + observable output demonstrating the whole
  feature end-to-end — distinct from the per-US checkpoints]

## Global Constraints

[The spec's project-wide requirements — version floors, dependency limits,
naming and copy rules, platform requirements — one line each, with exact
values copied verbatim from the spec. Every task's requirements implicitly
include this section.]

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Depends on:** [Task M | Foundation | none]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Interfaces:**
- Consumes: [what this task uses from earlier tasks — exact signatures]
- Produces: [what later tasks rely on — exact function names, parameter
  and return types. A task's implementer sees only their own task; this
  block is how they learn the names and types neighboring tasks use.]

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task

## Remember
- Exact file paths always
- Complete code in every step — if a step changes code, show the code
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits
<!-- END SDLC: sprint_planning -->

<!-- START SDLC: code_review_quality -->
<!-- DISPATCH: role=Plan Reviewer | count=1 | model=High | template=requesting-plan-refine/plan-reviewer.md | note=self-review inline, independent review via requesting-plan-refine -->
## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

<!-- created by riso-tech -->
**4. Template check:** Does the plan follow `skills/writing-plans/plan-template.md`? `**Spec:**` line, Expected Outcome section, `**Depends on:**` on every task, a Checkpoint closing every US section.

**5. Traceability check:** Every spec `US-n` has a matching plan `US-n` section; every US Checkpoint covers that story's GIVEN/WHEN/THEN acceptance criteria; every "Working behavior" bullet in Expected Outcome traces to a US.
<!-- end created by riso-tech -->

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.
<!-- END SDLC: code_review_quality -->

## Execution Handoff

**User Review Gate:**
After the self-review, do NOT jump to execution. Ask the user to choose:

> "Plan complete and saved to `docs/superpowers/plans/<filename>.md`. Two options:

> 1. Refine — get an independent review pass (gaps, ambiguity, User Story slicing) before execution

> 2. Execute — go straight to execution

> Which would you like?"

**If Refine chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:requesting-plan-refine

**If Execute chosen**, ask which execution mode:

**"Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?"**

- If Subagent-Driven chosen: **REQUIRED SUB-SKILL:** Use superpowers:subagent-driven-development
- If Inline Execution chosen: **REQUIRED SUB-SKILL:** Use superpowers:executing-plans
