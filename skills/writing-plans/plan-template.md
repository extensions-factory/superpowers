<!-- created by riso-tech -->
# Implementation Plan Template

Every plan written by the writing-plans skill follows this structure. The structure is fixed; the depth is not — a small feature may have one US and two tasks, but every section marked "always" must be present. The task format, bite-sized TDD steps, and No Placeholders rules in SKILL.md apply unchanged; this template defines the document skeleton around them.

## Template

````markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Spec:** `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

## Expected Outcome

After completing this plan, the developer will have:

### Working behavior

- [One bullet per User Story — what a user can concretely do once it ships.
  Prefix with the story ID: "US-1: users can …"]

### Artifacts

- [Key files/modules/APIs created or changed, and the role of each]

### How to see it working

- [Exact command or user flow + observable output that demonstrates the
  whole feature end-to-end. This is the aggregate proof — distinct from
  the per-US checkpoints below.]

## Global Constraints

[The spec's project-wide requirements — version floors, dependency limits,
naming and copy rules, platform requirements — one line each, with exact
values copied verbatim from the spec. Every task's requirements implicitly
include this section.]

---

## Foundation

[OPTIONAL — include only when some work blocks MORE THAN ONE user story:
project scaffold, shared schema, shared data layer. Setup needed by a
single story stays folded into that story's tasks, per Task Right-Sizing
in SKILL.md. Tasks here use the same task format as below. Omit this
section entirely when nothing qualifies.]

### Task 1: [Component Name]

…same task format as below…

## US-1: [feature name]

[IDs match the spec's User Stories — the plan's US-1 implements the spec's
US-1. Every US in the spec must appear as a section here.]

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

**US-1 Checkpoint:**

Run: [exact command or user action demonstrating this story end-to-end]
Expected: [observable output/behavior — one line per GIVEN/WHEN/THEN
acceptance criterion from the spec's US-1]

## US-2: [feature name]

…same pattern: tasks, then checkpoint…
````

## Section rules

**Always present:** header (with `**Spec:**` line), Expected Outcome, Global Constraints, at least one `## US-n` section, and a Checkpoint closing every US section.

**Optional:** Foundation — only when work blocks more than one user story. Never use it as a "setup dumping ground"; single-story setup folds into that story's tasks.

**Traceability:**

- The `**Spec:**` line points to the spec this plan implements.
- `US-n` section IDs reuse the spec's User Story IDs — do not renumber. Every spec US has a plan section; every plan section traces to a spec US.
- Each US Checkpoint covers that story's GIVEN/WHEN/THEN acceptance criteria from the spec.
- Every "Working behavior" bullet in Expected Outcome traces to a US.

**Dependencies:**

- Every task carries a `**Depends on:**` line naming the tasks (or Foundation) that must complete first, or `none`.
- Tasks with no dependency between them may be dispatched in any order or in parallel by the executing skill.

**Expected Outcome vs Goal vs Checkpoints:** Goal is one sentence; Expected Outcome is the detailed picture of the finished state (behavior + artifacts + aggregate proof); US Checkpoints verify one story each. Don't collapse them into one.
<!-- end created by riso-tech -->
