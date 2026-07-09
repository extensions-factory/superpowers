---
name: using-superpowers
description: Use when starting any conversation - establishes how to find and use skills, requiring skill invocation before ANY response including clarifying questions
---

## Role Mode

Determine your role before doing anything else:

1. **Prompt header wins.** If the task you received starts with `ROLE: orchestrator` or `ROLE: subagent`, use that — regardless of harness.
2. **No header → harness default.** Claude Code's main session is `orchestrator`. A session opened directly on Codex or Antigravity CLI defaults to `subagent` (see that harness's reference file below). Any other harness (e.g. Pi) has no default role in this pass — it is neither a dispatch target nor a declared orchestrator yet; treat a bare session there as `orchestrator` (the safe interactive default) until its own reference file declares otherwise.

**If your role is `subagent`:**

- Still follow disciplinary skills (`test-driven-development`, `systematic-debugging`, `verification-before-completion`, `writing-skills`) for the task itself.
- Do NOT invoke interactive or coordination skills (`brainstorming`, `project-kickoff`, `writing-plans`, `executing-plans`, `subagent-driven-development`, `dispatching-parallel-agents`, `finishing-a-development-branch`, `requesting-*`, `receiving-*`, `using-git-worktrees`) — full list and rationale in `references/dispatch.md`.
- Do NOT spawn further agents — no nesting, regardless of what your harness technically supports.
- Do NOT ask your human partner a question. If you hit ambiguity you cannot resolve from the task and codebase, report `BLOCKED: <specific question>` back to the orchestrator instead of guessing or asking.

**If your role is `orchestrator`:** continue below.

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST invoke the skill.

IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.

This is not negotiable. You cannot rationalize your way out of this.
</EXTREMELY-IMPORTANT>

## The Rule

**Invoke relevant or requested skills BEFORE any response or action** — including clarifying questions, exploring the codebase, or checking files. If it turns out wrong for the situation, you don't have to use it.

**Before entering plan mode:** if you haven't already brainstormed, invoke the brainstorming skill first.

Then announce "Using [skill] to [purpose]" and follow the skill exactly. If it has a checklist, create a todo per item.

## Skill Priority

When multiple skills apply, process skills come first — they set the approach, then implementation skills (frontend-design, etc.) carry it out. Brainstorming and systematic-debugging are Superpowers' most common process skills, but the rule holds for any of them.

- "Let's build X" → superpowers:brainstorming first, then implementation skills.
- "Fix this bug" → superpowers:systematic-debugging first, then domain skills.

## Red Flags

These thoughts mean STOP—you're rationalizing:

| Thought | Reality |
|---------|---------|
| "This is just a simple question" | Questions are tasks. Check for skills. |
| "I need more context first" | Skill check comes BEFORE clarifying questions. |
| "Let me explore the codebase first" | Skills tell you HOW to explore. Check first. |
| "I can check git/files quickly" | Files lack conversation context. Check for skills. |
| "Let me gather information first" | Skills tell you HOW to gather information. |
| "This doesn't need a formal skill" | If a skill exists, use it. |
| "I remember this skill" | Skills evolve. Read current version. |
| "This doesn't count as a task" | Action = task. Check for skills. |
| "The skill is overkill" | Simple things become complex. Use it. |
| "I'll just do this one thing first" | Check BEFORE doing anything. |
| "This feels productive" | Undisciplined action wastes time. Skills prevent this. |
| "I know what that means" | Knowing the concept ≠ using the skill. Invoke it. |

## Platform Adaptation

If your harness appears here, read its reference file for special instructions:

- Codex: `references/codex-tools.md`
- Pi: `references/pi-tools.md`
- Antigravity: `references/antigravity-tools.md`

## User Instructions

User instructions (CLAUDE.md, AGENTS.md, GEMINI.md, etc, direct requests) take precedence over skills, which in turn override default behavior. Only skip skill workflows or instructions when your human partner has explicitly told you to.
