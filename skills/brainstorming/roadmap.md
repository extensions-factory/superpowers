<!-- created by riso-tech -->
# Product Roadmap (shared reference)

A per-project roadmap that gives humans a comprehensive view of the product and
its progress, organized in three levels: **Epic → Feature → User Story (US)**.
`brainstorming` adds the User Stories for a feature when its spec is written;
`finishing-a-development-branch` marks them released when the work is integrated.
Humans move stories through the intermediate statuses as work progresses.

Both skills read/write the same two files in the working project:

```
docs/superpowers/
  roadmap.json    # source of truth (LLM reads/writes — precise edits)
  ROADMAP.html    # rendered view for humans (regenerated from roadmap.json)
```

## roadmap.json schema

A flat array of **User Story** entries, keyed by `slug`. Epic and Feature are
grouping fields on each entry — the hierarchy is derived from them, not nested.

```json
[
  {
    "slug": "user-auth--email-signin",
    "epic": "Account & Access",
    "feature": "User authentication",
    "title": "Email + password sign-in",
    "description": "Classic credential login with secure password hashing.",
    "status": "open",
    "spec": "specs/2026-06-26-user-auth-design.md",
    "plan": null,
    "created": "2026-06-26",
    "completed": null
  }
]
```

- `slug` — stable key for the User Story. Suggested form `<feature-topic>--<us-slug>`.
- `epic` — top-level grouping. Becomes a **summary card**.
- `feature` — mid-level grouping. Becomes a **detail section** heading.
- `title` — the User Story title (the linked item text in its section).
- `description` — one-line US summary shown under the title.
- `status` — one of `open`, `dev`, `test`, `ready`, `released` (the five filter
  chips). Set to `open` when the spec is written; `finishing-a-development-branch`
  sets it to `released` on integration. Move through `dev` → `test` → `ready` manually.
- `spec` / `plan` — paths relative to `docs/superpowers/` (or `null` if none yet).
- `created` / `completed` — `YYYY-MM-DD`. `completed` stays `null` until `released`.

## Update rules (idempotent by slug)

1. Read `roadmap.json` if it exists, else start from `[]`.
2. Find the entry whose `slug` matches. If found, **update** it; never append a
   duplicate. If not found, **append** a new entry.
3. Write `roadmap.json` back (2-space indent, entries in file order — newest
   appended last).
4. Regenerate `ROADMAP.html` from the full `roadmap.json` using the template
   described below.
5. Commit both files alongside the spec/plan or the integration commit.

When you can't determine the slug (e.g. at finish time with no spec in context),
ask the user which feature this work corresponds to rather than guessing.

## ROADMAP.html template

The canonical template is **`assets/roadmap.html`** in this plugin (relative to this
skill: `../../assets/roadmap.html`). It is a self-contained, dark,
JetBrains-Space-style page — inline CSS + JS, no external assets — with a sticky
status-filter legend, Epic summary cards, and Feature detail sections. **Do not
invent a different layout; start from that file verbatim and only swap in content.**

The three levels map onto the template like this:

| Level | Renders as |
|-------|-----------|
| **Epic** | a summary `.card` (`<h3>` = epic, the `<li>`s = its features) |
| **Feature** | a detail `<section class="section" data-section>` (`.eyebrow` = its epic, `<h2>` = feature) |
| **User Story** | an `.item` inside that section (title link + `.d` description + status badge) |

To regenerate `docs/superpowers/ROADMAP.html`:

1. **Start from `assets/roadmap.html` verbatim.** Keep the `<style>`, the legend
   `<nav>` (chips: Open / In development / In testing / Ready / Released, plus All),
   and the filter `<script>` exactly as-is.
2. **Hero** — replace the `<h1>` and intro `<p>`s with the project name and a short
   summary.
3. **Summary cards** — one `.card` per distinct `epic` (first-appearance order):
   `<h3>{epic}</h3>` and a `<li>` for each distinct `feature` under that epic.
4. **Detail sections** — one `<section class="section" data-section>` per distinct
   `feature` (first-appearance order). Inside, set `<p class="eyebrow">{epic}</p>`,
   `<h2>{feature}</h2>`, then one `.item` per User-Story entry of that feature:
   ```html
   <div class="item" data-status="{status}">
     <a href="{spec}" class="t">{title}</a>   <!-- plain text, no <a>, if spec is null -->
     <div class="d">{description}</div>
     <span class="badge {status}">{label}</span>
   </div>
   ```
   `{status}` ∈ `open|dev|test|ready|released`; `{label}` is the human label
   (`Open`, `In development`, `In testing`, `Ready`, `Released`). `data-status` and the
   `badge` class MUST use the same `{status}` so the legend filter works.
5. Leave the `id="emptyNote"` block and `<footer>` in place.

Because the template is the single source of truth for styling and behavior, edits to
the look-and-feel go in `assets/roadmap.html`, not here.
<!-- end created by riso-tech -->
