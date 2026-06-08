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

- <decision>: <brief rationale>

## Open questions

- <unknown>

## Team status (synced from Linear)

<!-- Team projects only. Reconcile from Linear at session start. Tag your rows (me). -->

| Workstream | Owner | Ticket | Status | Updated |
|------------|-------|--------|--------|---------|
| <area> | (me) | TEAM-123 | <status> | YYYY-MM-DD |
| <area> | <teammate> | TEAM-124 | <status> | YYYY-MM-DD |

## Done (recent)

<!-- Attribute every item; tag your own with (me) so your contribution stays distinguishable. -->

- YYYY-MM-DD — (me): <outcome>
- YYYY-MM-DD — <teammate>: <outcome>

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

- <completed item>

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

- Keep old pipeline read-only until cutover day — no dual writes
- Use existing Stripe event IDs as idempotency keys

## Open questions

- Do we backfill failed events from April?

## Team status (synced from Linear)

| Workstream | Owner | Ticket | Status | Updated |
|------------|-------|--------|--------|---------|
| Webhook idempotency | (me) | BILL-210 | In progress | 2026-05-26 |
| New pipeline writer | Priya | BILL-205 | Done | 2026-05-25 |
| Cutover runbook | (me) | BILL-212 | In review | 2026-05-24 |

## Done (recent)

- 2026-05-26 — (me): Added webhook integration tests
- 2026-05-25 — Priya: New pipeline writer merged (BILL-205)
- 2026-05-24 — (me): Drafted cutover runbook

## Next

- [ ] PR for idempotency fix ((me))
- [ ] Review runbook with on-call ((me))

## Links

- Linear: https://linear.app/team/project/billing-migration
```
