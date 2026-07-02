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

Discovery → Setup → Scaffold spec → Handoff. Each phase is defined below. **Do not skip or reorder phases.** Discovery gates everything after it.

## Phase 1 — Discovery (gates everything)

1. **Idea capture** — ask exactly one question: "What are you building, in a sentence?" Use the answer to seed research and later stack questions. Do not persist it as a vision doc.

2. **Research fan-out** — dispatch parallel research subagents with `superpowers:dispatching-parallel-agents` (use the `deep-research` skill where a deep multi-source pass fits). Four independent investigations, no shared state:
   - Similar/competing products
   - Market size & potential
   - Risks (technical, legal, adoption)
   - Differentiation opportunities

3. **Synthesize, present, commit** — synthesize findings into `docs/superpowers/specs/YYYY-MM-DD-<topic>-discovery.md` (similar products + comparison, potential assessment, risks, differentiation). Present it to your human partner, then commit it before moving on.

**This phase gates the rest.** Do not start Setup until the discovery doc is written and committed — even if the human "already knows the space." The research grounds the stack decision and the later `brainstorming` session.

## Phase 2 — Setup

Ask questions **one at a time**, multiple-choice where possible (same discipline as `brainstorming`), informed by the discovery doc.

1. **Stack** — language, framework/library, package manager, test runner.
2. **Standards** — formatter/linter, naming conventions, commit convention, test-file convention.
3. **AI tools** — multi-select: "Which AI coding tools do you use?" (Claude Code, Codex, Gemini CLI, Copilot, other/none). This drives which per-tool instruction files the scaffold spec will create.
4. **Bootstrap the repo** — `git init` (if not already a repo) and make an empty initial commit. This is the one piece of bootstrapping nothing downstream can do for itself.

## Phase 3 — Scaffold spec

Write `docs/superpowers/specs/YYYY-MM-DD-<topic>-scaffold-design.md` using the standard `brainstorming` spec format and self-review, scoped to tooling not features. Express all concrete scaffolding as **tasks for the plan** (do NOT run them here):

- Run the stack's **official init command** (ecosystem-native: `npm create …`, `cargo new`, `uv init`, `go mod init`, …) and install the chosen lint/format/test tooling. See `references/stack-init-commands.md`.
- Write `CONSTITUTION.md` — the single canonical source of truth for the Phase 2 standards answers.
- Write **thin per-tool instruction files** for each selected AI tool (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, …), each a pointer ("See `CONSTITUTION.md` for this project's coding standards") plus any genuinely tool-specific config. Follows `docs/superpowers/specs/2026-05-05-platform-neutral-config-refs-design.md`.
- Write enforceable config (`.eslintrc`/`.prettierrc`/`pyproject.toml`/…) matching the constitution.
- Write a minimal CI stub (lint + test) for the developer's git host. See `references/ci-stub-templates.md`.
- Walking-skeleton verification: run build/dev/test and the linter once; confirm a green baseline before the branch is finished.

For projects that use a product roadmap, add roadmap entries for the discovery and scaffold specs. (Skip if the project has no roadmap.)

## Phase 4 — Handoff

Invoke `superpowers:writing-plans` on the scaffold spec. From there the existing pipeline runs unmodified. After the scaffold branch is finished, `superpowers:brainstorming` designs the first real feature — now against a tested repo with market context in hand.

**This is the terminal state.** Do NOT invoke any other implementation skill; `writing-plans` is the next step.

## Red Flags

| Situation | Rule |
|---|---|
| Directory isn't actually empty (unrelated files present) | Stop and ask before `git init` / init commands — don't silently treat a non-empty dir as greenfield. |
| Idea-capture answer describes a feature for an *existing* project | Stop — not greenfield. Redirect to `superpowers:brainstorming`. |
| "I already know the space, skip the research" | Discovery gates everything. Run the research fan-out anyway — it grounds the stack decision and later brainstorming. |
| Stack init command fails (registry error, tool not installed) | Surface the failure; don't hand-write files faking what the tool would have produced. |
| Unknown stack/tool combo with no known init command | Ask the user for the exact command rather than guessing. |
| "It's a toy project, skip the CI stub / verification" | The scaffold spec still lists the CI stub and walking-skeleton verification. A green baseline is the point of kickoff. |
| Walking-skeleton verification fails | Do not finish the branch or hand off to `brainstorming` with a broken baseline. |
| Tempted to run init/lint/CI commands here | Don't. Concrete scaffolding is plan tasks (Phase 3), executed by the pipeline — not by this skill. |
