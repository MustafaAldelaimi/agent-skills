---
name: create-plan
description: >
  Standardize how implementation plans are written so a time-poor reader can
  decide "go / no-go" in one skim. Use whenever you are in Cursor Plan mode,
  about to present a plan or call CreatePlan, or when the user says "plan
  this", "scope this", "how would you approach this", "design this", or "write
  up a plan". Every plan leads with a one-line answer, then a scope estimate
  (rough lines of code changed + how many PRs are needed), a confidence rating
  (High / Medium / Low-Blocked, with the drivers behind it), and one short
  plain-language paragraph per change — abstracted to the higher level, not
  line-by-line. After the plan has fully finished executing, hand off to
  maintain-work-context to journal what was actually done.
---

# Create Plan

Write the plan for the **reader**, not the author. A plan exists so a time-poor person can understand *what we're about to do, how big it is, and how sure we are* in a single skim — then say go. Stay one level above the code: abstract the work up, don't narrate every edit.

## When to Apply

- You are in Cursor **Plan mode**, or about to present a plan / call `CreatePlan`.
- The user asks to "plan", "scope", "approach", "design", or "write up" a change.
- A task is large or ambiguous enough that the user should approve the direction before you build.

Skip the ceremony for trivial one-step changes — just do them. Keep the plan **proportional** to the work: a one-file change does not need eight headings.

## Plan format (required)

Fill this shape. You may drop sections that genuinely don't apply, but **never** drop **TL;DR**, **Scope**, **Confidence**, or **Changes**.

```markdown
## TL;DR
<one or two lines: what we're doing and the outcome>

## Scope
- Lines of code: ~<n> (<XS | S | M | L | XL>)
- PRs: <n> — <one line on why split this way, or "single atomic change">

## Confidence: <High | Medium | Low / Blocked>
- <the top 1-3 drivers behind the rating>

## Changes
1. **<change name>** — <one short paragraph, plain language: what it accomplishes
   and why. Name the key file(s). No line-by-line how.>
2. **<change name>** — <…>

## Assumptions & open questions
- Assuming: <something you're inferring that isn't confirmed yet>
- Open: <decision still needed + who owns it>

## Non-goals
- <what this deliberately does NOT do>

## Risks & rollback
- <main risk> -> <how we back out>

## Verification
- <manual steps to confirm it works — CI covers unit tests>

## Definition of done
- [ ] Change merged
- [ ] After full execution, journal via maintain-work-context (PROJECT.md + daily journal)
```

## Scope estimate (lines of code + PRs)

Give the reader a **size**, not a precise count.

**Lines of code** — order-of-magnitude bucket:

| Bucket | LOC | Feel |
|--------|-----|------|
| XS | < 10 | one-liner / config tweak |
| S | 10-50 | small, contained |
| M | 50-200 | feature-sized change |
| L | 200-500 | multi-file, needs care |
| XL | 500+ | consider splitting |

State it as "~120 lines (M)". If you genuinely can't bucket it, that *is* a confidence signal — say so rather than guessing precisely.

**Number of PRs** — default to **one PR per logical, independently-reviewable change** (mirrors [`raise-pr`](../raise-pr/) and the repo's one-commit-per-logical-change norm). Split when:

- Parts can ship / merge independently.
- A shared contract or migration must land before its consumers (then state the **merge order**).
- A single PR would be too large to review well (heading into XL).

If it's genuinely one atomic change, say "1 PR" and move on — don't manufacture splits.

## Confidence rating

Pick the level **and name what's driving it** — the drivers are more useful than the label.

| Level | When | Driver examples |
|-------|------|-----------------|
| **High** | Straightforward, isolated, well-understood; little inference needed | known files, additive change, existing pattern to copy |
| **Medium** | The AI must infer or decide things while executing; some unknowns | unclear API shape, multiple viable approaches, untyped edges |
| **Low / Blocked** | Major undecided factors, or pending a human | awaiting stakeholder decision, unresolved trade-off, missing access/spec |

Rules of thumb:

- Confidence is about **certainty of execution**, not size. A large change can be High; a tiny one can be Low.
- **Low / Blocked means name the blocker and who unblocks it.** A plan that hides its blocker is worse than one that flags it.
- If confidence is Medium because of a specific fork, surface that fork in *Assumptions & open questions* (or as a quick options-and-recommendation brief) so the user can resolve it up front instead of mid-execution.

## Changes — one paragraph each, abstracted up

The **Changes** list is the body of the plan, and the whole point is to lift the reader above the diff:

- **One short paragraph per change, maximum.** What it accomplishes and why — not the patch.
- **Lead with the answer**, then the why. Don't bury the conclusion at the bottom.
- **Name the key file(s)** with paths so the reader can locate the work, but don't reproduce the code.
- **Plain language, no jargon without a gloss.** Assume the reader skims.

## Refinements (make the plan more useful)

- **Lead with the answer.** TL;DR first, every time — the reader should get the conclusion before the reasoning.
- **Glanceable, not a wall of text.** Bullets over paragraphs; proportional to complexity.
- **Separate assumptions from facts.** Make explicit what the AI is *inferring* vs. what's *decided*, so a wrong assumption gets caught before execution rather than after.
- **State non-goals.** Saying what you won't do prevents scope creep and surprise.
- **Give a rollback.** "If this breaks, revert X" buys the reader the confidence to say go.
- **Verification = manual steps only.** CI covers unit tests (per [`raise-pr`](../raise-pr/)); list what a human checks.
- **Sequence multi-PR work.** State merge order and dependencies up front.
- **No calendar-time estimates.** Size by LOC, PR count, and confidence — never days or weeks.
- **A plan is the solution; a ticket is the problem.** Unlike [`create-linear-ticket`](../create-linear-ticket/) (which must *not* prescribe a solution), a plan's job is to commit to one — be concrete.

## After the plan executes

A plan isn't finished when the code merges — it's finished when the **work context is updated**. Once the plan has **fully finished executing**:

1. Hand off to [`maintain-work-context`](../maintain-work-context/) to update `PROJECT.md` (Current focus / Done / Next) and append today's journal with what was *actually* done.
2. Keep it evidence-linked and user-briefed per that skill (link the PR / ticket; brief before logging).
3. Do this **after** execution, not at plan time — the journal records what happened, not what was hoped.

This closes the loop: the plan said what we'd do; the journal records what we did, with receipts.

## Companion Cursor rule (recommended)

So the format fires automatically in Plan mode, install a user-level rule:

```markdown
---
description: Standardize implementation plans (scope, confidence, plain-language changes)
alwaysApply: true
---

# Write plans for the reader

When in Plan mode or about to present a plan:
1. Apply the create-plan format — lead with a TL;DR, then Scope (rough LOC + PR
   count), Confidence (High / Medium / Low-Blocked + drivers), and one short
   plain-language paragraph per change. See ~/.cursor/skills/create-plan/SKILL.md.
2. Separate assumptions from facts; state non-goals, risks/rollback, and manual
   verification. No calendar-time estimates.
3. After the plan has fully finished executing, update work context via
   maintain-work-context (PROJECT.md + daily journal), evidence-linked.
```

Install per the user's convention:

- **User-level** (recommended — applies across all projects): `~/.cursor/rules/create-plan.mdc`.
- **Project-level**: `<repo>/.cursor/rules/create-plan.mdc`.

`alwaysApply: true` keeps the directive in working memory so plans come out skimmable by default. If that's too noisy, set `alwaysApply: false` and trigger it by description instead.

## Related skills

| Skill | Direction | Relationship |
|-------|-----------|--------------|
| [maintain-work-context](../maintain-work-context/) | downstream (this skill hands off to it) | After full execution, journal what was done in `PROJECT.md` + the daily journal, evidence-linked. |
| [raise-pr](../raise-pr/) | downstream | PR mechanics + the one-PR-per-logical-change norm behind the Scope estimate's PR count. |
| [create-linear-ticket](../create-linear-ticket/) | sibling (contrast) | A ticket states the *problem* and must not prescribe a solution; a plan commits to the *solution*. |
| [propose-skill-improvement](../propose-skill-improvement/) | sibling | Shares the lead-with-the-answer, evidence-linked, skimmable-brief style. |
