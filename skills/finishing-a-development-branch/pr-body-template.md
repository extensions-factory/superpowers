<!-- created by riso-tech -->
# PR Body Template

Every PR created by the finishing-a-development-branch skill (Option 2) uses this body structure. Fill every section from the spec, plan, and actual session results — no placeholders, no invented claims. Scale depth to the change: a small feature may have one-line sections, but every "always" section must be present.

## Template

```markdown
## Summary

[1-3 sentences: what this PR delivers and why — from the spec's Overview
and the plan's Goal. Describe the problem solved, not just what changed.]

## User Stories Delivered

- [x] US-1: <title> — <one-line user-visible outcome>
- [x] US-2: <title> — <one-line user-visible outcome>

[One line per User Story from the spec, using the spec's US-n IDs. If a
story was intentionally deferred, list it unchecked with the reason.]

## Key Changes

- [Bullet list of the main files/modules/APIs created or changed and the
  role of each — from the plan's Expected Outcome → Artifacts.]

## Design Docs

- Spec: `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
- Plan: `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`

## Testing

- Test suite: `<exact command>` — PASS (<N> tests)
- US Checkpoints:
  - US-1: `<checkpoint command/action>` — <observed result>
  - US-2: `<checkpoint command/action>` — <observed result>

[Report what was actually run in this session with real results. Never
claim a test passed that was not run.]

## Notes for Reviewers

[OPTIONAL — breaking changes, migration steps, suggested review order,
known limitations. Omit the section if there is nothing to note.]
```

## Section rules

**Always present:** Summary, User Stories Delivered, Key Changes, Design Docs, Testing.

**Optional:** Notes for Reviewers — omit when empty rather than writing "N/A".

**Traceability:** US IDs reuse the spec's User Story IDs — the same chain as spec → plan → roadmap. Every checked story must have a corresponding Testing checkpoint line.

**Honesty:** The Testing section reports only commands actually run and results actually observed in this session. If tests were skipped or a checkpoint could not be exercised, say so explicitly.

**No spec/plan in context:** If the work has no spec/plan docs (e.g. a quick fix outside the brainstorming flow), drop the Design Docs section and describe stories as plain outcomes — keep the rest of the structure.
<!-- end created by riso-tech -->
