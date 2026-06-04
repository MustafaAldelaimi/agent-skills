---
name: maintain-work-context
description: >
  Bootstrap and maintain a live project work journal so AI agents stay as
  context-aware as the user. Use when the user wants to track daily tasks,
  month-long projects, work logs, living documentation, session handoff, or
  asks to set up, read, or update PROJECT.md / work context files.
---

# Maintain Work Context

Keep a **two-layer** work journal agents can read and update:

| Layer | Horizon | File |
|-------|---------|--------|
| **Project context** | ~1 month workflow | `docs/work/PROJECT.md` |
| **Daily journal** | Today | `docs/work/journal/YYYY-MM-DD.md` |

Agents only know what you put in these files. Mirror the user's Notes-app habit — structured, short, current.

## When to Apply

- User asks to set up, read, or update work context / live doc / project journal
- Start or end of a meaningful work session in a repo
- User switches focus within a month-long project
- User says "catch up on what I'm working on" or "update the work log"

## Phase 1: Bootstrap (first time in a repo)

1. Confirm the repo root (or the directory the user treats as the project home).
2. Create if missing:
   ```
   docs/work/PROJECT.md
   docs/work/journal/
   ```
3. If `PROJECT.md` is empty, scaffold from [templates.md](templates.md) using details from the user or conversation.
4. Offer to add a Cursor rule — see **Phase 5**.

Do not bootstrap inside `node_modules`, `.git`, or unrelated monorepo packages unless the user specifies that package as the project home.

## Phase 2: Read Context (session start)

Before non-trivial work, read in order:

1. `docs/work/PROJECT.md` — goal, current focus, constraints, open questions
2. Journal files in `docs/work/journal/` — sort by filename (date) and read the most recent one or two; use the current session date to identify today's file

If files are missing, offer Phase 1 bootstrap instead of guessing project state.

Summarize back briefly only when the user asks to "catch up" or context is ambiguous. Otherwise use context silently.

## Phase 3: Update Context (session end or on request)

Update **only what changed**. Keep `PROJECT.md` under ~2 pages.

### PROJECT.md — touch these sections

| Section | When to update |
|---------|----------------|
| **Current focus** | Task or priority changed |
| **Constraints / decisions** | A choice was made that future sessions must respect |
| **Open questions** | New unknowns; remove when resolved |
| **Done (recent)** | Meaningful progress; keep last ~2 weeks, archive older items to journal |
| **Next** | Concrete next actions |

Move stale "Done" bullets into the daily journal when trimming.

### Daily journal — append or create today's file

Use the journal template in [templates.md](templates.md). Capture:

- Planned vs done
- Blockers
- Decisions or discoveries worth remembering
- Links (PRs, tickets, docs)

One file per calendar day. Do not merge days into a single blob.

**Factual source for `## Done` (when `claw-work-activity` is installed):**

- If `docs/work/activity/<today>.md` exists (left by an earlier `claw-work-activity` run today), treat it as the factual source for the journal's `## Done` block. The agent's job becomes narrating + editing, not remembering.
- If the file does not exist, optionally invoke `claw-work-activity` in **`for-journal` mode**. That skill will print the chat report and then show a **Yes/No confirmation prompt** before writing `docs/work/activity/<today>.md`. If the user picks **Yes**, use the resulting file as the factual source. If **No**, proceed with the chat output as feedstock — no file is written, the journal still gets updated.
- Never bypass the confirmation prompt; the user always decides whether the activity artefact lives on disk.

## Phase 4: Handoff Between Agent Sessions

When the user ends a session or says "save context for next time":

1. Update `PROJECT.md` **Current focus** and **Next**
2. Append an **End of session** block to today's journal
3. Tell the user which files were updated (paths only, no need to dump full content)

For cold starts in a new chat, the Cursor rule (Phase 5) should make Phase 2 automatic.

## Phase 5: Cursor Rule (recommended)

Create or update `.cursor/rules/work-context.mdc` with `alwaysApply: true`:

```markdown
---
description: Load live project work context before substantive work
alwaysApply: true
---

# Work context

Before non-trivial tasks:
1. Read `docs/work/PROJECT.md`
2. Read the most recent one or two files in `docs/work/journal/` if they exist

After meaningful progress, decisions, or scope changes:
- Offer to update `PROJECT.md` and today's journal

Keep updates concise. Do not invent project state — ask the user if context files are missing or stale.
```

If the user uses a different path (e.g. `.cursor/work/`), follow their convention and put that path in the rule.

`alwaysApply: true` runs on every task in the repo. If that's too noisy, set `alwaysApply: false` and scope it — accepting that cold-start context loading becomes manual.

## Phase 6: Optional Integrations

Only when the user asks — do not sync by default.

### Linear (month-long project)

If the workflow is tracked in Linear:

1. Find or create a **Project** via Linear MCP (`list_projects`, `save_project`).
2. Add the Linear project URL to `PROJECT.md` → **Links**.
3. Optionally mirror **Next** items as Linear issues (`save_issue`) — tickets are tasks; `PROJECT.md` stays the narrative layer.

### claw-work-activity (factual feed for the journal)

If installed, [`claw-work-activity`](../claw-work-activity/) produces a timestamped activity report from git/GitHub, Linear, and Slack. When invoked in `for-journal` mode during Phase 3, it proposes saving `docs/work/activity/<today>.md` (gated on a Yes/No confirmation prompt). The journal's `## Done` block then narrates that factual file rather than relying on agent recall.

## Quality Rules

- **Concise over complete** — future agents skim; bullets beat paragraphs
- **Current over historical** — history lives in dated journals
- **Decisions explicit** — "we chose X because Y", not implied from chat
- **No secrets** — no tokens, passwords, or private credentials in work files
- **No solution prescriptions in journal** — log what happened and what's next, not implementation essays

## Templates

See [templates.md](templates.md) for `PROJECT.md`, daily journal, and end-of-session blocks.
