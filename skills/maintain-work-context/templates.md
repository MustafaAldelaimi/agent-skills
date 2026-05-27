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

## Done (recent)

- YYYY-MM-DD: <outcome>

## Next

- [ ] <concrete action>

## Links

- Linear: <url>
- PRs: <url>
- Docs: <url>
```

## Daily journal (`docs/work/journal/YYYY-MM-DD.md`)

```markdown
# YYYY-MM-DD

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

## Done (recent)

- 2026-05-26: Added webhook integration tests
- 2026-05-24: Drafted cutover runbook

## Next

- [ ] PR for idempotency fix
- [ ] Review runbook with on-call

## Links

- Linear: https://linear.app/team/project/billing-migration
```
