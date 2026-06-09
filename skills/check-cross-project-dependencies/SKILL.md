---
name: check-cross-project-dependencies
description: >
  Read-only audit of a project's dependencies on work owned by OTHER Linear
  projects/teams. Detects them three ways: an explicit `## Dependencies
  (cross-project)` section in PROJECT.md, `blockedBy`/`relatedTo` links on the
  active project's issues that point into other projects, and a scan for latent
  assumption-language in `Constraints / decisions` / `Open questions` /
  `Heads-ups` ("by launch", "will be deprecated", "once X ships", "source of
  truth =", "depends on", references to other teams/services/events). Resolves
  each candidate across all Linear projects, captures owner/team/status/due,
  and risk-assesses vs the active project's deadline (satisfied / on-track /
  at-risk / blocking). Strictly read-only — never writes, sends, posts, or
  saves anything; returns a report the caller decides what to do with. Two
  invocation modes: `ask-first` (caller prompts the user before running) and
  `auto` (caller runs it silently as part of its own workflow). Use when the
  user asks "is anything we depend on at risk", "what other projects gate our
  launch", "are our upstream deps on track", "verify cross-project
  dependencies", or when invoked by `maintain-work-context`,
  `corpo-standup-waffle`, or `claw-work-activity`.
---

# Check Cross-Project Dependencies

Audits assumptions a project makes about work owned by **other Linear projects / teams**, and flags any that are not actually on track. The motivating failure mode: a line like *"by launch, V3 is deprecated and source of truth is X.v0"* sits in `Constraints / decisions` as if it were a fact, but the deprecation is tracked in a different project's tickets that nobody is watching. This skill closes that gap.

Strictly read-only. The caller decides whether to surface, persist, or escalate the findings.

## Hard guardrails (read first)

- **Read-only across every source.** Never call Linear `save_*`, `slack_send_*`, `slack_schedule_message`, `gh pr create` / `gh issue create`, or any other mutating tool. Only `list_*`, `get_*`, `search_*`, and `gh api` reads.
- **No file writes, ever.** The skill returns a report (chat or structured object). It never writes to `PROJECT.md`, the journal, `docs/work/dependencies/*`, or anywhere else. Persistence is the caller's choice.
- **No invented tickets, projects, owners, or statuses.** Every row in the report cites its source (Linear issue id, PROJECT.md line/section, or GitHub `catalog-info.yaml` path). When a candidate can't be resolved to a real ticket, label it `UNTRACKED` rather than guessing.
- **Tracker is the source of truth for status.** When PROJECT.md says one thing and Linear says another, Linear wins and the drift is flagged explicitly in the report (`drift: file said X, Linear says Y`).
- **External projects = other projects you don't own + projects on other teams.** A blocker on a ticket in *our own* active project is not a cross-project dependency — that's normal project management. Filter those out.

## Invocation modes

The caller picks the mode; this skill behaves the same way internally, only the **entry contract** differs.

| Mode | Caller behaviour | Use when |
|------|------------------|----------|
| `ask-first` | Caller prompts the user with a Yes/No (`Run cross-project dependency check now?`) before invoking. On No, caller proceeds without the report. | `maintain-work-context` Phase 2 — running the check on every session start would be noisy; ask once per session. |
| `auto` | Caller invokes silently as part of its own workflow. No prompt. Output is consumed by the caller, not necessarily shown to the user directly. | `corpo-standup-waffle` (always — at-risk deps feed the de-risking/chase sections) and `claw-work-activity` (always when a `PROJECT.md` exists — surfaces a one-line note about moved/at-risk deps). |

Mode detection (in order):

1. Explicit `mode: ask-first | auto` from the caller wins.
2. Caller is `maintain-work-context` → `ask-first`.
3. Caller is `corpo-standup-waffle` or `claw-work-activity` → `auto`.
4. User invokes directly ("check our cross-project deps", "is anything upstream at risk") → run immediately, no prompt; this is the same as `auto` but with the report shown verbatim.

## Workflow (5 steps)

### Step 1 — Load context

Read (in this order, silently):

1. `docs/work/PROJECT.md` — extract: project name, deadline / milestone dates, **Dependencies (cross-project)** if present, **Constraints / decisions**, **Open questions**, **Heads-ups**, **Cross-team / ownership**, **Links** (the active Linear project URL).
2. The most recent 1–2 files in `docs/work/journal/` — recent decisions / blockers may name an external ticket or team.

If `docs/work/PROJECT.md` is missing, return a one-line result (`No PROJECT.md found at docs/work/PROJECT.md — nothing to audit.`) and stop. Never guess project state.

### Step 2 — Detect dependency candidates

Build the candidate list from three signals (union, dedupe later):

**(a) Explicit `## Dependencies (cross-project)` section.** If the section exists, every row is already a declared candidate. Carry over: dependency name, ticket id(s), our assumption, last-checked date.

**(b) Linear cross-project links.** Resolve the active project, then fetch its issues:

```
list_projects { query: <project name from PROJECT.md Links> }
list_issues   { project: <project id>, limit: 250, includeArchived: false }
```

For each issue, call `get_issue { id }` and inspect the `blockedBy`, `blocks`, and `relatedTo` arrays. A link **counts as cross-project** when the linked issue's `projectId` differs from the active project's id (or the linked issue's team differs from ours). Keep only `blockedBy` and `relatedTo` — we care about things we depend on, not things that depend on us.

> Performance note: `list_issues` returns most fields, but `blockedBy`/`relatedTo` ids usually require `get_issue`. Cap detail-fetches to issues that are non-`Done` (we only care about live work).

**(c) Assumption-language scan.** Grep PROJECT.md's `## Constraints / decisions`, `## Open questions`, `## Heads-ups`, and `## Cross-team / ownership` sections for any of these tells:

| Pattern | Why it's a tell |
|---------|----------------|
| `by launch` / `before launch` / `by <date>` | Time-bound assumption about external work landing |
| `will be deprecated` / `to be retired` / `deprecating` | Assumes another team finishes their retirement |
| `once <X> ships` / `after <X> lands` / `gated on <X>` | Explicit upstream dependency |
| `source of truth =` / `source of truth is` / `replaces <X>` | Assumes a migration to a new system is complete |
| `depends on` / `relies on` / `assuming <X>` | Self-flagging dependency language |
| `<TEAM>` mentioned outside our own team's ownership rows | Another team's commitment is implied |
| Event names / service names / API paths owned by other repos | Cross-service contract dependency |
| Linear ticket ids (`[A-Z]{2,}-\d+`) NOT belonging to our team prefix | External ticket cited as decided/done |

Convert each hit into a candidate row with: source line (file + section), our assumption (verbatim quote, ≤25 words), and any ticket ids referenced.

### Step 3 — Resolve across all projects

For each candidate, identify the owning ticket(s) / team / project:

```
# If candidate already names a ticket:
get_issue { id: <TICKET-id> }                     # owning project, team, status, dueDate, assignee, cycle

# If candidate has free-text only (no ticket):
list_issues { query: <key phrase>, limit: 25 }    # search across all projects
# then narrow by team / project / state
```

For event/contract candidates surfaced by (c) — e.g. *"V3 deprecated, source of truth = X.v0"* — corroborate with GitHub when possible (read-only):

```bash
# Who currently produces / consumes the event?
gh api -X GET search/code -f q='"<event-name>" filename:catalog-info.yaml org:<org>' \
  --jq '.items[] | "\(.repository.name): \(.path)"'

# Latest schema version on main:
gh api repos/<org>/event-schemas/contents/schemas/<ns>/<name> --jq '.[].name'
```

Combine into one resolved row per candidate. Where multiple tickets implement the same dependency (e.g. consume-new + retire-old + stop-producing), list them all and treat the chain's **last unstarted** ticket as the bottleneck.

### Step 4 — Risk-assess vs our deadline

For each resolved candidate, compute a risk label using the rules below. Read the active project's deadline from PROJECT.md's `**Window:**` or the first explicit `## Timeline / milestones` date; if there's no deadline, set risk only from status.

| Risk label | Rule |
|-----------|------|
| `satisfied` | All linked tickets `Done` / `Cancelled` (and the cancellation was expected). |
| `on-track` | At least one ticket `In Progress` / `In Review` with `dueDate` (or current-cycle membership) before our deadline. |
| `at-risk` | Live work but no ticket started yet (everything `Backlog` / `Ready for Development`) AND our deadline is within 14 days OR the dependency is on our project's critical path per PROJECT.md. |
| `blocking` | A linked ticket is explicitly `Blocked`, owned by a team that hasn't acknowledged the dep, or has a `dueDate` after our deadline. |
| `untracked` | We couldn't find a ticket at all — the assumption is in PROJECT.md but no Linear work exists for it. (Often a true gap.) |

When PROJECT.md and Linear disagree (status drift), set risk from Linear, and add `drift: ...` to the row's notes.

### Step 5 — Output report (read-only)

Return a single table. **Always**, even when everything is satisfied — silence is indistinguishable from "didn't check".

```
Cross-project dependency check — <project name>

| Dependency                       | Owning project / team       | Ticket(s)            | Our assumption (verbatim quote)                            | Status         | Risk        | Notes |
|----------------------------------|------------------------------|----------------------|--------------------------------------------------------------|----------------|-------------|-------|
| <one-line label>                 | <project> / <team>           | TEAM-123, TEAM-124   | "<≤25 words from PROJECT.md>"                                | <Linear state> | satisfied   | source: PROJECT.md §Constraints L42 |
| <one-line label>                 | <project> / <team>           | TEAM-200             | "<...>"                                                      | Backlog        | at-risk     | source: PROJECT.md §Heads-ups L88; drift: file said Done, Linear says Backlog |
| <one-line label>                 | <other-project> / <team>     | (UNTRACKED)          | "<...>"                                                      | —              | untracked   | source: assumption-language scan, no ticket found |

Summary
- <N> satisfied, <N> on-track, <N> at-risk, <N> blocking, <N> untracked.
- Deadline reference: <YYYY-MM-DD from PROJECT.md Window/Timeline> (used for risk-assessment).
- Detection signals used: explicit section (<N hits>); Linear cross-project links (<N hits>); assumption-language scan (<N hits>).

Suggested next actions (for the caller / user — not taken by this skill)
- <e.g. "Add an explicit `## Dependencies (cross-project)` row in PROJECT.md for the X→Y migration (currently caught by assumption-language scan only).">
- <e.g. "Ping <owning team> in <channel> for ETA on TEAM-200 (at-risk, due before our deadline).">
```

The summary line lets the caller decide whether to surface anything to the user without re-reading the whole table. When everything is `satisfied`, the line is enough.

## Interview stages

This skill is **mostly non-interactive** — it reads, resolves, and reports. Trigger an interview stage only when the audit cannot proceed honestly.

| Trigger | Ask |
|---------|-----|
| **No PROJECT.md** | Nothing to ask — return the one-line "no PROJECT.md, nothing to audit" result. |
| **No Linear project link in PROJECT.md `Links`** | Which Linear project is this work tracked under? (offer candidates from `list_projects { query: <PROJECT.md project name> }`) |
| **Multiple projects match** | Which of these is the active project? (offer the top 3 from `list_projects`) |
| **Assumption-language hit, no ticket** | Optional. Skill defaults to labelling these `untracked` in the report and moving on. Only ask if explicitly told to interactively resolve hits. |

`ask-first` vs `auto` modes do **not** change what's asked here — those modes govern the caller's behaviour before invocation. Once running, this skill's interactivity is determined only by what it actually can't resolve.

## What this skill is NOT

- **Not a project planner.** It does not propose plans, slip dates, or re-prioritise tickets. It only reports.
- **Not a ticket creator.** When a dependency is `untracked`, the skill surfaces the gap — it does not raise the ticket. Use `create-linear-ticket` for that, on the user's call.
- **Not a Slack chaser.** When a dependency is `at-risk`/`blocking` and a stakeholder needs pinging, the report's "Suggested next actions" names them — `corpo-standup-waffle` is the place that turns those names into chase lines.
- **Not a persistence layer.** Nothing is saved. The caller decides whether to write findings into `PROJECT.md` (and on the user's consent, in the case of `maintain-work-context`).

## Related skills

| Skill | Direction | Mode it invokes this skill in |
|-------|-----------|-------------------------------|
| [maintain-work-context](../maintain-work-context/) | upstream caller | `ask-first` — Phase 2 reconcile; on Yes, the caller updates `PROJECT.md`'s `## Dependencies (cross-project)` section from the report (user consent required for the write). |
| [corpo-standup-waffle](../corpo-standup-waffle/) | upstream caller | `auto` — at-risk / blocking rows feed the *In flight / de-risking* and *Need to loop in / chasing* sections of the spoken script. |
| [claw-work-activity](../claw-work-activity/) | upstream caller | `auto` — when a `PROJECT.md` exists, a one-line `Cross-project deps: …` entry is added to the activity report's `Notes` block. |
| [create-linear-ticket](../create-linear-ticket/) | downstream (on user request) | When an `untracked` dependency needs to become a tracked ticket, hand off here. |
