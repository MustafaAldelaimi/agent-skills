# Standup log format

Specification for `docs/work/standup-log/<audience>/YYYY-MM-DD.md` — the per-audience daily ledger the skill reads in Step 1 and writes in Step 6.

The log is the **only** memory `corpo-standup-waffle` has. If a day's log is missing, the skill is blind to what was said that day.

## File structure

Each daily log is a single markdown file:

```markdown
# YYYY-MM-DD — <audience>

## Script (verbatim)

<full script text, exactly as printed in chat>

## Items mentioned

| Item ID | State | First mentioned | Last mentioned | Source |
|---------|-------|-----------------|----------------|--------|
| <id>    | started \| in-flight \| finished | YYYY-MM-DD | YYYY-MM-DD | <where it came from> |
```

Two required sections, in this order. Tables in `## Items mentioned` are parsed by the next run's Step 1 walk-back.

## Item identity (the `Item ID` column)

The keying rule decides whether two days are talking about the "same item". Pick in this order:

| Item type | Key format | Example |
|-----------|-----------|---------|
| Linear ticket | Ticket ID exactly as Linear shows it | `SEA-1824` |
| Cross-team chase (person, team, vendor) | `<team-or-person>/<topic-slug>` | `WFD/AIP-funding-data`, `Tony/competency-service-dep` |
| Narrative finding / decision / discovery | Short kebab-case slug | `events-vs-graphql-calibration`, `platform-rest-verification` |
| Recurring meta-work (e.g. weekly seed of a thing) | `recurring/<slug>` | `recurring/weekly-WFD-sync` |

**Rules:**

- Slugs are **immutable** once chosen — that's how next-day lookup works. Use the **Item identity ambiguous** interview stage if a slug needs renaming (then update the prior log entry too).
- Linear ticket IDs are the strongest key — always prefer them when an item maps to a ticket.
- A cross-team chase about a ticket should usually use the ticket ID, not the `<person>/<topic>` form, so chase-list mentions and direct ticket-mentions collapse to the same item.
- Lowercase, kebab-case, no spaces, no special characters except `/` (used only as the team/person separator).

## Tri-state transitions

States are advanced **one-way** within a single audience. Cross-audience state is independent.

```
(absent) ──first mention──> started ──next mention──> in-flight ──complete-announcement──> finished ──> (drop forever)
```

| From → To | Trigger |
|-----------|---------|
| absent → `started` | First time the item appears in any candidate set for this audience. |
| absent → `finished` | One-shot work completed and announced same day (skip the intermediate states). |
| `started` → `in-flight` | Item is still active and appears in a later run. |
| `started` → `finished` | Item became done before next mention. |
| `in-flight` → `in-flight` | Item still active **and** state-change detected — re-mention in full with new substance. |
| `in-flight` → `finished` | Item completed. |
| `finished` → anything | **Not allowed.** A re-opened item should be tracked as a new item with a fresh slug (`<old-slug>-rev2`) or via a new ticket. |

Once an item lands at `finished` for an audience, the dynamic walk-back's termination condition no longer holds it open — it stays seen but doesn't lengthen future loads.

## State-change detection (drives in-flight: compress vs. include in full)

An `in-flight` item with no detectable change compresses to a one-liner. "Change" = any of the following, evaluated in order:

1. **Linear status changed** since `last_mentioned` date — e.g. Ready → In Progress, In Progress → In Review.
2. **Activity report has a new row** for this item in `docs/work/activity/<today>.md` (a commit, a Linear comment, a Slack message that names the ticket/topic).
3. **Chase target replied** — the Slack thread tracked for this chase item has `last touch` newer than `last_mentioned`.
4. **User said so** at the **Status ambiguity** interview stage — explicit override.

If none of 1–4 fire, the item collapses to:

```
Still pending: <topic> — no movement since <last_mentioned>.
```

This is intentionally short and honest. It signals "I haven't dropped this, but I haven't moved it either" without padding the script.

## Walk-back termination (the dynamic load)

```python
def load_logs(audience_dir, today):
    seen_state = {}                                 # item_id -> {state, first_mentioned, last_mentioned}
    logs_by_date = sorted(audience_dir.glob("*.md"), reverse=True)  # newest first
    SAFETY_CAP_DAYS = 90

    for log_file in logs_by_date:
        merge_into(seen_state, parse(log_file))

        active = [item for item in seen_state.values() if item.state != "finished"]
        if not active:
            return seen_state                       # nothing to chase backward

        oldest_first_mentioned = min(item.first_mentioned for item in active)
        log_date = parse_date(log_file.stem)
        if log_date <= oldest_first_mentioned:
            return seen_state                       # all active items' lifecycles covered

        if (today - log_date).days >= SAFETY_CAP_DAYS:
            warn_user("Item(s) active for 90+ days; consider escalation or dropping.")
            return seen_state

    return seen_state                               # reached start of log directory
```

The cost is proportional to your actual debt:

- Active-light week with everything Done: reads ~1 file.
- One item parked `in-flight` for 6 weeks: walks back 6 weeks (cheap — markdown parse).
- One item parked for 90+ days: hits the safety cap and warns; the warning is the cue to either drop the item from PROJECT.md or escalate via chase.

## Worked filter example

Suppose yesterday's log (2026-06-04) had:

| Item ID | State | First | Last |
|---------|-------|-------|------|
| SEA-1824 | finished | 2026-06-04 | 2026-06-04 |
| WFD/AIP-funding-data | in-flight | 2026-06-02 | 2026-06-04 |
| Tony/competency-service-dep | in-flight | 2026-06-03 | 2026-06-04 |
| cross-team-headsup | in-flight | 2026-06-02 | 2026-06-04 |

Today (2026-06-05) the candidate set rebuilds and includes:

- `SEA-1824` (PROJECT.md still references it) → **prior state finished → DROP.** Audience heard it yesterday.
- `WFD/AIP-funding-data` → prior `in-flight`. No new Linear status, no new activity row, no Slack reply. → **compress to one-liner**: `Still pending: WFD AIP funding data — no movement since 2026-06-04.`
- `Tony/competency-service-dep` → prior `in-flight`. Tony posted a reply in #ask-dp-learner this morning (per activity report). → **state-change detected; include in full** with the reply as new substance.
- `SEA-1852` (new candidate today, just appeared In Progress in Linear) → not in seen_state → **include as `started`**: `Kicking off the DB-foundation workstream (SEA-1852) — first PR going up today.`
- `cross-team-headsup` → prior `in-flight`. data-engineering replied yesterday with sign-off. → **state-change → promote to `finished`**: `Cross-team headsup wrapped — data-engineering confirmed no breakage expected.`

Today's log writes back all five items with their new states, ready for tomorrow.

## Edge cases

| Case | Handling |
|------|----------|
| Brand-new audience (no logs yet) | `seen_state = {}`; treat every candidate as new. Step 1 walk-back terminates immediately. |
| Skipped a day (no log for yesterday) | Walk-back continues until terminated; gap doesn't matter — the next prior log fills in. |
| Audience subdirectory exists but today's log already written (e.g. re-run) | Read it like any other; the latest write replaces it on Yes-to-save (no append). |
| Item appears under two slugs in different logs (rename mid-history) | Walk-back will treat them as distinct items → re-announcement risk. Use **Item identity ambiguous** interview to fix; manually update the older log entries to the new slug, or accept the duplicate announcement once. |
| Table malformed in a prior log | Log a warning, skip that log's items, continue walk-back. Don't fail the run. |
| `first_mentioned` missing on an in-flight item | Treat as worst case (assume very old); the walk-back may run to the safety cap. Surface a warning so the user can fix the malformed entry. |
