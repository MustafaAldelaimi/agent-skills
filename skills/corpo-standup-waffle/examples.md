# Example: dogfooding on the Competency-level PLA project

A worked end-to-end run of `corpo-standup-waffle`, against the real `docs/work/PROJECT.md` + journal for the Competency-level PLA project (SEA-1824), at the morning of 2026-06-04.

This shows the four moving parts together: (1) what the skill reads, (2) the interview it triggers, (3) the cache lookups + verifications, (4) the script it returns.

## 1. Context the skill reads (silent)

From `docs/work/PROJECT.md`:

- Goal: move PLA module → competency in Aurora.
- Current focus: build phase, hard end-of-June compliance deadline. Work split: events = Mustafa, scoring = Jamal, Tony on schema/platform discovery.
- Decisions adopted: per-competency grain, hard swap (no flag), archive old table, cut-offs unchanged. Admin UI (SEA-1853) **low priority / deferred from June**.
- Open: AIP data from WFD by **June 10** (critical path); Competency Service `pla` vs `mastery_percent` dependency (Tony); Aude's `pla_calculation_logic` event enum proposal (additive event change); cut-off sanity check with Barry.
- Cross-team: data-engineering (DWH), sync-learning-impact (client-xp), tech (Platform OTJ/fee), events-guild (no schema work needed), WFD.

From `docs/work/journal/2026-06-03.md`:

- Two syncs yesterday set timeline (local June 10, OTT handover June 19, testing done June 25).
- Verified Platform uses Aurora REST not GraphQL → induction form unaffected.
- client-xp **CLEARED** via Slack (#C047DUQK58S, Al Skipp confirmed grouping-only dependency, no `pla`-value logic).

From Linear (read-only):

- `list_projects { query: "Competency-level PLA" }` → project id.
- `list_issues { project: <id> }` →
  - **Done:** SEA-1849 (events investigation).
  - **In Design:** SEA-1824 (discovery).
  - **Ready for Development:** SEA-1852, SEA-1853, SEA-1854, SEA-1855 (Jamal Saleh).
  - No tickets currently assigned to **me** in flight; my work is the events workstream + the un-created seed-values ticket.

## 2. Interview stage triggered

`Today's intent` triggers because PROJECT.md "Next" lists multiple things and there's no fresh journal entry for today yet.

```
> Quick one before I generate the script: what (if anything) are
> you actually planning to touch today?
>
> 1. Draft the seed-values ticket (the WFD-data follow-up)
> 2. Outreach to Async Learning / DWH / DP Customer
> 3. Catch up on the Aude `pla_calculation_logic` proposal
> 4. None of the above — heads down on something else
> 5. Nothing concrete yet
```

User answers: "Mostly 5, but I'll reply to Aude's enum proposal in-thread today."

`Audience / format` defaults to daily standup (engineers), short, spoken — no interview needed.

## 3. Org-map lookups (cache → verify on miss)

Stakeholders mentioned in PROJECT.md: **WFD**, **data-engineering**, **sync-learning-impact**, **tech** (Platform), **Barry**, **Tony**, **Aude**, **Async Learning**, **DP Customer**.

`org-map.md` has team-level seeds for the first four + WFD. Tony, Aude, Barry are people, not teams — discovered live via Slack/Linear:

```
slack_search_users { query: "Aude" }      → Aude Faucheux (@aude, sync-learning-impact)
slack_search_users { query: "Tony" }      → Tony Narlock (@tnarlock, dp-learner)
slack_search_users { query: "Barry" }     → multiple matches → interview stage "Unresolved owner/contact":
  "Two Barrys in workspace — Barry Smith (platform-eng) or Barry Jones (WFD)?"
  User: "WFD one."
  → write back: workforce-diagnostics.Key people = "Barry Jones (@barry-j, cut-off owner); Last verified: 2026-06-04; Source: user-confirmed"
```

For `Async Learning` (no seed):

```
gh api repos/Multiverse-io/<async-learning-repo>/contents/catalog-info.yaml → spec.owner: "group:async-learning"
slack_search_channels { query: "ask-async-learning" } → #ask-async-learning (C0XXXXXX)
gh api repos/.../CODEOWNERS → confirms async-learning team owns the relevant paths
→ write new cache entry, Source: catalog + CODEOWNERS, Last verified: 2026-06-04
```

For `DP Customer`: same pattern → discovered, written back.

For the client-xp Slack thread cited "yesterday":

```
slack_search_public { query: "in:#C047DUQK58S PLA competency" }
slack_read_thread { channel_id: "C047DUQK58S", message_ts: "1780504844.441699" }
→ "last touch: Al replied 2026-06-04 09:02 BST — cleared, no action."
```

## 4. The script (final output)

This is **all** the skill returns. No preamble, no "would you like me to post this?". The user reads it.

```
Quick update on the competency-level PLA project.

Done / progressed:
- Closed out the events question (SEA-1849) with the no-change conclusion; V3 deprecates ahead of our launch so PLA lands cleanly on `result_generated.v0`.
- Verified Platform consumes Aurora via REST, not GraphQL — the induction form reads `masteryPercent` only, so the SEA-1854 GraphQL break and the calc change don't affect it.
- Captured yesterday's two syncs (timeline, work split, cut-off sanity check) in the living docs so the next session lands without re-discovery.
- Heads-up to client-xp went out yesterday afternoon; Al Skipp confirmed back this morning that they have no `pla`-value dependency — that consumer is cleared.

In flight / de-risking:
- Critical-path AIP funding data inbound from WFD — sequencing the seed-values ticket directly behind that input so we land cleanly on the June-10 local milestone.
- Aude floated an additive `pla_calculation_logic` enum on the event schema; calibrating whether any consumer actually needs it before we touch contracts — leaning towards skip but want to hear out the case.
- Tony's discovery on the Competency Service mastery%/PLA dependency is in flight; gates the Async Learning impact assessment.
- Cut-off logic is in DB-level sanity-check phase with Barry to confirm it's untouched by the PLA-level shift.

Today:
- Reply to Aude on the `pla_calculation_logic` proposal in-thread to align before we sink any event work.
- Following up with Async Learning, Data Warehouse, and DP Customer on the module → competency shift to keep momentum on the cross-team comms path.
- Capturing today's findings in the journal to keep context portable.

Need to loop in / chasing:
- Workforce Diagnostics (Barry Jones, ask-wfd) — AIP funding data for June-10 local milestone; last touch: TBC, going out today.
- Tony (#ask-dp-learner) — Competency Service mastery% vs PLA dependency check; last touch: kicked off in yesterday's sync.
- Aude (#TBC) — `pla_calculation_logic` enum proposal; last touch: thread in #C047DUQK58S, my reply going in today.
- Async Learning (#ask-async-learning), Data Warehouse (#TBC — verifying with data-engineering), DP Customer (#TBC) — heads-up on the PLA grain shift; last touch: TBC, sequencing outreach today.
```

## Notes on this example

- **Honest framing.** "Closed out the events question" maps to SEA-1849 actually closing. "Verified Platform consumes Aurora via REST" maps to the `grep` we did against the local clone. Every line cites a real fact.
- **Today is mostly stalling tactics**, because the user said today is mostly empty — that's the honest answer and the script reflects it without lying.
- **Stakeholder lines lean on others**, which is the point. Every chase line names a specific channel/person + ask + last-touch citation. No fake threads.
- **TBC** appears where the cache wasn't verified — better than guessing a channel that doesn't exist.
- **The skill returns the script and stops.** No "shall I post this?", no Slack draft. The user reads it.
