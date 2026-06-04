---
name: corpo-standup-waffle
description: >
  Generate an impromptu standup script (what's done, what's pending, what's
  happening today, who needs to be chased) by reading the user's
  PROJECT.md/journal and enriching with read-only Linear + Slack + GitHub
  lookups. Optimised to maximise perceived activity, foreground dependencies,
  and surface people/teams to "loop in". Strictly output-only — the skill
  never sends, posts, replies, or drafts anything; it returns a script for
  the user to read aloud. Use when the user asks for a standup, status
  update, stand-up waffle, "what have I done / what's pending / what am I
  working on today", blockers update, or asks who they need to chase / loop
  in / sync with.
---

# Corpo Standup Waffle

Reads real status from `docs/work/PROJECT.md` + the latest journal entries, enriches with Linear (tickets/owners) and Slack (who/where to chase), and returns a **spoken-style script** the user reads at standup. Grounded in real data, just spun.

The spin maximises perceived activity and foregrounds dependencies/stakeholders, so a day with little shipped still has plenty to say. **Always honest about facts, never about volume.**

## Hard guardrails (read first)

- **Output-only.** Never send, post, reply, draft, or schedule anything. Do **not** call `slack_send_message`, `slack_send_message_draft`, `slack_schedule_message`, Linear `save_*`, `gh pr create`, etc. Only read/list/search/get.
- The chase-list lines in the script are **talking points**, not messages.
- Never invent ticket IDs, people, channels, or threads. If a fact can't be resolved, mark it `TBC` or trigger an interview stage.
- Treat `catalog-info.yaml` / Backstage / surfbot maps as **hints, not truth** — always corroborate against a live signal (`gh` CODEOWNERS + recent commit/PR authors, or actual Slack activity) before recording an owner/contact.

## Workflow (5 steps)

### Step 1 — Load context

Read in this order, silently:

1. `docs/work/PROJECT.md` — extract: Goal, Current focus, Constraints/decisions, Cross-team/ownership, Heads-ups, Open questions, Blockers, Done (recent), Next, milestones/dates.
2. The most recent 1–2 files in `docs/work/journal/` (sorted by filename = date).

If `docs/work/PROJECT.md` is missing, **stop** and trigger the **Project ambiguous** interview stage. Do not guess project state.

### Step 2 — Pull Linear (read-only)

Resolve the project, then bucket its issues:

```
list_projects { query: <project name from PROJECT.md> }
list_issues   { project: <project id>, limit: 100, includeArchived: false }
```

For each issue, capture: `id`, `title`, `status` (Done / In Progress / In Review / Ready / Backlog / Cancelled), `assignee`, `dueDate`, `cycleId`. For anything `Blocked` or assigned to a non-`me` user, call `get_issue` for the full description and any `blocks`/`blocked-by` links.

Anything **blocked, owned by another team, or stalled** is prime "waiting on…" / "de-risking" material — promote it.

### Step 3 — Identify stakeholders to drag in

Build the chase-list as the union of:

- PROJECT.md **Cross-team / ownership** + **Heads-ups** + **Open questions** owners + **Next** outreach owners.
- Linear assignees of blocking/other-team issues; Linear project members not on our team.

For each stakeholder, resolve **Slack channel** and **named person + outstanding ask** via the **org-map cache first**:

1. Look up team → channel → key people in [`org-map.md`](org-map.md).
2. **On miss or stale** (entry older than 30 days, or lookup failed), discover live and write back. Order:
   - **Service → team:** `gh api repos/<org>/<repo>/contents/catalog-info.yaml` → parse `spec.owner` (strip `group:`).
   - **Verify owner is current:** `gh api repos/<org>/<repo>/contents/CODEOWNERS` for the actual paths, and `gh api repos/<org>/<repo>/commits?path=<file>` for recent authors. If `catalog-info.yaml` disagrees with CODEOWNERS or commit history, **prefer the live signal** and record the discrepancy.
   - **Team → Slack channel:** try `ask-{owner}` first (`slack_search_channels { query: "ask-<owner>" }`), then fall back to a topic search.
   - **People & handles:** `slack_search_users { query: <first name> }`; for confirmed Linear assignees, `get_user`.
   - **Recent activity / outstanding ask:** `slack_search_public { query: "in:#<channel> <topic>" }` then `slack_read_thread` on the most recent matching thread to cite "last touch: replied / no reply since <date>".

If a stakeholder genuinely can't be resolved after one pass, **don't fake it** — convert it into a script line: "Need to identify the right owner for X — will chase via #engineering today." (More waffle, still honest.)

See [`org-map.md`](org-map.md) for the full discovery procedure, entry shape, and seed.

### Step 4 — Generate the waffle

Use [`phrasebook.md`](phrasebook.md) to transform facts → waffle. Section bias:

- **Done / progressed** — small wins spun as substantial; verify before spinning ("decided X" not "shipped X" unless code merged).
- **In flight / de-risking** — foreground unknowns, dependencies, scoping work. Anything Pending/Ready/Blocked in Linear lives here.
- **Today** — bias toward **low-commitment, high-visibility** actions: chase, socialise, scope, de-risk, align, await sign-off. Avoid promising specific ships.
- **Need to loop in / chasing** — one line per stakeholder, with channel + last-touch citation.

If today's intent isn't clear from PROJECT.md "Next" or the latest journal, trigger the **Today's intent** interview stage before generating "Today".

### Step 5 — Output the script (and nothing else)

Return **only** the script below — no preamble, no meta-commentary, no Slack-formatted block, no "would you like me to post this?". The user reads it aloud.

```
Quick update on <project>.

Done / progressed:
- <line>
- <line>

In flight / de-risking:
- <line — name the dependency or unknown>
- <line>

Today:
- <chase / sync / scope / await — low-commitment>
- <line>

Need to loop in / chasing:
- <Team / Person> (#<channel>) — <ask>; last touch: <date / "no reply since <date>" / "TBC">
- <Team / Person> (#<channel>) — <ask>; last touch: <...>
```

After the script, the response ends. Do not offer to send it.

## Interview stages

Pause and ask the user (use `AskQuestion` when available; otherwise ask conversationally) **only when** the skill can't proceed confidently. Ask 1–2 crisp questions per stage. Triggers:

| Trigger | Ask |
|---------|-----|
| **Project ambiguous** — no PROJECT.md, multiple candidates, or Linear has several active projects matching. | Which project is this standup for? (offer the candidates) |
| **Audience / format** — daily standup vs leadership update vs written async; verbosity. | Audience? (daily standup / leadership / async post) — and length preference? |
| **Today's intent** — PROJECT.md "Next" is stale, journal doesn't say, or there's a real shipping plan worth foregrounding honestly. | What (if anything) are you actually planning to touch today? |
| **Unresolved owner/contact** — stakeholder can't be resolved, or catalog vs live signal disagree. | Owner for `<area>` is unclear — `<candidate A>` per catalog, `<candidate B>` per recent commits. Which? |
| **Status ambiguity** — a ticket is "In Progress" but stale (>2 weeks no update), or PROJECT.md and Linear disagree. | How should I characterise `<TICKET-id>`? (in flight / blocked / parked / done) |
| **Sensitivity** — anything the user wants to omit or soft-pedal for this audience. | Anything to leave out or soft-pedal for this audience? |

Record durable answers (confirmed owners, channel ids) back into [`org-map.md`](org-map.md) with `Last verified: <today>` and `Source: user-confirmed`. Keep one-off answers (audience, today's intent) in-session only.

## Org-map cache

[`org-map.md`](org-map.md) holds discovered team → channel → people mappings, dynamically generated from `catalog-info.yaml` + Slack + Linear and verified against live signals. Read it before MCP lookups; refresh stale entries; never present a stale entry as truth. Full procedure and entry shape live in that file.

## What this skill is not

- Not a Slack bot. It never posts.
- Not a status report generator that fabricates progress. Every line maps to a real fact in PROJECT.md / journal / Linear / Slack.
- Not a permanent record. The script is throwaway; the org-map cache is the only durable artefact.

## Related files

- [`phrasebook.md`](phrasebook.md) — corporate lexicon + fact→waffle transformation rules + stalling/stakeholder-drag patterns.
- [`org-map.md`](org-map.md) — team/channel/people cache with discovery + verification procedure.
- [`examples.md`](examples.md) — one worked example from a real PROJECT.md.
