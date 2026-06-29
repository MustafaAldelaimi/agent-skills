---
name: maintain-work-context
description: >
  Bootstrap and maintain a live project work journal so AI agents stay as
  context-aware as the user. Every logged decision is evidence-based and
  verifiable (links to Linear tickets/comments, GitHub PRs, or Slack
  messages), and the user is briefed on each decision in a short, skimmable
  walkthrough before it is recorded. Use when the user wants to track daily
  tasks, month-long projects, work logs, living documentation, session
  handoff, or asks to set up, read, or update PROJECT.md / work context files.
---

# Maintain Work Context

Keep a **two-layer** work journal agents can read and update:

| Layer | Horizon | File |
|-------|---------|--------|
| **Project context** | ~1 month workflow | `~/Desktop/MV_Dev/docs/work/PROJECT.md` |
| **Daily journal** | Today | `~/Desktop/MV_Dev/docs/work/journal/YYYY-MM-DD.md` |

> **Work-context location (hardcoded).** The work-context tree lives in **one shared directory at `~/Desktop/MV_Dev/docs/work/`** — the developer root that holds every repo — and **never inside a _project_ repo.** A project-local `docs/work/` fragments the journal across repos and leaks personal notes into a project. **Every `docs/work/…` path in this skill and in the related skills (`corpo-standup-waffle`, `claw-work-activity`, `check-cross-project-dependencies`) is shorthand for `~/Desktop/MV_Dev/docs/work/…`.**
>
> **Version it (dedicated private repo).** The work-context root **should be its own dedicated private git repo** (`~/Desktop/MV_Dev/docs/work/.git`), separate from every project repo — this is the one place git *is* wanted, because it makes every overwrite recoverable (`git restore`) and every decision diffable. "Never inside a repo" means never inside a **project** repo; a standalone work-context repo is encouraged. Commit after each update (Phase 3 / Phase 4).
>
> **Migrating a stray in-repo `docs/work/` → canonical: merge, never blind-overwrite.** If a `docs/work/` exists inside a project repo from an older run, **first verify whether `~/Desktop/MV_Dev/docs/work/` already exists by `ls`-ing it directly** — the Glob/search tools are workspace-scoped and will falsely report an out-of-workspace canonical path as absent. If the canonical tree exists, it is **authoritative**: merge file-by-file and delete only the in-repo duplicates — **never `mv`/`cp` a stray over the canonical copy** (a blind overwrite can destroy live history irrecoverably when the root isn't yet a git repo). Only when the canonical tree is genuinely absent may you move the in-repo copy up wholesale.

Agents only know what you put in these files. Mirror the user's Notes-app habit — structured, short, current.

**Team projects.** When the work is shared, `PROJECT.md` is the **team-aware** layer (everyone's workstreams + status, synced from the tracker), while the daily journal stays the **user's personal record**. Two hard requirements:

- **Tracker is the source of truth for status — except code-landed state.** When the project is tracked in Linear, reconcile `PROJECT.md` against Linear at session start (see Phase 2) — do not trust stale files for what is "done". **Caveat: the Linear workflow column lags the merge.** For any "merged / shipped / landed / deployed" claim, the **GitHub PR is authoritative and routinely leads the ticket** — verify with `gh pr view <n> --repo <org>/<repo> --json state,mergedAt` before recording it, rather than inferring "done" (or "not done") from a ticket still showing *In Review*.
- **The user's own contribution must always be distinguishable.** This documentation doubles as the user's professional-development record (a feeder for their brag/recap system), so it is useless if their individual work cannot be told apart from teammates'. Attribute every status/`Done`/team item to its owner, and tag the user's own with **`(me)`**. The daily journal is first-person = the user's work.

### Honest attribution (celebrate the user's work; never claim others')

- **Role-qualified `(me)`.** Tag the user's own items with what they actually did: `(me: authored | reviewed | drove | investigated | coordinated | advised | paired)`. This both celebrates the real contribution and keeps it defensible.
- **Shared work names collaborators + the user's slice:** e.g. `(me: investigated; Jamal: implemented)` or `(me + Aude: decided)`. A teammate's solo work is logged under **their** name — never `(me)`.
- **Attribute from evidence, not memory:** ownership comes from the source of truth (Linear assignee, PR author/reviewer, Slack author). If unclear, tag `(contributed — verify)` rather than claiming it.
- **Capture wins + evidence at the time.** When something is brag-worthy, mark it `[win]` and record, while sources are fresh, `[impact: …]`, `[stakeholders: …]`, `[evidence: <PR/ticket/Slack links>]`. Reconstruction under review pressure is lossy and primary sources decay.
- **Feeder, not a second brag doc.** These role-qualified, evidence-linked `(me)` items are the source material for the user's existing brag/recap system — especially non-code work (discovery, decisions, cross-team, AI-augmented investigation) that PR/ticket scrapers miss. Do not write or duplicate the brag doc here.

## Evidence-based & verifiable (every logged item is checkable)

Everything written into `PROJECT.md` or the journal — decisions, `Done` / `Team status` items, resolved questions, blockers — must be **traceable to a primary source** so a future agent (or reviewer) can verify it without trusting anyone's memory. Attach a link, not a paraphrase.

- **Link the source, by type:**
  - **Linear** — the issue (`https://linear.app/<org>/issue/TEAM-123`) or a specific **comment permalink** when the decision was made in-thread.
  - **GitHub** — the PR (`.../pull/123`), a commit, or a **file-at-line permalink** (`.../blob/<sha>/path#L10`) for code / schema / contract facts.
  - **Slack** — the **message permalink** (`https://<org>.slack.com/archives/<channel>/p<ts>`) for verbal/async decisions and sign-offs.
- **One decision, one anchor.** A decision bullet with no link is a liability: record `[evidence: none — unverified]` so the gap is visible instead of being read as fact. Never quietly promote an unverified claim to a stated fact.
- **Cite the source of truth, not a description of it.** Prefer the ticket / PR / schema over a TechDoc or a summary — docs drift (see `fetch-multiverse-techdocs`). When a doc disagrees with the code/ticket, link the code/ticket.
- **Decisions name who decided + where:** e.g. `Decided X (Jamal, [Slack ↗]); confirmed against [TEAM-123 ↗]`.
- **Quote sparingly, link always.** A one-line quote is fine for colour, but the link is what makes it checkable.

This makes the journal double as an audit trail: the user's brag/recap system can lift any `(me)` item straight into a review with its receipts already attached.

## Keep the user in sync — brief the decision, then log it

Treat the user as **time-poor and context-light relative to you**: they have not read the threads, schemas, or tickets you just did, and they will not wade through a wall of text. Before recording any non-trivial decision, **walk them through it in a glanceable brief and get a quick agree** — never log a decision the user has not signed off.

A decision brief is short and skimmable:

1. **The question** — one line, plain language ("deprecate the old event, or version-bump it?").
2. **The options** — 2–4 bullets, each with its one-line consequence.
3. **The evidence** — a link next to each claim (Linear / PR / Slack), one line each, not a paragraph.
4. **The recommendation** — your pick + the single main reason, stated first and loudest.
5. **The ask** — "sound right?" or a yes/no, so agreeing is effortless.

Rules of thumb:

- **Lead with the answer**, then the why — don't make them read to the bottom for the conclusion.
- **One or two lines per step**, plain language, no jargon without a gloss. Assume they skim.
- **Evidence inline at every step** — a claim they can't click is a claim they must take on faith.
- **Confirm before committing.** Only after the user agrees does it enter `PROJECT.md` / the journal — then log it *with* the same evidence links and tag the user's role `(me: decided | advised | investigated | …)`.
- If the user corrects you, the correction **and its source** is what gets logged.

## When to Apply

- User asks to set up, read, or update work context / live doc / project journal
- Start or end of a meaningful work session in a repo
- User switches focus within a month-long project
- User says "catch up on what I'm working on" or "update the work log"

## Phase 1: Bootstrap (first time)

1. Work-context lives at the hardcoded root `~/Desktop/MV_Dev/docs/work/` (see **Work-context location**), shared across every repo — not the current repo.
2. Create if missing:
   ```
   ~/Desktop/MV_Dev/docs/work/PROJECT.md
   ~/Desktop/MV_Dev/docs/work/journal/
   ```
3. **Make the root a versioned private repo (recommended).** If `~/Desktop/MV_Dev/docs/work/.git` is absent, offer to back the work-context with a **dedicated private git repo** so the journal is recoverable and diffable:
   - New: `git -C ~/Desktop/MV_Dev/docs/work init`, add a `.gitignore` (at minimum `.DS_Store`), commit, then `gh repo create <user>/<name> --private --source ~/Desktop/MV_Dev/docs/work --remote origin --push`.
   - Existing: clone the private repo to `~/Desktop/MV_Dev/docs/work/`.
   This is the one place git *is* wanted (it is **not** a project repo). Without it, an accidental overwrite is unrecoverable — see **Work-context location**.
4. If `PROJECT.md` is empty, scaffold from [templates.md](templates.md) using details from the user or conversation.
5. Offer to add a Cursor rule — see **Phase 5**.

Never create `docs/work/` inside a **project** repository (`node_modules`, `.git`, or any project tree) — it always lives at its own root `~/Desktop/MV_Dev/docs/work/` (which may itself be a dedicated private repo).

## Phase 2: Read Context (session start)

Before non-trivial work, read in order:

1. `docs/work/PROJECT.md` — goal, current focus, constraints, open questions, team status, **Dependencies (cross-project)** if present
2. Journal files in `docs/work/journal/` — sort by filename (date) and read the most recent one or two; use the current session date to identify today's file
3. **Reconcile with the tracker (team projects).** If the project is tracked in Linear, fetch the project's current issues + statuses (Linear MCP `list_issues` / `get_project` for the project) and update `PROJECT.md` (**Current focus**, **Done**, **Next**, **Team status**) to match reality — including teammates' progress. Linear is the source of truth for status; flag drift ("file said X, Linear says Y") rather than silently trusting stale files. Keep each item attributed and the user's own tagged `(me)`.
4. **Reconcile cross-project dependencies (ask-first).** If [`check-cross-project-dependencies`](../check-cross-project-dependencies/) is installed, offer to run it: *"Run a cross-project dependency check now? (audits assumptions in `PROJECT.md` against other Linear projects' tickets — read-only)"*. On **Yes**, invoke it in `ask-first` mode (read-only — the skill never writes), then on the user's consent sync its risk table into `PROJECT.md`'s **Dependencies (cross-project)** section (status, risk, owning project, last-checked). On **No**, skip and continue with files-as-read. The audit catches assumption-language in `Constraints / decisions` / `Open questions` / `Heads-ups` that implicitly relies on work owned by other projects/teams. **Never auto-update `PROJECT.md` without user consent.**

If files are missing, offer Phase 1 bootstrap instead of guessing project state.

Summarize back briefly only when the user asks to "catch up" or context is ambiguous. Otherwise use context silently.

## Phase 3: Update Context (session end or on request)

Update **only what changed**. Keep `PROJECT.md` under ~2 pages.

> Before logging any decision here, run the **Keep the user in sync** brief and get agreement, and attach a primary-source link per **Evidence-based & verifiable**. No unverified or unconfirmed decisions go into the files.

### PROJECT.md — touch these sections

| Section | When to update |
|---------|----------------|
| **Current focus** | Task or priority changed |
| **Constraints / decisions** | A choice was made that future sessions must respect |
| **Open questions** | New unknowns; remove when resolved |
| **Dependencies (cross-project)** | A new upstream commitment surfaced, or an existing one changed status/risk (sync from `check-cross-project-dependencies` report on user Yes) |
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
3. **Commit the work-context repo** if it is git-backed (Phase 1): `git -C ~/Desktop/MV_Dev/docs/work add -A && git commit -m "<one-line summary>"`, and push if a remote exists. This snapshots the session so any later overwrite is recoverable.
4. Tell the user which files were updated (paths only, no need to dump full content)

For cold starts in a new chat, the Cursor rule (Phase 5) should make Phase 2 automatic.

## Phase 5: Cursor Rule (recommended)

Create or update `.cursor/rules/work-context.mdc` with `alwaysApply: true`:

```markdown
---
description: Load live project work context before substantive work
alwaysApply: true
---

# Work context

Work-context lives outside this repo, at the hardcoded shared root. Before non-trivial tasks:
1. Read `~/Desktop/MV_Dev/docs/work/PROJECT.md`
2. Read the most recent one or two files in `~/Desktop/MV_Dev/docs/work/journal/` if they exist

After meaningful progress, decisions, or scope changes:
- Offer to update `PROJECT.md` and today's journal

Keep updates concise. Do not invent project state — ask the user if context files are missing or stale.
```

Because the work-context root is **outside** the repo, this rule must use the absolute `~/Desktop/MV_Dev/docs/work/` path — a bare `docs/work/` would resolve inside the repo and miss it. If the root ever moves, update this path wherever it appears.

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

### check-cross-project-dependencies (audit upstream commitments)

When PROJECT.md cites work owned by **other** Linear projects or teams (events being deprecated elsewhere, an upstream service migration finishing, another team's ticket landing by our launch), invoke [`check-cross-project-dependencies`](../check-cross-project-dependencies/) in `ask-first` mode (Phase 2 step 4 already does this on session start). The skill is strictly read-only and produces a risk table (`satisfied / on-track / at-risk / blocking / untracked`); on user Yes, sync the table into `PROJECT.md`'s **Dependencies (cross-project)** section. **The skill never writes — that update is this skill's job, only with user consent.** Re-run whenever a new decision/constraint cites external work.

## Quality Rules

- **Verifiable over asserted** — every decision / `Done` / status item carries a primary-source link (Linear ticket or comment, GitHub PR/commit/line, or Slack permalink); if none exists, mark `[evidence: none — unverified]` rather than stating it as fact (see **Evidence-based & verifiable**)
- **Brief the user before logging** — walk through every non-trivial decision in a short, evidence-linked, skimmable brief (question → options → evidence → recommendation → ask) and get a quick agree *before* it enters the files (see **Keep the user in sync**)
- **Concise over complete** — future agents skim; bullets beat paragraphs
- **Current over historical** — history lives in dated journals
- **Versioned & recoverable** — the work-context root should be its own dedicated **private git repo**; commit after each update so any overwrite is recoverable (`git restore`). When migrating a stray in-repo `docs/work/`, **merge into the canonical tree, never blind-`mv`/`cp` over it**, and verify the canonical path with a direct `ls` first — the Glob/search tools are workspace-scoped and will misreport an out-of-workspace path as absent
- **Decisions explicit** — "we chose X because Y", not implied from chat
- **Tracker is source of truth for status — except code-landed state** — on team projects, reconcile `PROJECT.md` against Linear at session start; never assume status from memory or stale files. For "merged/shipped/landed" claims, verify against the **GitHub PR** (`gh pr view --json state,mergedAt`), which leads the Linear ticket — never write "merged" off a ticket still showing *In Review*
- **Other teams' work = dependencies, not facts** — anything in `Constraints / decisions` / `Open questions` / `Heads-ups` that depends on tickets/events/services owned by another project or team is tracked as a `## Dependencies (cross-project)` row with its own status, not stated as if already true. Use `check-cross-project-dependencies` to verify and flag drift ("file said deprecated, Linear says unstarted") rather than trusting stale assumption-language ("by launch", "will be deprecated", "source of truth =")
- **Attribute everything; keep the user's work distinguishable** — tag the user's own items `(me: <role>)`; the journal is their personal professional-development record. If individual contribution can't be told apart from teammates', the doc has failed its purpose
- **Never claim teammates' work** — attribute by evidence (Linear assignee / PR author / Slack author); log a teammate's solo work under their name, and for shared work record the user's specific slice and name collaborators
- **Celebrate + evidence wins at the time** — mark brag-worthy items `[win]` with impact / stakeholders / source links while sources are fresh; reconstruction under review pressure is lossy
- **No secrets** — no tokens, passwords, or private credentials in work files
- **No solution prescriptions in journal** — log what happened and what's next, not implementation essays

## Templates

See [templates.md](templates.md) for `PROJECT.md`, daily journal, and end-of-session blocks.
