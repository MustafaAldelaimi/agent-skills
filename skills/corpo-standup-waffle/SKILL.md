---
name: corpo-standup-waffle
description: >-
  Use whenever the user needs a standup or status update — "standup",
  "stand-up waffle", "status update", "daily status", "what have I done /
  what's pending / what am I working on today", a blockers update, or asks who
  they need to chase / loop in / sync with. Generates an impromptu standup
  script (done / pending / happening today / who to chase) by reading the
  user's PROJECT.md/journal and enriching with read-only Linear + Slack +
  GitHub lookups. Tracks each item through started -> in-flight -> finished
  per-audience (team-standup, leadership-update, async-post) so an item
  already announced to that audience isn't re-announced. Optimised to maximise
  perceived activity, foreground dependencies, and surface people/teams to
  loop in. Strictly output-only — never sends, posts, replies, or drafts
  anything; returns a script for the user to read aloud.
---

# Corpo Standup Waffle

Reads real status from `docs/work/PROJECT.md` + the latest journal entries, enriches with Linear (tickets/owners) and Slack (who/where to chase), and returns a **spoken-style script** the user reads at standup. Grounded in real data, just spun.

The spin maximises perceived activity and foregrounds dependencies/stakeholders, so a day with little shipped still has plenty to say. **Always honest about facts, never about volume.**

> **Work-context location (hardcoded).** `docs/work/` lives at `~/Desktop/MV_Dev/docs/work/` — the developer root shared across every repo, never inside a repo (see `maintain-work-context` › *Work-context location*). Every `docs/work/…` path below — `PROJECT.md`, `journal/`, `activity/`, `standup-log/<audience>/` — is shorthand for `~/Desktop/MV_Dev/docs/work/…`.

## Hard guardrails (read first)

- **Output-only.** Never send, post, reply, draft, or schedule anything. Do **not** call `slack_send_message`, `slack_send_message_draft`, `slack_schedule_message`, Linear `save_*`, `gh pr create`, etc. Only read/list/search/get.
- The chase-list lines in the script are **talking points**, not messages.
- Never invent ticket IDs, people, channels, or threads. If a fact can't be resolved, mark it `TBC` or trigger an interview stage.
- Treat `catalog-info.yaml` / Backstage / surfbot maps as **hints, not truth** — always corroborate against a live signal (`gh` CODEOWNERS + recent commit/PR authors, or actual Slack activity) before recording an owner/contact.

## Workflow (7 steps)

### Step 0 — Audience selection (interview)

Trigger the **Audience selection** interview stage (see table below) if the user hasn't specified an audience. Default = `team-standup`. The audience determines which standup-log subdirectory is read in Step 1 and written in Step 6, so an item said at standup doesn't silence the same item from being said in a future leadership-update (and vice versa).

### Step 1 — Load context

Read in this order, silently:

1. `docs/work/PROJECT.md` — extract: Goal, Current focus, Constraints/decisions, Cross-team/ownership, Heads-ups, Open questions, Blockers, Done (recent), Next, milestones/dates.
2. The most recent 1–2 files in `docs/work/journal/` (sorted by filename = date).
3. `docs/work/activity/<today>.md` if it exists (left by an earlier `claw-work-activity` `for-journal` run today) — treat as factual feedstock for the Done/Progressed section.
4. If `claw-work-activity` is installed and `docs/work/activity/<today>.md` does NOT exist, optionally invoke it in **`for-context` mode** (chat-only, no save prompt) for richer Git/Linear/Slack activity than PROJECT.md/journal alone provides. Use the returned report as Done/Progressed feedstock; do not ask the user to save anything.
5. **Walk back through `docs/work/standup-log/<audience>/*.md` dynamically** (newest first) until every still-active item's full lifecycle is covered. Build `seen_state = {item_id: {state, first_mentioned, last_mentioned}}` from each log's `## Items mentioned` table. See [`standup-log-format.md`](standup-log-format.md) for the file format.

   **Why dynamic, not fixed-window:** an item can sit `in-flight` for weeks (e.g. waiting on a slow upstream). A fixed N-day window would lose its `first_mentioned`, surface it as "new", and re-announce it as `started` to an audience that already heard it. The walk-back length adapts to how stale your active items are.

   **Termination — load one more file IFF none of these hold:**
   - No active items remain in `seen_state` (everything seen so far is `finished`).
   - `date(last file loaded) <= min(item.first_mentioned for item in active)` (every active item's full history is covered).
   - Reached the start of the log directory.
   - Safety cap: **90 days walked back** — warn the user that any item still active at this depth likely needs dropping or escalation; stop and proceed with what we have.

If `docs/work/PROJECT.md` is missing, **stop** and trigger the **Project ambiguous** interview stage. Do not guess project state.

### Step 2 — Pull Linear (read-only)

Resolve the project, then bucket its issues:

```
list_projects { query: <project name from PROJECT.md> }
list_issues   { project: <project id>, limit: 100, includeArchived: false }
```

For each issue, capture: `id`, `title`, `status` (Done / In Progress / In Review / Ready / Backlog / Cancelled), `assignee`, `dueDate`, `cycleId`. For anything `Blocked` or assigned to a non-`me` user, call `get_issue` for the full description and any `blocks`/`blocked-by` links.

Anything **blocked, owned by another team, or stalled** is prime "waiting on…" / "de-risking" material — promote it.

### Step 2.5 — Pull cross-project dependencies (auto, read-only)

Always invoke [`check-cross-project-dependencies`](../check-cross-project-dependencies/) in **`auto` mode**. It returns a read-only risk table for work this project depends on but other projects/teams own. Use its rows as first-class candidates alongside Linear:

- `at-risk` / `blocking` / `untracked` rows → promote into the **In flight / de-risking** section ("waiting on TEAM-200 — owned by <other-team>, not started, due before our deadline") and the **Need to loop in / chasing** section (the owning team becomes a stakeholder with the row's `Suggested next actions` as the ask).
- `on-track` rows → mention only if the standup audience benefits from hearing "upstream is on track"; otherwise omit.
- `satisfied` rows → drop.

Treat each dependency's owning ticket id (or `<other-project>/<dep-slug>` when untracked) as an item identity for the Step 4 tri-state filter, so "still waiting on TEAM-200" doesn't get re-announced as new on day two.

If `check-cross-project-dependencies` isn't installed, skip silently — no `PROJECT.md` damage is done by missing it.

### Step 3 — Identify stakeholders to drag in

Build the chase-list as the union of:

- PROJECT.md **Cross-team / ownership** + **Heads-ups** + **Open questions** owners + **Next** outreach owners.
- Linear assignees of blocking/other-team issues; Linear project members not on our team.
- Owning team(s) of any **`at-risk` / `blocking` / `untracked`** row from Step 2.5's cross-project dependency report.

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

### Step 4 — Generate the waffle (with tri-state filter)

Build a candidate item list from Steps 1–3 (PROJECT.md + journal + activity report + Linear + chase list). For each candidate, look it up in `seen_state` and apply the **tri-state filter** before spinning the line:

| Prior state (in seen_state) | Today's action |
|------------------------------|----------------|
| Not present | Include as `started` (or `finished` if it's a one-shot completed today) |
| `started` | Include as `in-flight` (or `finished` if done today) |
| `in-flight` AND state-change detected | Include in full; highlight the new substance. Promote to `finished` if actually done. |
| `in-flight` AND no state-change detected | **Compress** to one-liner: `Still pending: <topic> — no movement since <last_mentioned_date>.` |
| `finished` | **Drop forever** (this audience has heard it) |

Surviving candidates then go through [`phrasebook.md`](phrasebook.md) to transform facts → waffle. Section bias:

- **Done / progressed** — small wins spun as substantial; verify before spinning ("decided X" not "shipped X" unless code merged). **Check the GitHub PR state for any "merged/shipped" line (`gh pr view --json state,mergedAt`) — not the Linear ticket status, whose workflow column lags the merge and will mis-state reality.**
- **In flight / de-risking** — foreground unknowns, dependencies, scoping work. Anything Pending/Ready/Blocked in Linear lives here.
- **Today** — bias toward **low-commitment, high-visibility** actions: chase, socialise, scope, de-risk, align, await sign-off. Avoid promising specific ships.
- **Need to loop in / chasing** — one line per stakeholder, with channel + last-touch citation.

Each item picked for the script gets queued with its new state (`started`/`in-flight`/`finished`) for the Step 6 log write.

**Item identity (keying):** Linear ticket ID where applicable (`SEA-1824`); else `<team-or-person>/<topic-slug>` for cross-team chases (`WFD/AIP-funding-data`); else a short manual slug for narrative findings (`events-vs-graphql-calibration`). Full keying + state-change-detection rules in [`standup-log-format.md`](standup-log-format.md). If a narrative item's slug is ambiguous, trigger the **Item identity ambiguous** interview stage.

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

After the script, proceed to Step 6. Do not offer to send the script anywhere.

### Step 6 — Propose save (Yes/No)

After printing the script, **always** propose saving the standup log. This is how Step 1's walk-back finds prior mentions; skipping the save defeats the memory mechanism.

```
Save this script + items log to docs/work/standup-log/<audience>/<YYYY-MM-DD>.md?
This is how the next run avoids re-announcing the same items to this audience.

- Yes
- No (script printed, no memory written; tomorrow's run won't know what was said today)
```

On **Yes**: create parent dir if needed, write the file in the format specified in [`standup-log-format.md`](standup-log-format.md) (script verbatim + `## Items mentioned` table with each item's `id`, `state`, `first_mentioned`, `last_mentioned`, `source`). Confirm the path in chat.

On **No**: print a one-line warning (`Skipped — next run won't see today's mentions, may repeat them`) and stop. Never silent-write.

A caller cannot opt out of the save prompt. The prompt is the gate between the script existing in chat and persisting as memory.

## Interview stages

Pause and ask the user (use `AskQuestion` when available; otherwise ask conversationally) **only when** the skill can't proceed confidently. Ask 1–2 crisp questions per stage. Triggers:

| Trigger | Ask |
|---------|-----|
| **Audience selection** — no audience specified. | Audience? Default `team-standup`. Existing audiences (from `docs/work/standup-log/*/`): `<list>`. Or pick a new one (creates a new subdirectory). |
| **Project ambiguous** — no PROJECT.md, multiple candidates, or Linear has several active projects matching. | Which project is this standup for? (offer the candidates) |
| **Today's intent** — PROJECT.md "Next" is stale, journal doesn't say, or there's a real shipping plan worth foregrounding honestly. | What (if anything) are you actually planning to touch today? |
| **Unresolved owner/contact** — stakeholder can't be resolved, or catalog vs live signal disagree. | Owner for `<area>` is unclear — `<candidate A>` per catalog, `<candidate B>` per recent commits. Which? |
| **Status ambiguity** — a ticket is "In Progress" but stale (>2 weeks no update), or PROJECT.md and Linear disagree. | How should I characterise `<TICKET-id>`? (in flight / blocked / parked / done) |
| **Item identity ambiguous** — a narrative finding doesn't have an obvious slug. | Use slug `<proposed>` for this item, or pick another? (slug pins it across days so it can be tracked). |
| **Sensitivity** — anything the user wants to omit or soft-pedal for this audience. | Anything to leave out or soft-pedal for this audience? |
| **Save prompt (mandatory after script)** — see Step 6. | Save to `docs/work/standup-log/<audience>/<today>.md`? (Yes / No with warning) |

Record durable answers (confirmed owners, channel ids) back into [`org-map.md`](org-map.md) with `Last verified: <today>` and `Source: user-confirmed`. Keep one-off answers (audience, today's intent) in-session only.

## Org-map cache

[`org-map.md`](org-map.md) holds discovered team → channel → people mappings, dynamically generated from `catalog-info.yaml` + Slack + Linear and verified against live signals. Read it before MCP lookups; refresh stale entries; never present a stale entry as truth. Full procedure and entry shape live in that file.

## Standup log (audience-tagged memory)

`docs/work/standup-log/<audience>/YYYY-MM-DD.md` — per-audience daily ledger of what's already been said. Written only when the user picks Yes at the Step 6 save prompt; read in Step 1 via the dynamic walk-back.

Audience subdirectories are created on demand. Common ones: `team-standup/`, `leadership-update/`, `async-post/`. Items in `team-standup/` don't suppress mentions in `leadership-update/` and vice versa — each audience has its own memory.

Full file format, item-keying rules, state-change detection rules, and a worked filter example live in [`standup-log-format.md`](standup-log-format.md).

## What this skill is not

- Not a Slack bot. It never posts.
- Not a status report generator that fabricates progress. Every line maps to a real fact in PROJECT.md / journal / activity / Linear / Slack.
- Not a permanent narrative record. Scripts are ephemeral; the standup log and org-map cache are the only durable artefacts the skill produces.

## Related files and skills

Within this skill:

- [`phrasebook.md`](phrasebook.md) — corporate lexicon + fact→waffle transformation rules + stalling/stakeholder-drag patterns.
- [`org-map.md`](org-map.md) — team/channel/people cache with discovery + verification procedure.
- [`standup-log-format.md`](standup-log-format.md) — daily-log file format, item-keying rules, state-change detection rules, tri-state transitions, worked filter example.
- [`examples.md`](examples.md) — worked Day 1 + Day 2 runs against the same project, showing the tri-state filter in action.

Upstream skill (optional, recommended when installed):

- [`claw-work-activity`](../claw-work-activity/) — produces the timestamped activity report this skill consumes in Step 1 (invoked in `for-context` mode → chat-only, no save prompt). Also one input source for state-change detection on `in-flight` items.
- [`check-cross-project-dependencies`](../check-cross-project-dependencies/) — produces the read-only cross-project risk table this skill consumes in Step 2.5 (invoked in `auto` mode → no prompt). At-risk/blocking/untracked rows feed *In flight / de-risking* and *Need to loop in / chasing*.
