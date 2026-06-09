# Work Context Templates

## PROJECT.md

```markdown
# Project: <name>

**Window:** YYYY-MM-DD → YYYY-MM-DD
**Goal:** <one sentence>
**Success:** <how we know we're done>

## Current focus

- <what matters right now>

## Constraints / decisions

<!-- Every decision links to its source: Linear issue/comment, GitHub PR/commit/line, or Slack permalink.
     The user must have been briefed and agreed before it lands here. No link ⇒ tag [evidence: none — unverified]. -->

- <decision>: <brief rationale> — decided by <who> ([Slack/Linear/PR ↗]); [evidence: <link>]

## Open questions

<!-- When resolved, move to Constraints / decisions WITH the deciding link (ticket/PR/Slack). -->

- <unknown>

## Team status (synced from Linear)

<!-- Team projects only. Reconcile from Linear at session start. Tag your rows (me). -->

| Workstream | Owner | Ticket | Status | Updated |
|------------|-------|--------|--------|---------|
| <area> | (me) | TEAM-123 | <status> | YYYY-MM-DD |
| <area> | <teammate> | TEAM-124 | <status> | YYYY-MM-DD |

## Done (recent)

<!-- Attribute every item by evidence; tag your own (me: <role>); never log a teammate's solo work as yours.
     Roles: authored | reviewed | drove | investigated | coordinated | advised | paired.
     EVERY item carries a primary-source link (Linear issue/comment, GitHub PR/commit/line, or Slack permalink);
     no link ⇒ [evidence: none — unverified]. Mark brag-worthy items [win] and capture [impact:] [stakeholders:]
     [evidence:] while sources are fresh. -->

- YYYY-MM-DD — (me: authored) [win] <outcome> [impact: …] [stakeholders: …] [evidence: PR/ticket/Slack link]
- YYYY-MM-DD — (me: reviewed; <teammate>: authored): <shared outcome, your slice noted>
- YYYY-MM-DD — <teammate>: <their outcome>  <!-- not yours; logged for context -->

## Next

- [ ] <concrete action> (<owner / (me)>)

## Links

- Linear: <url>
- PRs: <url>
- Docs: <url>
```

## Daily journal (`docs/work/journal/YYYY-MM-DD.md`)

```markdown
# YYYY-MM-DD

> Personal log — first person = my work (this is the professional-development record).

## Plan

- <intended work>

## Done

<!-- Attribute (teammates' work under their name) and link the source. Each item: [evidence: Linear/PR/Slack link] (or [evidence: none — unverified]). -->

- (me: <role>) <completed item> [evidence: <link>]

## Wins (brag-worthy)

<!-- Only your own, while sources are fresh. Feeds your brag/recap system. -->

- (me: <role>) [win] <what + why it mattered> [impact: …] [stakeholders: …] [evidence: PR/ticket/Slack link]

## Blockers

- <blocker or "none">

## Notes

- <decisions, discoveries, links>
```

## End-of-session block (append to today's journal)

```markdown
---

## End of session (HH:MM)

**Focus now:** <one line>
**Next:** <1–3 bullets>
**Open:** <unresolved questions, if any>
```

## Example: filled PROJECT.md (abbreviated)

```markdown
# Project: Billing migration

**Window:** 2026-05-01 → 2026-06-01
**Goal:** Move invoice generation to the new pipeline
**Success:** Production traffic on new pipeline with no P1 incidents for 1 week

## Current focus

- Fix idempotency key handling in webhook handler

## Constraints / decisions

- Keep old pipeline read-only until cutover day — no dual writes — decided by Priya + (me) ([Slack ↗]); [evidence: BILL-201 comment ↗]
- Use existing Stripe event IDs as idempotency keys — [evidence: PR #298 ↗]

## Open questions

- Do we backfill failed events from April?

## Team status (synced from Linear)

| Workstream | Owner | Ticket | Status | Updated |
|------------|-------|--------|--------|---------|
| Webhook idempotency | (me) | BILL-210 | In progress | 2026-05-26 |
| New pipeline writer | Priya | BILL-205 | Done | 2026-05-25 |
| Cutover runbook | (me) | BILL-212 | In review | 2026-05-24 |

## Done (recent)

- 2026-05-26 — (me: authored) [win] Webhook idempotency fix [impact: eliminated duplicate invoices] [stakeholders: Billing + Payments squads] [evidence: BILL-210, PR #310]
- 2026-05-25 — (me: reviewed; Priya: authored): New pipeline writer merged — reviewed, flagged retry edge case (BILL-205)
- 2026-05-24 — (me: authored) Drafted cutover runbook

## Next

- [ ] PR for idempotency fix ((me))
- [ ] Review runbook with on-call ((me))

## Links

- Linear: https://linear.app/team/project/billing-migration
```
