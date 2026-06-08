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

**Team projects.** When the work is shared, `PROJECT.md` is the **team-aware** layer (everyone's workstreams + status, synced from the tracker), while the daily journal stays the **user's personal record**. Two hard requirements:

- **Tracker is the source of truth for status.** When the project is tracked in Linear, reconcile `PROJECT.md` against Linear at session start (see Phase 2) — do not trust stale files for what is "done".
- **The user's own contribution must always be distinguishable.** This documentation doubles as the user's professional-development record (a feeder for their brag/recap system), so it is useless if their individual work cannot be told apart from teammates'. Attribute every status/`Done`/team item to its owner, and tag the user's own with **`(me)`**. The daily journal is first-person = the user's work.

### Honest attribution (celebrate the user's work; never claim others')

- **Role-qualified `(me)`.** Tag the user's own items with what they actually did: `(me: authored | reviewed | drove | investigated | coordinated | advised | paired)`. This both celebrates the real contribution and keeps it defensible.
- **Shared work names collaborators + the user's slice:** e.g. `(me: investigated; Jamal: implemented)` or `(me + Aude: decided)`. A teammate's solo work is logged under **their** name — never `(me)`.
- **Attribute from evidence, not memory:** ownership comes from the source of truth (Linear assignee, PR author/reviewer, Slack author). If unclear, tag `(contributed — verify)` rather than claiming it.
- **Capture wins + evidence at the time.** When something is brag-worthy, mark it `[win]` and record, while sources are fresh, `[impact: …]`, `[stakeholders: …]`, `[evidence: <PR/ticket/Slack links>]`. Reconstruction under review pressure is lossy and primary sources decay.
- **Feeder, not a second brag doc.** These role-qualified, evidence-linked `(me)` items are the source material for the user's existing brag/recap system — especially non-code work (discovery, decisions, cross-team, AI-augmented investigation) that PR/ticket scrapers miss. Do not write or duplicate the brag doc here.

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

1. `docs/work/PROJECT.md` — goal, current focus, constraints, open questions, team status
2. Journal files in `docs/work/journal/` — sort by filename (date) and read the most recent one or two; use the current session date to identify today's file
3. **Reconcile with the tracker (team projects).** If the project is tracked in Linear, fetch the project's current issues + statuses (Linear MCP `list_issues` / `get_project` for the project) and update `PROJECT.md` (**Current focus**, **Done**, **Next**, **Team status**) to match reality — including teammates' progress. Linear is the source of truth for status; flag drift ("file said X, Linear says Y") rather than silently trusting stale files. Keep each item attributed and the user's own tagged `(me)`.

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
| **Team status** | A teammate's (or your) workstream/ticket changed status — sync from Linear |
| **Next** | Concrete next actions |

Move stale "Done" bullets into the daily journal when trimming.

**Attribution (mandatory on team projects).** Every `Done` and `Team status` item names its owner with a role (`(me: authored|reviewed|drove|investigated|coordinated|advised|paired)`); shared work names collaborators and the user's slice. Keep teammates' work and the user's clearly separable so the user's individual contribution is always extractable (e.g. for reviews / brag doc). Mark brag-worthy items `[win]` with `[impact: …]` / `[stakeholders: …]` / `[evidence: …]` captured at the time. The daily journal records the user's own work in the first person, with a `## Wins` lane for brag-worthy items.

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

### Linear (team-tracked projects — status source of truth)

When the project is tracked in Linear, **sync from Linear**, don't just mirror to it:

1. Find the **Project** via Linear MCP (`list_projects` / `get_project`); add its URL to `PROJECT.md` → **Links**.
2. At session start (Phase 2) and when updating, pull current issues + statuses (`list_issues` for the project) and reconcile `PROJECT.md` **Done**, **Next**, **Current focus**, and the **Team status** table. Attribute each item's owner; tag the user's own `(me)`. This is how teammates' progress (e.g. a ticket they closed) enters the context without the user having to relay it.
3. Optionally mirror **Next** items as Linear issues (`save_issue`) — tickets are tasks; `PROJECT.md` stays the narrative layer.

### claw-work-activity (factual feed for the journal)

If installed, [`claw-work-activity`](../claw-work-activity/) produces a timestamped activity report from git/GitHub, Linear, and Slack. When invoked in `for-journal` mode during Phase 3, it proposes saving `docs/work/activity/<today>.md` (gated on a Yes/No confirmation prompt). The journal's `## Done` block then narrates that factual file rather than relying on agent recall.

## Quality Rules

- **Concise over complete** — future agents skim; bullets beat paragraphs
- **Current over historical** — history lives in dated journals
- **Decisions explicit** — "we chose X because Y", not implied from chat
- **Tracker is source of truth for status** — on team projects, reconcile `PROJECT.md` against Linear at session start; never assume status from memory or stale files
- **Attribute everything; keep the user's work distinguishable** — tag the user's own items `(me: <role>)`; the journal is their personal professional-development record. If individual contribution can't be told apart from teammates', the doc has failed its purpose
- **Never claim teammates' work** — attribute by evidence (Linear assignee / PR author / Slack author); log a teammate's solo work under their name, and for shared work record the user's specific slice and name collaborators
- **Celebrate + evidence wins at the time** — mark brag-worthy items `[win]` with impact / stakeholders / source links while sources are fresh; reconstruction under review pressure is lossy
- **No secrets** — no tokens, passwords, or private credentials in work files
- **No solution prescriptions in journal** — log what happened and what's next, not implementation essays

## Templates

See [templates.md](templates.md) for `PROJECT.md`, daily journal, and end-of-session blocks.
