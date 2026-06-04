# Phrasebook

The corporate lexicon, fact→waffle transformation rules, and stalling/stakeholder-drag patterns the `corpo-standup-waffle` skill uses to spin honest facts into a respectable-sounding standup script.

**Iron rule:** the *facts* never change — only the *framing*. If a fact isn't in PROJECT.md / journal / Linear / Slack, it doesn't go in the script.

## Lexicon

Use these phrases as substitutions when generating lines. Mix freely; don't cluster three in one sentence (immediate giveaway).

### Verbs / process

| Plain | Corpo |
|-------|-------|
| read / re-read | re-familiarised myself with |
| asked | tee'd up a sync / floated for alignment |
| didn't ask yet | actively sequencing outreach to |
| haven't started | in early discovery / scoping phase |
| started | laid the groundwork for |
| made notes | captured findings |
| disagreed | calibrated expectations with |
| changed our mind | re-baselined the approach |
| missed something | uncovered an additional dependency |
| forgot | de-prioritised pending re-evaluation |
| reverted | applied a rollback to de-risk |
| broke prod | exercised our incident-response runbook |
| fixed bug | shipped a corrective patch |
| reviewed PR | provided code-review feedback |
| chased | followed up |
| chased again | continued to drive alignment |
| ignored | parked pending stakeholder bandwidth |

### Nouns / states

| Plain | Corpo |
|-------|-------|
| meeting | working session / alignment sync |
| chat | quick stakeholder touchpoint |
| problem | risk / open item |
| blocker | external dependency |
| broken | degraded / pending mitigation |
| done | shipped / landed / closed out |
| almost done | in final QA / awaiting sign-off |
| not done | in flight |
| not started | upstream of the current sprint |
| we're stuck | we're de-risking |
| we don't know | we're scoping |
| we forgot | we're re-prioritising |
| guess | working assumption |
| decision needed | open for input |

### Connector words

Reach for these to fill space and signal collaboration:

- "as part of"
- "in parallel"
- "to ensure"
- "alongside"
- "more broadly"
- "from a [thing] perspective"
- "with the [team] hat on"
- "to land cleanly"
- "to keep optionality open"

## Fact → waffle transforms

Apply per Done / In-flight / Today section.

### Done / progressed

Each Done bullet = `<short fact>` + `<context wrapper>`. Keep it factual; the wrapper sells perceived effort.

| Fact | Waffle |
|------|--------|
| "Closed ticket SEA-XXX." | "Closed out SEA-XXX, which unblocks downstream sequencing on `<area>`." |
| "Reviewed the existing X." | "Did a deep-dive on the current `<X>` implementation to surface any hidden dependencies before we move." |
| "Decided to use approach A." | "Aligned on approach A after weighing it against B — settled the design question that was holding sequencing." |
| "Talked to <person>." | "Tee'd up a working session with `<person>` to socialise the approach and pull in any concerns early." |
| "Updated PROJECT.md / journal." | "Captured the latest decisions in living docs so the next session lands without re-discovery." |
| "Wrote the plan." | "Drafted the implementation plan covering the data-model change, calculation swap, and the cross-team comms path." |

**Honesty rule:** "Closed", "Shipped", "Landed", "Merged" only apply when something actually moved in code/tickets/prod. If it was just a decision or a doc update, say so.

### In flight / de-risking

This section absorbs everything that isn't done and isn't trivially today's work. Foreground **dependencies, unknowns, scoping** — that's the corpo bread and butter.

| Fact | Waffle |
|------|--------|
| "Haven't started Y." | "Y is in scoping — sequencing it behind the upstream dependency on `<team>`." |
| "Don't know if Z is needed." | "Validating whether Z is in scope; pulling `<team>` in to confirm before we sink build cycles." |
| "Waiting on someone." | "Awaiting input from `<team>` on `<thing>` — pinged earlier, expecting a response shortly." |
| "Stalled ticket." | "SEA-XXX is parked pending external dependency on `<team>`; we're keeping it warm via async updates." |
| "Schema change pending." | "Coordinating the schema bump with `<events team>` to ensure consumers land cleanly." |
| "Don't have data yet." | "Critical-path data inbound from `<team>` — once received, we're a single seed away from completion." |
| "Production data not yet seeded." | "Production rollout is gated on the final data ingest, which is sequenced for the next deploy window." |

### Today

Bias toward **low-commitment, high-visibility** verbs. Reads as a full day; commits to nothing concrete shipping.

Defaults if there's nothing else to say:

- "Following up with `<team>` on `<open question>` to keep momentum on the dependency."
- "Continuing to socialise the design with `<stakeholder>` ahead of `<milestone>`."
- "Scoping `<next item>` so we can sequence it as soon as `<dependency>` lands."
- "Pairing with `<reviewer>` on `<PR/spec>` to land cleanly."
- "Capturing today's findings in the journal to keep context portable."
- "Working through the open items on `<ticket>` and de-risking the unknowns."

If the user gave a concrete "Today" answer in the interview stage, **use it verbatim** — don't dilute real plans with waffle. Reserve the defaults for genuinely empty days.

### Need to loop in / chasing

One line per stakeholder. Format:

```
- <Team / Person> (#<channel>) — <ask>; last touch: <citation>
```

Citation options:

- `last touch: replied <date>` (we already heard back; mention to imply momentum)
- `last touch: no reply since <date>` (chase justified — leans on them)
- `last touch: TBC` (we haven't pinged yet — frames as upcoming action)
- `last touch: thread in #<channel>` (link not pasted, but cited)

**Stalling tactic:** every unresolved question = at least one stakeholder line. A blocker handled silently is a blocker that doesn't justify your morning. Surface it.

## Stakeholder-drag patterns

Turn any task into a dependency on someone else. Use sparingly — over-applied and the script reads as deflection.

| Task | Drag pattern |
|------|--------------|
| Build something | "Pre-build review with `<team>` to ensure we land cleanly." |
| Ship something | "Final sign-off from `<owner>` before we cut the release." |
| Document something | "Walking `<reviewer>` through the doc to capture concerns." |
| Decide something | "Tee-ing up a decision sync with `<DRI>`." |
| Test something | "Coordinating with `<QA / WFD / etc.>` on acceptance criteria." |
| Deploy something | "Sequencing the deploy with `<infra / SRE>` for the right window." |

**When NOT to use these:** if the user said in the interview stage that today is a deep-work day with no stakeholder dependency, don't manufacture one. Honest "heads down on `<ticket>` today" beats fake collaboration.

## Stalling tactics (for empty days)

These are valid when there's genuinely no progress and no obvious next action. Use them to fill the script, never as a substitute for facts.

- **Discovery framing:** "Continuing discovery on `<area>` — surfacing edge cases before we commit to an approach."
- **De-risking framing:** "De-risking the rollout path; mapping the consumer impact before flipping anything."
- **Comms framing:** "Driving cross-team alignment on `<topic>` — multiple workstreams converge, want one shared understanding."
- **Sequencing framing:** "Re-sequencing the workstream to match `<other team>`'s timeline."
- **Documentation framing:** "Updating the living doc / runbook to reflect the latest decisions."
- **Onboarding framing:** "Onboarding `<new joiner>` to the project context to expand review capacity."

## Anti-patterns (don't generate these)

- ❌ Specific dates for things you can't ship by then ("shipping Friday").
- ❌ Numbers without a source ("about 80% done").
- ❌ Naming a person as blocking you without a real thread to cite — leans on them publicly.
- ❌ Three corpo verbs in a row ("re-baselined the approach to socialise the alignment workstream") — sounds satirical, not professional.
- ❌ Claiming "done" / "shipped" / "merged" when nothing moved in code or tickets.

## Calibration

| Audience | Tone |
|----------|------|
| Daily standup (engineers) | Lighter on lexicon, heavier on facts. Use 1–2 corpo phrases max per section. |
| Leadership update | Heavier on outcomes, dependencies, and risks. Stakeholder-drag patterns play well. |
| Async written post | Slightly more structured; use bullets, drop the "Quick update" opener if redundant. |

The skill's interview stage asks audience; pick calibration accordingly.
