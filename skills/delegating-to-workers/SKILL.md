---
name: delegating-to-workers
description: Use when about to dispatch any subagent — implementer, task reviewer, plan reviewer, code reviewer, fixer, or researcher — during plan execution or review, or when work could run on an external coding agent (Codex, Antigravity) instead of an internal subagent
---

<!-- created by riso-tech -->
# Delegating To Workers

## Overview

Every dispatch is routed through one registry, `~/.agents/routing.json`, so
work lands on the right worker and cross-review happens across vendors.

**Core principle:** The registry owns routing; skills own prompts. The
vendor that wrote the code never reviews that code.

**Announce at start:** "I'm using the delegating-to-workers skill to route
this dispatch."

## When to Use

Before any dispatch point in the SDLC skills — and NOT for anything else:

- Use: at the dispatch steps of superpowers:subagent-driven-development,
  superpowers:requesting-plan-refine, superpowers:requesting-code-review,
  superpowers:project-kickoff, superpowers:dispatching-parallel-agents
- Don't use: verification (run tests yourself — superpowers:verification-before-completion),
  arbitration between conflicting reviews (orchestrator's own job), talking
  to your human partner

**If `~/.agents/routing.json` does not exist,** every role resolves to an
internal subagent exactly as the calling skill already describes. Stop here.

## Quick Reference — Roles

| Role key | Dispatch point (skill) |
|---|---|
| `researcher` | project-kickoff research fan-out; parallel investigations |
| `plan-reviewer` | requesting-plan-refine |
| `implementer.mechanical` | subagent-driven-development — cheap-tier tasks |
| `implementer.integration` | subagent-driven-development — standard-tier tasks |
| `implementer.design` | subagent-driven-development — max-tier tasks |
| `fixer` | subagent-driven-development — fix dispatches |
| `task-reviewer` | subagent-driven-development — per-task review |
| `code-reviewer` | requesting-code-review, incl. SDD final whole-branch review |

Implementer subkeys follow the task's `Complexity:` line in the plan, or —
if absent — the Model Selection signals in subagent-driven-development.
For a fixer whose findings are integration- or design-level, use that
implementer role instead.

## Resolving a Dispatch

1. Look up the role key in `roles`.
2. A pinned entry (`"worker": …`) resolves directly; `model` overrides
   `tier`; tier names map through the `tiers` block (`null` model = bridge
   default).
3. `"rule": "cross-vendor"` — read the implementing vendor from your
   progress ledger (for `code-reviewer` on a whole branch: the vendor that
   wrote most of the diff), then take the first worker in `workers`
   declaration order that is `available` and a different vendor.
4. Worker unavailable or dispatch fails → walk the role's `fallback` list
   in order; record each hop and reason in the ledger.
5. All exhausted → implementer/fixer/researcher: internal subagent is an
   acceptable last resort. Reviewer: only if the vendor still differs from
   the implementer's — otherwise stop and tell your human partner. A
   same-vendor review is not a review.

## Dispatching

- `internal-subagent` — dispatch exactly as the calling skill describes,
  with the model from the registry, always stated explicitly.
- Bridge worker (e.g. `codex-plugin-cc`) — **REQUIRED:** follow
  [bridge-dispatch.md](bridge-dispatch.md). Every external prompt carries
  the contract in [worker-contract.md](worker-contract.md).

## Ledger

For every dispatch, record: task ID, role, vendor, profile, model/tier,
bridge job ID, resulting status, review rounds. Step 3 above is only
enforceable if this stays current.

## Red Flags

- Same vendor implementing and reviewing — escalate; never silently accept
- Pasting a worker's report or findings into your context — pass file paths
- Trusting a worker's "tests pass" — verify locally yourself
- Hard-coding a worker or model at a dispatch point — registry only
- Inventing a `--profile` — rotation belongs to the bridge unless the
  registry pins one
<!-- end created by riso-tech -->
