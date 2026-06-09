---
name: propose-skill-improvement
description: >
  Self-observation skill: when the agent has just resolved something the hard
  way (multiple wrong directions, failed tool calls, repeated user re-asks,
  stale-cache misses) OR had an unprompted epiphany that generalises (a
  paper-cut that will recur, a root-cause one level up from the user's
  question), propose a concrete, evidence-linked skill change that would
  prevent or shorten the next occurrence — and, on the user's Yes, raise a PR
  against `MustafaAldelaimi/agent-skills` to create or update the target skill.
  Strictly consent-gated: never edits or opens a PR without an explicit Yes.
  Fires at most once per session, never from a tool error alone (must include
  the resolution arc), and only when the friction is specific and addressable
  by a skill change (not a vague "be more careful"). Use when the agent
  notices it just cracked something after struggling, when it spots a
  generalisable lesson the user didn't ask for, or when the user asks "what
  could we change so this is easier next time".
---

# Propose Skill Improvement

A learning-loop skill. When the agent has just paid for a lesson — by struggling, retrying, or having an epiphany — this skill briefs the user in three lines and, on their Yes, raises a PR to encode the lesson into the skills repo. The point is that **a friction the agent felt today should not be a friction the agent feels tomorrow**.

Strictly consent-gated. Strictly skill-focused (not Cursor rules / hooks / project code).

## Hard guardrails (read first)

- **At most one fire per session.** Even with the medium firing bar, two proposals in one session is noise. Drop additional candidates; mention them only if the user explicitly asks "anything else?".
- **Never PR without an explicit Yes.** The brief is presented; the user picks Yes or No. On Yes, raise the PR. On No, do nothing — no retry, no nag, no "are you sure?".
- **Never fire from a tool error alone.** The signal is the **resolution arc** (struggled → cracked it). A single failed tool call is not enough; the agent needs to have actually overcome the problem in this session, so the lesson is real and the PR has concrete before/after evidence.
- **Skills only.** The user's intent is `MustafaAldelaimi/agent-skills` content. If the right answer is a Cursor rule or hook, mention it in the brief but do not auto-PR — point them at `create-rule` / `create-hook` instead.
- **Don't propose changes to skills you haven't read.** Before naming a target skill, fetch its current `SKILL.md` (read-only) so the brief proposes a real, locatable change — not a generic "add a rule to X".
- **Honest about uncertainty.** If you're not sure the friction is real or the change would prevent it, lead with "low-confidence proposal — agree or skip?" and accept No gracefully.
- **Don't propose your own skill into existence retrospectively.** This skill firing on the friction *of using this skill* is a loop; abort cleanly.

## When to fire (two detection patterns)

### Pattern A — stuck-then-cracked

The agent visibly struggled on a sub-problem in this conversation, then resolved it. Heuristics (any **two** of these on the same sub-problem):

- 3+ failed tool calls / wrong-direction attempts before the right approach was found.
- A course-correction the agent made unprompted (recognising mid-task it was on the wrong track).
- The user re-asked, rephrased, or said "no — what about X" before the agent landed the right answer.
- A stale-cache / source-of-truth miss (tool returned content that contradicted reality; agent had to bypass to verify).
- A scope mistake (agent gave a confident wrong answer, then corrected after the user pushed back or after a second check).

Fire only after the agent has **landed the correct answer or a deliberate handoff** — never mid-struggle.

### Pattern B — unprompted epiphany

The agent realises something generalisable that the user did **not** ask about. Heuristics (any one):

- "While doing X for you, I noticed Y is a recurring paper-cut" — pattern-match across the conversation history.
- A root-cause one level up from the user's question that would prevent a class of similar questions.
- A missing piece of context that, if encoded in a skill, would have made the just-finished investigation faster.
- A workflow the agent reconstructed from scratch that should have been documented (e.g. "I had to re-derive how to verify event consumers — that should be in `fetch-multiverse-techdocs`").

## Quality gate (medium bar — specific + addressable + not-already-covered)

A candidate clears the gate **only** when all three hold:

1. **Specific.** The proposed change is a concrete edit to a real `SKILL.md` (new section, new rule, new guardrail, new step), not a tone shift ("be more rigorous").
2. **Addressable by a skill change.** Encoding it into `~/agent-skills/skills/<skill>/SKILL.md` would prevent or shorten the friction on the next occurrence. If the answer is "the user just needs to be more careful", abort — that is not a skill problem.
3. **Not already covered.** Skim the target skill's current `SKILL.md` (and adjacent skills if the lesson straddles two) to confirm the change doesn't duplicate existing guidance. If it does, abort and (optionally) note it in passing — no PR.

One-offs are allowed (medium bar, not high bar) — the user can always say No. But aborts must be silent: an aborted candidate does **not** consume the one-per-session quota.

## Workflow (5 steps)

### Step 1 — Self-check that the pattern fired

At a sensible session checkpoint (just resolved a sub-problem, just answered a multi-turn question, user said "thanks / okay / next"), ask internally:

- Did Pattern A or Pattern B happen since the last skill-improvement check this session?
- Is the candidate specific, addressable, and not-already-covered?
- Has this skill already fired once in this session? (If yes, stop here.)

If any answer is No, **do nothing** and continue with the user's actual task.

### Step 2 — Locate the target skill (read-only)

Identify the most likely target:

- **Update existing skill**: when the friction is adjacent to an existing skill's domain (e.g. a `fetch-multiverse-techdocs` paper-cut → add a rule there).
- **New skill**: when the friction has no natural home and the lesson is reusable (e.g. "tracing event consumers" deserved its own skill all along).

Fetch the candidate skill's current `SKILL.md` via `gh api` (or read the local clone if `~/agent-skills/` is present) so the brief proposes a real edit anchored in real text — **not** a guess. If proposing a new skill, list the names of existing skills so the user can sanity-check there isn't already a better home.

### Step 3 — Brief the user (≤8 lines, evidence-linked)

Output exactly this shape — no preamble, no "noticed something":

```
Skill-improvement proposal (1/1 this session)

Friction: <one line — what tripped us up, with a chat-history pointer>
  Evidence: <one or two concrete moments from this conversation>
Lesson: <one line — the generalisable rule>
Target: <existing skill to edit, OR new skill name>
  Change: <one line — the concrete edit (new section / rule / step)>

Raise a PR to MustafaAldelaimi/agent-skills? (Yes / No)
```

Examples of what each line looks like, for calibration:

- Friction: `Spent 4 turns scoping v6 vs v7 because we kept rediscovering 'who consumes this event'.` Evidence: `gh search calls at turns 14, 19, 23 each rediscovered the same consumer set.`
- Lesson: `Before scoping any event schema change, enumerate ALL consumers + their pinned versions in one pass.`
- Target: `Update fetch-multiverse-techdocs/SKILL.md`. Change: `Add a "Single-pass consumer enumeration" subsection to the event-interaction workflow with the gh api search/code template.`

Use `AskQuestion` for the Yes/No when the tool is available; otherwise inline question.

### Step 4 — On Yes, raise the PR (uses `raise-pr` mechanics)

```bash
# Assume ~/agent-skills exists and is a git checkout of MustafaAldelaimi/agent-skills
cd ~/agent-skills
git checkout main && git pull --ff-only origin main
git checkout -b skill/<short-slug>
```

Then **either** edit the target `SKILL.md` (use `Write` with the full file body to avoid stale-Read pitfalls — see [`fetch-multiverse-techdocs`](../fetch-multiverse-techdocs/) for the same lesson), **or** create a new `skills/<name>/SKILL.md` from the [`create-skill`](../../) skill structure (frontmatter + Hard guardrails + Workflow + Related skills).

```bash
git add skills/<target>
git commit -m "<skill>: <one-line change, present tense>

<2-4 line body describing the friction + lesson + change.
Reference the conversation source motivating this change (no permalinks
to chat — describe the pattern instead).>
"
git push -u origin HEAD
gh pr create --title "<skill>: <change>" --body "$(cat <<'EOF'
## Why

<friction in 1-2 sentences>

## Change

<bulleted summary of the edit>

## Motivating example

<2-4 lines describing the in-session pattern that motivated this — not a chat link, an anonymised summary>
EOF
)"
```

Return the PR URL to the user.

### Step 5 — On No, drop it silently

No retry, no follow-up, no "are you sure?". The user has the context; they decided. Do not log the proposal anywhere — it was a chat-only suggestion.

The one-per-session quota is consumed by **a fire that reached Step 3**, not by Yes/No.

## What this skill is NOT

- **Not a continuous improvement loop.** One fire per session, by design. The signal-to-noise ratio collapses past that.
- **Not a place to propose Cursor rules / hooks / project code changes.** The skill's PR target is `MustafaAldelaimi/agent-skills` only. If the right answer is a rule or hook, mention it in the brief and point at `create-rule` / `create-hook`; do not raise the PR yourself.
- **Not a place to vent.** "That was annoying" is not a brief. Every proposal names a concrete edit to a real file.
- **Not a meta-loop trap.** This skill does not fire on the friction of using this skill itself.

## Companion Cursor rule (recommended)

Reliable firing needs the agent to *remember* to self-check at session checkpoints. Install this user-level rule so the directive appears in every session:

```markdown
---
description: Watch for skill-improvement opportunities (friction + epiphanies)
alwaysApply: true
---

# Learn from friction

At sensible session checkpoints (a sub-problem just resolved, a multi-turn investigation just landed, the user just said "okay / thanks / next"):

1. Internally check whether the resolution arc matched Pattern A (stuck-then-cracked) or Pattern B (unprompted epiphany) — see `~/.cursor/skills/propose-skill-improvement/SKILL.md` for the heuristics.
2. If yes, AND the candidate is specific + addressable + not-already-covered, run `propose-skill-improvement` once per session.
3. If the user picks No, drop silently. Never retry.

Skill is consent-gated: no edits, no PRs without explicit user Yes.
```

Install per the user's convention:

- **User-level** (recommended — applies across all projects): `~/.cursor/rules/learn-from-friction.mdc`.
- **Project-level**: drop into the project's `.cursor/rules/learn-from-friction.mdc` instead, if user-level rules aren't in use.

`alwaysApply: true` keeps the directive in working memory every session. The cost is a few lines of system prompt; the gain is that friction caught today becomes a skill PR tomorrow instead of being silently re-paid every session.

## Related skills

| Skill | Direction | Relationship |
|-------|-----------|--------------|
| [raise-pr](../raise-pr/) | downstream (this skill invokes it) | Step 4 PR mechanics — branch / commit / push / `gh pr create`. |
| [create-skill](../../) | downstream (when proposing a new skill) | New-skill structure: frontmatter + Hard guardrails + Workflow + Related skills. |
| [create-rule](../../) | downstream (when the friction is better solved by a rule) | Mentioned in the brief but not auto-PRed by this skill. |
| [maintain-work-context](../maintain-work-context/) | sibling | Shares the "brief the user before logging" pattern (Keep-the-user-in-sync) — same evidence-linked, ≤8-line shape. |
