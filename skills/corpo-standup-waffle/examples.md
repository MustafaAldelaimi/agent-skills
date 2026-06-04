# Example: dogfooding on the Competency-level PLA project

A worked end-to-end run of `corpo-standup-waffle`, against the real `docs/work/PROJECT.md` + journal for the Competency-level PLA project (SEA-1824).

Two days are shown: **Day 1 (2026-06-04)** — first run, empty standup log, full script. **Day 2 (2026-06-05)** — same audience, the tri-state filter drops/compresses prior mentions automatically.

This shows: (1) what the skill reads, (2) the interview stages it triggers, (3) the cache lookups + verifications, (4) the script it returns, (5) the mandatory Step 6 save prompt, (6) how Day 2's walk-back filters Day 1's mentions.

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

## 2. Interview stages triggered

**Audience selection** triggers first (Step 0) because no audience was specified and no `docs/work/standup-log/` subdirectories exist yet.

```
> Audience? Default `team-standup`. No existing audiences yet (this is the first run).
>
> 1. team-standup (default)
> 2. leadership-update
> 3. async-post
> 4. (other — name a new audience)
```

User picks `team-standup`. The skill creates `docs/work/standup-log/team-standup/` lazily on the Step 6 save.

`Step 1 walk-back` then finds no prior logs (fresh audience) → `seen_state = {}` → every candidate item gets treated as new.

**Today's intent** triggers because PROJECT.md "Next" lists multiple things and there's no fresh journal entry for today yet.

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

## 5. Step 6 — Save prompt (mandatory)

After printing the script, the skill always proposes saving:

```
> Save this script + items log to docs/work/standup-log/team-standup/2026-06-04.md?
> This is how the next run avoids re-announcing the same items to this audience.
>
> 1. Yes
> 2. No (script printed, no memory written; tomorrow's run won't know what was said today)
```

User picks **Yes**. The skill writes `docs/work/standup-log/team-standup/2026-06-04.md` per [`standup-log-format.md`](standup-log-format.md):

```markdown
# 2026-06-04 — team-standup

## Script (verbatim)
<full script from section 4>

## Items mentioned
| Item ID | State | First mentioned | Last mentioned | Source |
|---------|-------|-----------------|----------------|--------|
| SEA-1849 | finished | 2026-06-04 | 2026-06-04 | Linear (Done) |
| platform-rest-verification | finished | 2026-06-04 | 2026-06-04 | journal 2026-06-03 |
| events-vs-graphql-calibration | finished | 2026-06-04 | 2026-06-04 | session memory |
| code-walkthrough-all-tickets | finished | 2026-06-04 | 2026-06-04 | session memory |
| client-xp-headsup | finished | 2026-06-04 | 2026-06-04 | Slack #C047DUQK58S |
| WFD/AIP-funding-data | in-flight | 2026-06-02 | 2026-06-04 | PROJECT.md Open Q1 |
| Aude/pla_calculation_logic-enum | in-flight | 2026-06-03 | 2026-06-04 | journal 2026-06-03 |
| Tony/competency-service-dep | in-flight | 2026-06-03 | 2026-06-04 | journal 2026-06-03 |
| Barry/cut-off-sanity-check | in-flight | 2026-06-03 | 2026-06-04 | journal 2026-06-03 |
| cross-team-headsup-data-eng | in-flight | 2026-06-04 | 2026-06-04 | PROJECT.md Cross-team |
| cross-team-headsup-async-learning | in-flight | 2026-06-04 | 2026-06-04 | PROJECT.md Cross-team |
| cross-team-headsup-dp-customer | in-flight | 2026-06-04 | 2026-06-04 | PROJECT.md Cross-team |
```

Confirmed in chat: `Wrote docs/work/standup-log/team-standup/2026-06-04.md (12 items).`

---

# Day 2 — same audience, walk-back filter in action

User invokes the skill again on **2026-06-05** at 10:00 BST, same project, same audience.

## 1. Step 0 — audience

User already in `team-standup` context (or specifies it again). No re-interview.

## 2. Step 1 — dynamic walk-back

```
Read docs/work/standup-log/team-standup/*.md, newest first:
  - 2026-06-04.md  -> parse Items mentioned (12 rows)
  
After loading 2026-06-04:
  - 5 items in `finished` state (drop from active set)
  - 7 items in `in-flight` state; oldest first_mentioned = 2026-06-02
  - Current file date 2026-06-04 > 2026-06-02 (oldest active first_mentioned)
  - There are no older logs in the directory
  - Termination: reached start of log directory; safety cap not hit
  
seen_state ready, walk-back stops after 1 file.
```

## 3. Fresh sources

- Linear: SEA-1852 just moved to **In Progress** today (Jamal started the DB-foundation work) — new candidate not in seen_state.
- Activity report (`docs/work/activity/2026-06-05.md`): row for Aude replying in the `pla_calculation_logic` thread overnight, agreeing to park to M2.
- Slack search shows data-engineering replied "no concerns" to the heads-up thread late yesterday.

## 4. Step 4 — tri-state filter applied

| Candidate item | seen_state | State-change? | Action |
|----------------|-----------|---------------|--------|
| SEA-1824 | (not in candidates — closed yesterday, PROJECT.md no longer references it as open) | — | — |
| SEA-1849 | `finished` | n/a | **DROP** |
| platform-rest-verification | `finished` | n/a | **DROP** |
| events-vs-graphql-calibration | `finished` | n/a | **DROP** |
| code-walkthrough-all-tickets | `finished` | n/a | **DROP** |
| client-xp-headsup | `finished` | n/a | **DROP** |
| WFD/AIP-funding-data | `in-flight` | No (no Linear status, no activity, no Slack reply) | **Compress to one-liner** |
| Aude/pla_calculation_logic-enum | `in-flight` | Yes (Aude replied — agreed M2) | **Promote to `finished`**, include with the new substance |
| Tony/competency-service-dep | `in-flight` | No | **Compress to one-liner** |
| Barry/cut-off-sanity-check | `in-flight` | No | **Compress to one-liner** |
| cross-team-headsup-data-eng | `in-flight` | Yes (data-eng replied "no concerns") | **Promote to `finished`**, include |
| cross-team-headsup-async-learning | `in-flight` | No | **Compress to one-liner** |
| cross-team-headsup-dp-customer | `in-flight` | No | **Compress to one-liner** |
| SEA-1852 | (new) | n/a | Include as **`started`** |

## 5. The Day 2 script

Much shorter than Day 1 because the audience has heard most of it:

```
Quick update on the competency-level PLA project.

Done / progressed:
- Aude confirmed the `pla_calculation_logic` enum proposal is parked to Milestone 2 — events workstream stays contained for M1.
- Cross-team heads-up to data-engineering wrapped — confirmed no DWH-side concerns on the new-scans-only value shift.
- Kicking off the DB-foundation workstream (SEA-1852) today — Jamal moved it into In Progress; PR going up later.

In flight / de-risking:
- Still pending: WFD AIP funding data — no movement since 2026-06-04.
- Still pending: Tony's Competency Service mastery%/PLA dependency check — no movement since 2026-06-04.
- Still pending: Barry cut-off sanity-check — no movement since 2026-06-04.
- Still pending: cross-team heads-up to async-learning and DP customer — no movement since 2026-06-04.

Today:
- Kicking off SEA-1852 with Jamal — pairing on the migration shape.

Need to loop in / chasing:
- Workforce Diagnostics (Barry Jones, ask-wfd) — AIP funding data; last touch: no reply since 2026-06-04.
- Tony (#ask-dp-learner) — Competency Service dependency check; last touch: no reply since 2026-06-04.
```

Notice what's missing vs. Day 1: SEA-1849 closing, the events-vs-GraphQL calibration, the Platform REST verification, the code walkthrough, the client-xp clearance — all dropped automatically because they were `finished` in Day 1's log. The four "still pending" lines acknowledge ongoing dependencies without re-pitching them in full. **The team can tell something's actually new versus stale, and you can tell that you didn't accidentally repeat yourself.**

## 6. Step 6 — save again

The skill prompts to save Day 2's log. User picks Yes → writes `docs/work/standup-log/team-standup/2026-06-05.md` with updated states:

- SEA-1852 → `started` (first: 2026-06-05)
- Aude/pla_calculation_logic-enum → `finished` (first: 2026-06-03, last: 2026-06-05)
- cross-team-headsup-data-eng → `finished` (first: 2026-06-04, last: 2026-06-05)
- WFD/AIP-funding-data → `in-flight` (first: 2026-06-02, last_mentioned bumps to 2026-06-05 because we mentioned it as "still pending")
- Tony/competency-service-dep, Barry/cut-off-sanity-check, cross-team-headsup-async-learning, cross-team-headsup-dp-customer → `in-flight` (last_mentioned bumps to 2026-06-05)
- All Day-1 `finished` items carry forward unchanged (and remain droppable on Day 3).

Day 3's walk-back would now load 2026-06-05 (newest), see the SEA-1852 first_mentioned = 2026-06-05 plus the WFD item still active at first_mentioned = 2026-06-02, and walk back to 2026-06-04 (the only other log) to cover it — terminating because we've reached the start of the directory.

---

## Notes on this example

- **Honest framing.** "Closed out the events question" maps to SEA-1849 actually closing. "Verified Platform consumes Aurora via REST" maps to the `grep` we did against the local clone. Every line cites a real fact.
- **Day 1 today is mostly stalling tactics**, because the user said today is mostly empty — that's the honest answer and the script reflects it without lying.
- **Day 2 script is honestly thinner** — because the tri-state filter dropped 5 already-announced items. That thinness is the point: it stops you from sounding like you forgot what you said yesterday.
- **Stakeholder lines lean on others**, which is the point. Every chase line names a specific channel/person + ask + last-touch citation. No fake threads.
- **TBC** appears where the cache wasn't verified — better than guessing a channel that doesn't exist.
- **Save prompt is the gate.** No memory without a Yes on Step 6. Skipping the save means Day 2 starts from `seen_state = {}` and re-announces Day 1 verbatim — which is exactly the bug the audience-tagged memory is supposed to prevent.
