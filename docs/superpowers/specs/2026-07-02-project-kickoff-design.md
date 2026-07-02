# `project-kickoff` — greenfield entry skill

A new skill that runs *before* `brainstorming` for projects that don't exist yet: it validates the idea through parallel research, sets up the toolchain and repo, and hands a scaffold spec into the existing plan/execute pipeline. It turns "an idea in someone's head" into "a tested, version-controlled skeleton with market context in hand."

## Problem

The current Basic Workflow starts at `brainstorming`, which assumes there is already a project to explore — its first step is "check files, docs, recent commits." For a genuinely greenfield idea there is nothing to check: no repo, no scaffold, no toolchain, no coding standards.

Two concrete gaps make this a real hole, not a cosmetic one:

- **No bootstrap path exists.** `using-git-worktrees` Step 0 runs `git rev-parse --git-dir` and assumes a repo already exists; it has no path for "no git repo at all." `using-git-worktrees` line 201 says "Auto-detect and *run* project setup" — it assumes a setup script already exists. Nothing in the current flow ever *creates* the repo, the toolchain, or that setup script.
- **No validation happens before commitment.** The flow jumps straight from a raw idea to designing its first feature, with no step that asks "do similar products exist, is this worth building, what are the risks?"

So an agent handed a blank directory and "let's build X" either guesses a stack silently and starts writing feature code, or runs `brainstorming` against a void.

## Goals

- Give the workflow a real greenfield entry point that produces a **verified, runnable skeleton** plus a **validation/discovery doc**, then hands off to the existing pipeline.
- Validate the idea (similar products, market potential, risks, differentiation) **before** any scaffolding, so both stack choices and the first `brainstorming` session start grounded in reality.
- Determine stack and coding standards through short, Socratic, one-at-a-time questions — same discipline as `brainstorming`, scoped to tooling not features.
- Produce **one canonical coding-standards doc** (`CONSTITUTION.md`) plus **thin per-tool pointer files** for whichever AI harnesses the developer actually uses — no duplicated, drift-prone standards text.
- **Reuse the existing pipeline** for execution: the scaffold is built by `writing-plans` → `subagent-driven-development`/`executing-plans` → `finishing-a-development-branch`, not by bespoke logic inside the new skill.
- Stay consistent with this repo's constraints: zero bundled dependencies, no shipped project templates, cross-harness neutrality.

## Non-goals

- **No product/feature discovery beyond validation.** The skill validates the *idea* and scaffolds the *vessel*; designing the first feature is still `brainstorming`'s job, run afterward.
- **No bundled starter templates.** The skill runs the ecosystem's own official init tooling (`npm create …`, `cargo new`, `uv init`, …); it does not ship or maintain templates. (This is a deliberate rejection of an alternative — see Approaches.)
- **No new execution/verification/orchestration machinery.** Scaffold execution, per-task review, and completion all reuse existing skills unchanged.
- **No hard go/no-go gate.** The discovery doc informs the human; the skill does not auto-halt an idea (a viability verdict was considered and deferred — see Open questions).
- **No change to any existing skill's internal behavior.** Only a new entry point and a one-line addition to the documented Basic Workflow.

## Trigger

The skill fires when **either** condition holds, decided at the `using-superpowers` skill-check step (the same place that chooses brainstorming vs. systematic-debugging today):

1. **No repo/meaningful code exists** — the working directory is empty, `git rev-parse --git-dir` fails, or only stray non-code files exist (e.g. a lone `.gitignore` or `LICENSE`); **or**
2. **Explicit greenfield language** — the user signals a new-from-scratch project ("new project", "from scratch", "start a new app/tool/service").

If the directory turns out to hold a real existing project, the skill stops and redirects to `brainstorming` — it must not scaffold a new repo on top of one that already exists.

## Design

### Where it sits in the flow

```
project-kickoff
  ├─ Discovery: research fan-out → validation/discovery doc   (gates the rest)
  ├─ Setup:     stack / standards / AI-tool Q&A + git init
  └─ Spec:      writes scaffold spec
      → writing-plans → [requesting/receiving-plan-refine] → subagent-driven-development
        / executing-plans → finishing-a-development-branch
          (executes scaffold: constitution, pointer files, lint/format, CI, walking skeleton)
  → brainstorming (first REAL feature — now with a tested repo AND market context in hand)
```

`project-kickoff` is inserted **before** `brainstorming`; it does not replace it. Everything downstream of `writing-plans` is the existing pipeline, unchanged.

### Phase 1 — Discovery (gates everything)

| Step | What happens | Output |
|---|---|---|
| 1. Idea capture | One question: "What are you building, in a sentence?" Enough context to seed research and stack questions; not persisted as a vision doc. | idea summary (used, not saved) |
| 2. Research fan-out | Dispatch parallel research subagents via `dispatching-parallel-agents` (using `deep-research` where a deep multi-source pass fits): **similar products**, **market/potential**, **risks**, **differentiation opportunities**. Independent, no shared state — textbook parallel work. | raw findings |
| 3. Synthesize + present | Synthesize findings into a validation/discovery doc, present it to the human, commit it. | `docs/superpowers/specs/YYYY-MM-DD-<topic>-discovery.md` |

The discovery doc is dual-purpose: it informs the stack decision in Phase 2 **and** lands as context for the later `brainstorming` session, so feature design starts from the competitive landscape rather than a blank slate.

### Phase 2 — Setup

| Step | What happens | Output |
|---|---|---|
| 4. Stack Q&A | One at a time, multiple-choice where possible, informed by discovery: language, framework/library, package manager, test runner. | concrete stack decision |
| 5. Standards + AI-tool Q&A | One at a time: formatter/linter, naming conventions, commit convention, test-file convention. Plus a multi-select: **which AI coding tools do you use?** (Claude Code, Codex, Gemini CLI, Copilot, other/none). | standards decision + tool list |
| 6. Bootstrap repo | `git init` (if not already a repo) + an empty initial commit. This is the *one* piece of bootstrapping nothing downstream can do for itself. | version-controlled empty repo |

### Phase 3 — Scaffold spec

Step 7 writes a scaffold spec to `docs/superpowers/specs/YYYY-MM-DD-<topic>-scaffold-design.md`, following the standard `brainstorming` spec format and self-review, but scoped to tooling rather than a product feature. Crucially, the concrete scaffolding work is expressed as **tasks for the plan**, not executed inside the skill. The spec's task list covers:

- **Run the stack's official init command** (ecosystem-native, per Approach B) and install the chosen lint/format/test tooling.
- **Write `CONSTITUTION.md`** — the single canonical source of truth capturing all Step 5 standards answers.
- **Write thin per-tool pointer files** — for each selected AI tool, its instruction file (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, …) contains only a pointer ("See `CONSTITUTION.md` for this project's coding standards") plus any genuinely tool-specific bits (e.g. Claude Code hook config). This follows the platform-neutral instruction-file pattern established in `2026-05-05-platform-neutral-config-refs-design.md`, and eliminates drift: standards live in exactly one editable place.
- **Write enforceable config** — `.eslintrc`/`.prettierrc`/`pyproject.toml`/etc. matching the constitution.
- **Write a minimal CI stub** — lint + test, for the developer's git host.
- **Walking-skeleton verification** — run the scaffold's build/dev/test and the linter once; confirm a green baseline before the branch is finished.

### Phase 4 — Handoff

Step 8 invokes `writing-plans` on the scaffold spec. From there the existing pipeline runs unmodified: `writing-plans` → optional `requesting/receiving-plan-refine` → `subagent-driven-development`/`executing-plans` (with `test-driven-development` and `requesting-code-review` applying per-task as they already do) → `finishing-a-development-branch`. When the scaffold branch is finished, `brainstorming` runs for the first real feature.

### Outputs (summary)

- `docs/superpowers/specs/YYYY-MM-DD-<topic>-discovery.md` — validation/discovery doc (similar products, potential, risks, differentiation).
- `docs/superpowers/specs/YYYY-MM-DD-<topic>-scaffold-design.md` — scaffold spec fed to `writing-plans`.
- A version-controlled repo (from Step 6), which the plan then fills out into a tested walking skeleton: chosen stack + deps, green build/test baseline, lint/format configured, `CONSTITUTION.md` + thin per-tool instruction files, CI stub.

### File structure

```
skills/project-kickoff/
  SKILL.md                        # the flow above (Discovery → Setup → Spec → Handoff)
  references/
    stack-init-commands.md        # illustrative ecosystem-native init commands per language
                                  #   (npm create, cargo new, uv init, go mod init, bundle gem…)
                                  #   — anchors, NOT a lookup table to keep current
    ci-stub-templates.md          # minimal CI YAML skeletons (GitHub Actions, GitLab CI) as reference text
```

Both reference files are read-only guidance the agent consults; neither is bundled scaffolding (consistent with Approach B — the agent still runs the ecosystem's own tools).

`SKILL.md` frontmatter description uses the "Use when…" convention from `writing-skills`, e.g.: *"Use when starting a brand-new project with no existing repo or code — before brainstorming, when there's nothing yet to explore."*

## Approaches considered

**Scaffold source (chosen: B — agent-driven, ecosystem-native tools).** The agent runs each stack's own official init CLI, then layers lint/format/test/CI on top. Zero-dependency and always current.
- *A — superpowers-bundled templates:* rejected. Directly conflicts with this repo's zero-dependency policy and creates indefinite cross-language maintenance; would almost certainly be rejected at review.
- *C — questions-only, writes a SETUP.md checklist:* rejected. Produces no working skeleton, only a to-do list.

**Kickoff scope (chosen: thin kickoff + reuse pipeline).** Kickoff does Q&A + `git init` + writes specs; all concrete scaffolding is plan tasks executed by the existing pipeline. An earlier draft that baked run-init/configure-lint/verify/commit directly into the skill was dropped — it duplicated machinery the pipeline already provides.

**Standards materialization (chosen: constitution + thin pointers).** One `CONSTITUTION.md`, thin per-tool pointer files. Full per-tool duplicates were rejected for drift risk.

## Error handling / Red Flags

Following the existing "Red Flags" table convention (e.g. `using-git-worktrees`):

| Situation | Rule |
|---|---|
| Directory isn't actually empty (unrelated files present) | Stop and ask before `git init` / init commands — don't silently treat a non-empty dir as greenfield. |
| Idea-capture answer describes a feature for an *existing* project | Stop — not greenfield. Redirect to `brainstorming` instead of scaffolding over an existing repo. |
| Stack init command fails (registry error, tool not installed) | Surface the failure; don't hand-write files faking what the tool would have produced. |
| Unknown stack/tool combo with no known init command | Ask the user for the exact command rather than guessing one that may not exist. |
| Walking-skeleton verification fails | Do not finish the branch or hand off to `brainstorming` with a broken baseline (same principle as `verification-before-completion`). |

**Always:** verify the trigger condition before acting; ask stack/standards questions one at a time; commit the discovery doc before proceeding to Setup.

## Validation (deferred to implementation via `writing-skills`)

Per `writing-skills`' RED-GREEN-REFACTOR-for-process-docs approach:

- **RED baseline:** fresh agent, empty directory, vague prompt, skill *not* loaded — confirm it does something wrong (guesses a stack, jumps to feature code, or runs brainstorming against a void).
- **GREEN:** same scenario, skill loaded — confirm it runs discovery research, asks stack/standards one at a time, bootstraps the repo, writes both docs, and hands off to `writing-plans`.
- **Rationalization scenarios:** "the dir only has a `.gitignore`, skip the trigger check"; "toy project, skip the CI stub"; "hello-world, skip walking-skeleton verification." Each maps to a Red Flags entry.
- **Cross-harness check:** verify correct per-tool instruction-file names on Claude Code + at least one other harness (Codex/Gemini CLI), per this repo's "test on at least one harness" contribution rule.

## Open questions

- **Viability verdict.** Discovery currently produces an informational doc, not a go/no-go gate. If a hard "proceed / pivot / stop" checkpoint proves valuable, it can be added to Phase 1 Step 3 without disturbing the rest of the flow.
- **Roadmap entries.** `brainstorming` normally adds a roadmap entry per spec, but this repo has no `roadmap.json` yet (only `2026-06-26-product-roadmap-design.md`). For projects that *do* use a roadmap, kickoff should add entries for both the discovery and scaffold specs; for this repo's own contribution, there's nothing to update.

## Contribution note

This is a new skill for superpowers core. Per `CLAUDE.md`, before any PR it must be developed and pressure-tested with `writing-skills`, target the `dev` branch, complete the PR template, and disclose the authoring environment. This spec is the design; it is not itself a PR.
