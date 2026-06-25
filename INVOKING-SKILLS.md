# Invoking skills aggressively

Cursor and Claude Code both auto-surface these skills: the agent is handed each
skill's `description` and decides relevance itself. Two levers make that firing
reliable, and this repo uses both.

1. **Sharp triggers.** Every `SKILL.md` front-loads a broad "Use when / Use
   proactively …" trigger so the matching signal is the first thing the agent
   reads. Safety contracts (read-only, output-only, consent-gated) stay in the
   body, so broadening *when* a skill fires never broadens *what* it does.
2. **A global skills-first rule** (below), pasted once into each tool. This
   turns "the agent *could* use a skill" into "the agent *checks first, every
   time*". It is biased toward **over-invocation** — a wasted check beats a
   missed skill.

Neither tool auto-loads a *global* skills rule file, so the rule is pasted into
each tool's global settings once.

## Cursor — User Rules

Cursor Settings → **Rules** → **User Rules** (applies to Agent/Chat across every
project; it does not reach Tab or Cmd-K). Paste:

```
Skills are mandatory, not optional. Before doing anything in response to a
request — including before asking clarifying questions — scan the available
Skills and their "Use when" triggers. If any skill could plausibly apply, even
at low confidence, read its SKILL.md and follow it. When in doubt, invoke:
over-invoking is strongly preferred to missing one. Announce briefly ("Using
[skill]."). Re-read the skill each time instead of relying on memory. Never skip
a skill because the task seems simple or because you already know how — the
skill is the source of truth. Fire these proactively without being asked:
maintain-work-context, check-cross-project-dependencies,
propose-skill-improvement.
```

## Claude Code — global memory

Append the same rule as its own section in your global `~/.claude/CLAUDE.md`
(append — don't replace anything already there):

```md
# Using skills

Skills are mandatory, not optional. Before doing anything in response to a
request — including before asking clarifying questions — check whether any
available skill applies. If one could plausibly apply, even at low confidence,
read its SKILL.md and follow it; over-invoking is strongly preferred to missing
one. Announce briefly ("Using [skill]."), and re-read the skill rather than
acting from memory. Fire these proactively without being asked:
maintain-work-context, check-cross-project-dependencies,
propose-skill-improvement.
```

## Why over-invocation is the default here

Most of these skills are cheap to consult, and several are *meant* to fire
without being asked (`maintain-work-context`, `check-cross-project-dependencies`,
`propose-skill-improvement`). The cost of skipping one — unversioned work
context, a missed cross-team dependency, a lesson never captured — is far higher
than a redundant read. Skills that must *not* auto-fire protect themselves in
their own body with consent gates and read-only / output-only contracts.
