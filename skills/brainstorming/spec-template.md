<!-- created by riso-tech -->
# Spec Document Template

Every spec written by the brainstorming skill follows this structure. The structure is fixed; the depth is not. Scale each section to the project's complexity — for a truly simple project the "always" sections can each be a few lines, and "scale to fit" sections may shrink to a sentence or be omitted when genuinely not applicable. Never omit an "always" section.

Do not leave placeholders ("TBD", "TODO") anywhere. If something is unknown, either resolve it with your human partner during brainstorming or state it as an explicit assumption in section 2.

## Template

```markdown
---
title: <Feature name>
date: YYYY-MM-DD
status: draft
---

# <Feature name> — Design Spec

## 1. Overview

<Problem being solved, who it's for, and the outcome. One short paragraph.>

## 2. Context & Assumptions

<Current state of the system, constraints, and assumptions made.
No open questions — resolve them or convert each into an explicit assumption.>

## 3. Scope

### Goals

- <bullet list>

### Non-Goals

- <what we deliberately won't do, and why>

## 4. User Stories

### US-1: <title> (Priority: P1)

As a <user>, I want <capability>, so that <benefit>.

**Acceptance criteria:**

- GIVEN <state> WHEN <action> THEN <outcome>

## 5. Approach

<Chosen approach in a few sentences, with the reasoning.>

### Alternatives considered

| Option | Why rejected |
|--------|--------------|
| <option> | <reason> |

## 6. Design

### Architecture

<Components and how they connect. Include a diagram if it helps.>

### Components & Interfaces

<Per unit: what it does, how it's used, what it depends on.>

### Data Model & Flow

### Error Handling

### Edge Cases

## 7. Testing Strategy

<How each user story's acceptance criteria will be verified; test levels and locations.>

## 8. Success Criteria

- SC-1: <measurable, observable outcome>
```

## Section rules

**Always present:** 1 Overview, 3 Scope, 4 User Stories, 5 Approach, 7 Testing Strategy, 8 Success Criteria.

**Scale to fit:** 2 Context & Assumptions and the subsections of 6 Design. Omit a Design subsection only when it is genuinely not applicable (e.g. no data model in a pure refactor) — never because it was skipped.

**Sections 1–4 describe WHAT and WHY; sections 5–6 describe HOW.** Keep implementation detail (tech stack, code structure) out of 1–4.

**User Stories (section 4):**

- Each story must be independently testable — implementing just one should still yield something viable.
- Number stories `US-1`, `US-2`, … and give each a priority (P1 = must have, P2 = should have, P3 = nice to have).
- Acceptance criteria use GIVEN/WHEN/THEN form.
- Story IDs feed the roadmap: each `US-n` becomes a roadmap entry whose `<us-slug>` derives from the story title.

**Approach (section 5):** Record the alternatives explored during brainstorming and why each was rejected. This preserves the decision, not just the design.

**Success Criteria (section 8):** Measurable, observable outcomes for the feature as a whole — distinct from per-story acceptance criteria. Number them `SC-1`, `SC-2`, …
<!-- end created by riso-tech -->
