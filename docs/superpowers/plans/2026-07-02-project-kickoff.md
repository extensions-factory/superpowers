# `project-kickoff` Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `project-kickoff` skill — a greenfield entry point that validates an idea via parallel research, sets up repo + toolchain decisions, writes a scaffold spec, and hands off to the existing plan/execute pipeline before `brainstorming` runs.

**Architecture:** A single `skills/project-kickoff/SKILL.md` describing a four-phase flow (Discovery → Setup → Scaffold spec → Handoff), plus two read-only `references/` guidance files. The deliverable is process documentation that shapes agent behavior, so each task is verified with `writing-skills`' subagent pressure-test method — a baseline run *without* the new section (RED: agent behaves wrong) and a run *with* it (GREEN: agent behaves right) — not unit tests. Concrete scaffolding work (init commands, lint, CI, constitution) is deliberately NOT in this skill; it becomes plan tasks generated downstream by `writing-plans`.

**Tech Stack:** Markdown skill docs; subagent dispatch for pressure-testing (via the Task/Agent tooling already used by `writing-skills` and `subagent-driven-development`). No runtime dependencies.

## Global Constraints

- Zero bundled dependencies; no shipped project/starter templates (verbatim repo rule). — `references/` files are illustrative anchors, never copied-in scaffolding.
- Cross-harness neutral: never assume CLAUDE.md is the only instruction file; per-tool instruction files follow the pattern in `docs/superpowers/specs/2026-05-05-platform-neutral-config-refs-design.md`.
- Skill `description` frontmatter uses the "Use when…" convention (from `writing-skills`), describing *when to invoke*, not what it does.
- Skill changes require `writing-skills` development + adversarial pressure testing before any PR (verbatim `CLAUDE.md` rule).
- Contributions target the `dev` branch, not `main` (verbatim `CLAUDE.md` rule).
- Source of truth for scope/behavior: `docs/superpowers/specs/2026-07-02-project-kickoff-design.md`.

---

## US-1: Skill triggers on greenfield and runs Discovery

The skill exists, auto-triggers when there's no repo or the user signals a new-from-scratch project, and its first phase runs parallel research into a committed validation/discovery doc — instead of jumping to feature code or running `brainstorming` against a void. This is the minimum end-to-end slice: a greenfield prompt now produces a discovery doc.

### Task 1: Skill skeleton — frontmatter, announce, trigger, redirect guard

**Files:**
- Create: `skills/project-kickoff/SKILL.md`
- Test (scratch): a subagent pressure-test transcript; not committed

**Interfaces:**
- Produces: the `project-kickoff` skill invocable by name; frontmatter `name: project-kickoff` and a "Use when…" `description`; a Trigger section and a redirect-to-`brainstorming` guard consumed by every later task in this plan.

- [ ] **Step 1: Write the baseline pressure test (RED)**

Dispatch a subagent into an empty temp directory with the prompt: *"let's build a habit-tracking app"* and NO `project-kickoff` skill available. Record its behavior.

Expected baseline failure (documents the gap): it guesses a stack and/or starts writing feature code, or runs `brainstorming` with nothing to explore. Save the transcript to the scratchpad.

- [ ] **Step 2: Write the skill skeleton**

Create `skills/project-kickoff/SKILL.md` with:

```markdown
---
name: project-kickoff
description: Use when starting a brand-new project with no existing repo or code — before brainstorming, when there's nothing yet to explore. Validates the idea, sets up the toolchain, and hands a scaffold spec into the plan/execute pipeline.
---

# Project Kickoff

**Announce at start:** "I'm using the project-kickoff skill to turn this idea into a validated, scaffolded starting point."

## Trigger

Use this skill when **either** holds:

1. **No repo/meaningful code exists** — the directory is empty, `git rev-parse --git-dir` fails, or only stray non-code files exist (a lone `.gitignore`, `LICENSE`); **or**
2. **Explicit greenfield language** — "new project", "from scratch", "start a new app/tool/service".

**Redirect guard:** If the directory holds a real existing project, STOP and use `superpowers:brainstorming` instead. Never scaffold a new repo on top of one that already exists.

## Flow

Discovery → Setup → Scaffold spec → Handoff. Each phase is defined below.
```

- [ ] **Step 3: Write the GREEN pressure test**

Dispatch a fresh subagent with the same empty dir + *"let's build a habit-tracking app"*, this time with `project-kickoff` available. Confirm it announces the skill and enters Discovery rather than writing code.

Expected: PASS — skill triggers, no feature code written.

- [ ] **Step 4: Run the redirect-guard test**

Dispatch a subagent into a directory that already contains a real project (e.g. a populated `package.json` + `src/`), prompt *"add a settings page"*. Confirm the skill's guard redirects to `brainstorming` and does NOT run `git init` or scaffold.

Expected: PASS — redirect fires.

- [ ] **Step 5: Commit**

```bash
git add skills/project-kickoff/SKILL.md
git commit -m "feat(project-kickoff): skill skeleton with trigger and redirect guard"
```

### Task 2: Discovery phase — research fan-out and validation doc

**Files:**
- Modify: `skills/project-kickoff/SKILL.md` (add the Discovery phase section)
- Test (scratch): subagent pressure-test transcript

**Interfaces:**
- Consumes: the Trigger/Flow scaffold from Task 1.
- Produces: a documented Discovery phase whose output is `docs/superpowers/specs/YYYY-MM-DD-<topic>-discovery.md`, consumed as context by US-2 (stack choice) and by the later `brainstorming` session.

- [ ] **Step 1: Write the baseline pressure test (RED)**

Dispatch a subagent with only Task 1's skill (no Discovery section) + a greenfield prompt. Confirm it has no instruction to research the landscape — it goes straight to setup/coding.

Expected baseline: no market/competitor research happens.

- [ ] **Step 2: Add the Discovery phase to SKILL.md**

Append:

```markdown
## Phase 1 — Discovery (gates everything)

1. **Idea capture** — ask exactly one question: "What are you building, in a sentence?" Use the answer to seed research and later stack questions. Do not persist it as a vision doc.

2. **Research fan-out** — dispatch parallel research subagents with `superpowers:dispatching-parallel-agents` (use the `deep-research` skill where a deep multi-source pass fits). Four independent investigations, no shared state:
   - Similar/competing products
   - Market size & potential
   - Risks (technical, legal, adoption)
   - Differentiation opportunities

3. **Synthesize, present, commit** — synthesize findings into `docs/superpowers/specs/YYYY-MM-DD-<topic>-discovery.md` (similar products + comparison, potential assessment, risks, differentiation). Present it to your human partner, then commit it before moving on.

**This phase gates the rest.** Do not start Setup until the discovery doc is written and committed.
```

- [ ] **Step 3: Write the GREEN pressure test**

Dispatch a subagent with the updated skill + a greenfield prompt. Confirm it asks the one idea-capture question, dispatches parallel research, and writes+commits a discovery doc before touching setup.

Expected: PASS — discovery doc exists and is committed before any stack question.

- [ ] **Step 4: Commit**

```bash
git add skills/project-kickoff/SKILL.md
git commit -m "feat(project-kickoff): Discovery phase — research fan-out to validation doc"
```

---

## US-2: Setup phase collects stack, standards, and tools, then bootstraps the repo

After discovery, the skill collects stack + coding-standards + AI-tool decisions through one-at-a-time questions and bootstraps a git repo. This is the slice that turns "validated idea" into "decisions + an initialized repo."

### Task 3: Setup phase — stack / standards / AI-tool Q&A and git init

**Files:**
- Modify: `skills/project-kickoff/SKILL.md` (add the Setup phase section)
- Test (scratch): subagent pressure-test transcript

**Interfaces:**
- Consumes: the discovery doc from Task 2 (informs stack questions).
- Produces: a documented Setup phase yielding a stack decision, a standards decision, a selected-AI-tools list, and a bootstrapped repo — all consumed by US-3's scaffold spec.

- [ ] **Step 1: Write the baseline pressure test (RED)**

Dispatch a subagent with the US-1 skill (no Setup section) past discovery. Confirm it either guesses a stack silently or asks everything in one overwhelming dump.

Expected baseline: no disciplined one-at-a-time stack/standards questioning; no explicit AI-tool question; no clean bootstrap commit.

- [ ] **Step 2: Add the Setup phase to SKILL.md**

Append:

```markdown
## Phase 2 — Setup

Ask questions **one at a time**, multiple-choice where possible (same discipline as `brainstorming`), informed by the discovery doc.

1. **Stack** — language, framework/library, package manager, test runner.
2. **Standards** — formatter/linter, naming conventions, commit convention, test-file convention.
3. **AI tools** — multi-select: "Which AI coding tools do you use?" (Claude Code, Codex, Gemini CLI, Copilot, other/none). This drives which per-tool instruction files the scaffold spec will create.
4. **Bootstrap the repo** — `git init` (if not already a repo) and make an empty initial commit. This is the one piece of bootstrapping nothing downstream can do for itself.
```

- [ ] **Step 3: Write the GREEN pressure test**

Dispatch a subagent through Setup. Confirm: questions come one at a time; the AI-tool multi-select is asked; `git init` + empty commit happen; no stack is guessed silently.

Expected: PASS.

- [ ] **Step 4: Add Setup-related Red Flags**

Append to a `## Red Flags` section (create it if absent):

```markdown
| Situation | Rule |
|---|---|
| Directory isn't actually empty (unrelated files present) | Stop and ask before `git init` / init commands — don't silently treat a non-empty dir as greenfield. |
| Idea-capture answer describes a feature for an *existing* project | Stop — not greenfield. Redirect to `brainstorming`. |
```

- [ ] **Step 5: Commit**

```bash
git add skills/project-kickoff/SKILL.md
git commit -m "feat(project-kickoff): Setup phase — stack/standards/tool Q&A and git bootstrap"
```

---

## US-3: Scaffold spec is written and handed to the pipeline

The skill converts the Setup decisions into a scaffold spec (with all concrete scaffolding expressed as *plan tasks*) and hands off to `writing-plans`. This is the slice that connects kickoff to the existing pipeline and reaches the terminal state.

### Task 4: Scaffold-spec phase and handoff to writing-plans

**Files:**
- Modify: `skills/project-kickoff/SKILL.md` (add Scaffold-spec + Handoff sections)
- Test (scratch): subagent pressure-test transcript

**Interfaces:**
- Consumes: stack/standards/tools decisions from Task 3.
- Produces: `docs/superpowers/specs/YYYY-MM-DD-<topic>-scaffold-design.md` and an explicit invocation of `superpowers:writing-plans` — the terminal state of this skill.

- [ ] **Step 1: Write the baseline pressure test (RED)**

Dispatch a subagent with the US-2 skill (no Scaffold-spec section) past Setup. Confirm it either starts running init/lint commands itself (duplicating the pipeline) or stalls with no handoff.

Expected baseline: no scaffold spec; scaffolding done ad-hoc inside the skill instead of as plan tasks.

- [ ] **Step 2: Add the Scaffold-spec + Handoff phases**

Append:

```markdown
## Phase 3 — Scaffold spec

Write `docs/superpowers/specs/YYYY-MM-DD-<topic>-scaffold-design.md` using the standard `brainstorming` spec format and self-review, scoped to tooling not features. Express all concrete scaffolding as **tasks for the plan** (do NOT run them here):

- Run the stack's **official init command** (ecosystem-native: `npm create …`, `cargo new`, `uv init`, `go mod init`, …) and install the chosen lint/format/test tooling. See `references/stack-init-commands.md`.
- Write `CONSTITUTION.md` — the single canonical source of truth for the Phase 2 standards answers.
- Write **thin per-tool instruction files** for each selected AI tool (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, …), each a pointer ("See `CONSTITUTION.md` for this project's coding standards") plus any genuinely tool-specific config. Follows `2026-05-05-platform-neutral-config-refs-design.md`.
- Write enforceable config (`.eslintrc`/`.prettierrc`/`pyproject.toml`/…) matching the constitution.
- Write a minimal CI stub (lint + test) for the developer's git host. See `references/ci-stub-templates.md`.
- Walking-skeleton verification: run build/dev/test and the linter once; confirm a green baseline before the branch is finished.

For projects that use a product roadmap, add roadmap entries for the discovery and scaffold specs. (Skip if the project has no roadmap.)

## Phase 4 — Handoff

Invoke `superpowers:writing-plans` on the scaffold spec. From there the existing pipeline runs unmodified. After the scaffold branch is finished, `superpowers:brainstorming` designs the first real feature — now against a tested repo with market context in hand.

**This is the terminal state.** Do NOT invoke any other implementation skill; `writing-plans` is the next step.
```

- [ ] **Step 3: Add scaffold-related Red Flags**

Append to the Red Flags table:

```markdown
| Stack init command fails (registry error, tool not installed) | Surface the failure; don't hand-write files faking what the tool would have produced. |
| Unknown stack/tool combo with no known init command | Ask the user for the exact command rather than guessing. |
| Walking-skeleton verification fails | Do not finish the branch or hand off to `brainstorming` with a broken baseline. |
```

- [ ] **Step 4: Write the GREEN pressure test**

Dispatch a subagent past Setup. Confirm it writes a scaffold spec whose tasks include constitution + thin per-tool files + init + lint + CI + walking-skeleton verification, and then invokes `writing-plans` (not any ad-hoc execution).

Expected: PASS — scaffold spec written, `writing-plans` invoked as terminal step.

- [ ] **Step 5: Commit**

```bash
git add skills/project-kickoff/SKILL.md
git commit -m "feat(project-kickoff): Scaffold-spec phase and writing-plans handoff"
```

---

## US-4: Reference files ground the agent's scaffolding choices

Two read-only reference files give the agent concrete anchors for init commands and CI stubs, so it runs real ecosystem tooling instead of inventing commands. Independently useful: the skill references them; a reviewer can accept/reject them on their own.

### Task 5: `stack-init-commands.md` reference

**Files:**
- Create: `skills/project-kickoff/references/stack-init-commands.md`

**Interfaces:**
- Consumes: referenced by SKILL.md Phase 3 (Task 4).
- Produces: an illustrative, explicitly non-exhaustive command anchor list.

- [ ] **Step 1: Write the reference file**

```markdown
# Ecosystem-native init commands (anchors, not a lookup table)

These are illustrative starting points. Prefer the ecosystem's own current
official tool; if a stack isn't here, ask the user for the exact command.

- **Node / TS (Vite app):** `npm create vite@latest <name>`
- **Node library:** `npm init -y` then add the chosen test runner
- **Python:** `uv init <name>` (or `poetry new <name>`)
- **Rust:** `cargo new <name>`
- **Go:** `go mod init <module-path>`
- **Ruby gem:** `bundle gem <name>`

Never ship or copy a bundled template — always run the real tool.
```

- [ ] **Step 2: Verify SKILL.md references it correctly**

Run: `grep -n "stack-init-commands.md" skills/project-kickoff/SKILL.md`
Expected: at least one hit (from Task 4).

- [ ] **Step 3: Commit**

```bash
git add skills/project-kickoff/references/stack-init-commands.md
git commit -m "docs(project-kickoff): stack-init-commands reference"
```

### Task 6: `ci-stub-templates.md` reference

**Files:**
- Create: `skills/project-kickoff/references/ci-stub-templates.md`

**Interfaces:**
- Consumes: referenced by SKILL.md Phase 3 (Task 4).
- Produces: minimal CI skeletons as reference text.

- [ ] **Step 1: Write the reference file**

```markdown
# Minimal CI stubs (lint + test only)

Reference skeletons — adapt to the project's actual commands. Keep them
minimal; the goal is a green baseline, not a full pipeline.

## GitHub Actions — `.github/workflows/ci.yml`
\`\`\`yaml
name: ci
on: [push, pull_request]
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: <install deps>
      - run: <lint command>
      - run: <test command>
\`\`\`

## GitLab CI — `.gitlab-ci.yml`
\`\`\`yaml
check:
  script:
    - <install deps>
    - <lint command>
    - <test command>
\`\`\`
```

- [ ] **Step 2: Verify SKILL.md references it correctly**

Run: `grep -n "ci-stub-templates.md" skills/project-kickoff/SKILL.md`
Expected: at least one hit (from Task 4).

- [ ] **Step 3: Commit**

```bash
git add skills/project-kickoff/references/ci-stub-templates.md
git commit -m "docs(project-kickoff): ci-stub-templates reference"
```

---

## US-5: Skill survives rationalization and works cross-harness

Final hardening: close the loopholes an agent would rationalize its way through, and confirm the skill produces correct per-tool instruction filenames on more than one harness. This is the `writing-skills` REFACTOR pass plus the repo's cross-harness contribution requirement.

### Task 7: Rationalization hardening (REFACTOR)

**Files:**
- Modify: `skills/project-kickoff/SKILL.md`
- Test (scratch): subagent pressure-test transcripts

**Interfaces:**
- Consumes: the full skill from US-1..US-4.
- Produces: a hardened skill whose Red Flags defeat the known rationalizations.

- [ ] **Step 1: Run the rationalization pressure tests (RED)**

Dispatch subagents against the current skill with each tempting shortcut and record which ones slip through:
- *"the dir only has a `.gitignore`, that's basically empty — skip the trigger check"*
- *"it's a toy project, skip the CI stub"*
- *"hello-world, skip walking-skeleton verification"*
- *"I already know the stack, skip discovery research"*

- [ ] **Step 2: Add explicit counters for any that slipped**

For each rationalization that got through, add a Red Flags row or tighten the phase wording so the skill explicitly forbids it (e.g. discovery gates everything; verification is not optional).

- [ ] **Step 3: Re-run the pressure tests (GREEN)**

Re-dispatch the same scenarios. Expected: PASS — every shortcut is now refused.

- [ ] **Step 4: Commit**

```bash
git add skills/project-kickoff/SKILL.md
git commit -m "feat(project-kickoff): harden against rationalized shortcuts"
```

### Task 8: Cross-harness verification and README workflow line

**Files:**
- Modify: `README.md` (add `project-kickoff` to the Basic Workflow as the greenfield entry point)
- Test (scratch): two subagent transcripts (Claude Code + one other harness)

**Interfaces:**
- Consumes: the complete skill.
- Produces: a documented workflow entry and evidence the skill names per-tool instruction files correctly on ≥2 harnesses.

- [ ] **Step 1: Cross-harness pressure test**

Run the GREEN scenario on Claude Code and on one other harness (Codex or Gemini CLI). Confirm the scaffold spec names the correct per-tool instruction file for each (e.g. `CLAUDE.md` vs `AGENTS.md`/`GEMINI.md`), per the platform-neutral pattern.

Expected: PASS on both; correct filenames per harness.

- [ ] **Step 2: Add the workflow line to README**

Insert before the existing step 1 (`brainstorming`) in "The Basic Workflow":

```markdown
0. **project-kickoff** - Activates for brand-new projects with no repo yet. Validates the idea via parallel research (discovery doc), collects stack/standards/tool decisions, initializes the repo, and writes a scaffold spec that flows into writing-plans — before brainstorming designs the first feature.
```

- [ ] **Step 3: Verify README edit**

Run: `grep -n "project-kickoff" README.md`
Expected: the new workflow line is present.

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs: add project-kickoff as greenfield entry to Basic Workflow"
```

---

## Self-Review

**Spec coverage** (against `2026-07-02-project-kickoff-design.md`):
- Trigger (no-repo OR greenfield language) + redirect guard → Task 1. ✅
- Discovery: research fan-out (4 domains) → discovery doc → Task 2. ✅
- Setup: stack/standards/AI-tool Q&A one-at-a-time + git init → Task 3. ✅
- Scaffold spec with constitution + thin per-tool pointer files + init/lint/CI/walking-skeleton as *plan tasks* → Task 4. ✅
- Handoff to `writing-plans` as terminal state → Task 4. ✅
- Reference files (stack-init-commands, ci-stub-templates) → Tasks 5, 6. ✅
- Red Flags (all five spec rows) → distributed across Tasks 3 and 4. ✅
- Validation via `writing-skills` pressure tests incl. rationalization + cross-harness → Tasks 7, 8. ✅
- Zero-dependency / no bundled templates → enforced in Global Constraints and Task 5 wording. ✅

**Placeholder scan:** No "TBD"/"handle edge cases"/"similar to Task N". The `<install deps>` / `<lint command>` tokens inside `ci-stub-templates.md` are intentional fill-ins *in a reference template the agent adapts per project*, not plan placeholders — called out explicitly in that file's prose. ✅

**Type consistency:** Phase names (Discovery/Setup/Scaffold spec/Handoff), file paths (`CONSTITUTION.md`, per-tool instruction files, discovery + scaffold spec paths), and skill names (`dispatching-parallel-agents`, `deep-research`, `writing-plans`, `brainstorming`) are used consistently across all tasks. ✅

## Notes on deviations from the standard plan template

- **Tests are subagent pressure-tests, not unit tests.** The deliverable is behavior-shaping documentation; `writing-skills` is the correct methodology and its RED/GREEN is a with/without-skill subagent comparison. Each task keeps a real, runnable verification (dispatch a subagent, observe behavior, or `grep` a reference).
- **No HTML companion generated.** None of this repo's existing plans/specs ship `.html` companions and there's no `roadmap.json`; matching existing repo practice. Say the word to add the HTML.
