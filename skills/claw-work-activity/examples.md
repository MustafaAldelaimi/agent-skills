# Examples

Three worked runs covering the three invocation modes that produce visible behaviour. Each example shows what triggers the mode, what the chat output looks like, and (where applicable) what the confirmation prompt looks like and what gets written.

The chat body is **identical** across all three. The only difference is the side effect (save prompt + file write or not).

## Example A — `standalone` (chat-only, no save prompt)

**Trigger:** user invokes the skill directly.

> User: "claw my work today"

**Mode resolution:** no upstream caller → `standalone`.

**Window:** unambiguous → `today` (local 00:00 → now). No interview.

**What the skill returns:**

```
Activity report: 2026-06-04 00:00 -> 14:54 BST
Identity: MustafaAldelaimi / @mustafa / Mustafa Aldelaimi

Git (4 events)
- 14:54 - MustafaAldelaimi/agent-skills pushed 1 commit to main (3dda78e)
- 14:54 - MustafaAldelaimi/agent-skills created tag/branch event for corpo-standup-waffle
- 11:23 - Multiverse-io/aurora reviewed PR #13407 (comment)
- 09:18 - Multiverse-io/aurora commented on #SEA-1849

Linear (3 events)
- 14:35 - SEA-1849 "Investigate whether PLA events need changing..." -> Done
- 11:50 - SEA-1855 commented: "Need WFD AIP data by June 10 for the seed-values ticket..."
- 09:02 - SEA-1824 commented: "Pulling Aude/Jamal/Tony sync notes into PROJECT.md..."

Slack (5 messages)
- 13:14 - #C047DUQK58S - "Replying to Aude on pla_calculation_logic..."
- 11:08 - #ask-dp-learner - "Following up with Tony on Competency Service mastery..."
- 10:42 - DM Jamal - "Quick one on the seed-values ticket — should..."
- 09:24 - DM Aude - "Re your enum proposal — I think we can hold off..."
- 09:02 - #C047DUQK58S - "thanks Al"

Notes
- Window resolved from: default "today"
- Sources skipped/failed: none
- Linear-comment-only items NOT included (MCP limitation - see SKILL).
- Slack relevance filter: 5 work messages kept; 2 social/logistics omitted (DM/social tier only; work channels verbatim).
```

(The two `#C047DUQK58S` and `#ask-dp-learner` entries are named work channels, so they stay verbatim — including the short `thanks Al`. The 2 omitted were scheduling/banter DMs that referenced no work artifact.)

**Save prompt:** **none.** `standalone` mode never proposes a save. The skill prints the report and returns control.

---

## Example B — `for-context` (called by corpo-standup-waffle, chat-only)

**Trigger:** `corpo-standup-waffle` is generating a standup script and needs richer activity than `PROJECT.md` / journal alone provides.

> User: "give me a standup script for today"

`corpo-standup-waffle` runs through its workflow and, at Step 1 (Load context), invokes `claw-work-activity` in `for-context` mode.

**Mode resolution:** caller is another skill (not `maintain-work-context`) → `for-context`.

**Window:** `for-context` defaults to `today` to match the standup horizon.

**What the user sees** — the skill is invoked behind the scenes and the same report body (as Example A) is held in conversation context. `corpo-standup-waffle` then uses it as Done/Progressed feedstock and produces its script (see [`../corpo-standup-waffle/examples.md`](../corpo-standup-waffle/examples.md)).

**Save prompt:** **none.** `for-context` mode never proposes a save — `corpo-standup-waffle` only needs the data in context, not an artefact on disk. The user only sees the final standup script; the activity report is a means to that end.

---

## Example C — `for-journal` (called by maintain-work-context, Yes/No prompt)

**Trigger:** user is wrapping up the day and asks `maintain-work-context` to update the journal.

> User: "update today's journal"

`maintain-work-context` reaches Phase 3 (Update Context) and invokes `claw-work-activity` in `for-journal` mode to gather the factual Done block.

**Mode resolution:** caller is `maintain-work-context` Phase 3 → `for-journal`.

**Window:** `today`.

**What the user sees:**

1. The chat report (same body as Example A).
2. Immediately followed by the confirmation prompt:

```
About to save this report to docs/work/activity/2026-06-04.md
(proposed by maintain-work-context). Proceed?

- Yes
- No
```

**If user picks Yes:**

- The skill writes `docs/work/activity/2026-06-04.md` with the same body as the chat report (including DM snippets verbatim — Slack scope is symmetric).
- Confirms in chat: `Wrote docs/work/activity/2026-06-04.md (12 entries)`.
- Returns control to `maintain-work-context`, which then uses that file as the factual source for today's journal `## Done` section. Agent's job becomes narrating + editing, not remembering.

**If user picks No:**

- No file is written.
- Returns control to `maintain-work-context`, which proceeds using the chat output as feedstock (and writes the journal as it would have without the artefact).

Either choice is fine — the journal still gets updated. The file is only an optimisation that survives across sessions.

---

## Example D — opt-in Cursor sessions bucket (titled multi-select + subagent summaries)

**Trigger:** user wants in-chat work (research, debugging, decisions) included — not just Git/Linear/Slack.

> User: "claw my work this week and include my Cursor sessions"

**Mode resolution:** direct invocation → `standalone`. **Window:** `last-7d`.

**Step 3 (Cursor sessions):** harvest metadata only — read titles + timestamps from the SQLite state DB (`file:...?immutable=1`) and join to transcript dirs across all workspaces. No `.jsonl` is read yet. Likely-personal sessions are flagged.

**Selection prompt (nothing ticked by default):**

```
Cursor sessions in window (tick to include):
[ ] aurora        | Module-level and competency-level PLA investigation
[ ] aurora        | Adding dp-learner tag to workflows
[ ] notifications | Users with approved-by-mv-and-client status

Likely personal (excluded - tick only to include):
[ ] aurora        | CV eligibility check
```

User ticks the three work sessions, leaves the personal one unticked.

**Summarisation:** one readonly subagent per ticked session reads that single `.jsonl` and returns a <=120-word summary. The parent ingests only those summaries (never the full 300-message transcript).

**Resulting bucket (appended to the Example A body):**

```
Cursor sessions (3)
- 16:06 - aurora - "Module-level and competency-level PLA investigation" - confirmed no event change; scoped 6-ticket events workstream [SEA-1849]
- 16:17 - aurora - "Adding dp-learner tag to workflows" - tagged 7 Knock workflows in dev via CLI
- 13:15 - notifications - "Users with approved-by-mv-and-client status" - wrote recipient query for the comms audit
```

**Notes block additions:**

```
- Cursor sessions: opted in: 3 of 4 in-window sessions included; 1 flagged-personal excluded.
```

**Save behaviour:** in `standalone` this is chat-only. Had this been `for-journal` with a flagged-personal session ticked, the skill would require a second acknowledgement before writing that session's content to `docs/work/activity/*.md`.

**Cross-agent (optional):** if `agentgrep` is installed, the step adds cross-agent keyword recall for non-Cursor agents (Codex/Claude/Cursor CLI/etc.) via `agentgrep search <terms> --scope conversations --agent all --json`, de-duped against the SQLite rows; the bucket is then titled **Agent sessions**. Note (verified against `0.1.0a20`): agentgrep is term-driven with no window-list mode, `title` is null for all agents and `timestamp` only present for `cursor-cli`, and its Cursor IDE adapter exposes only the flat `aiService.prompts` list — so Cursor IDE always stays on the authoritative SQLite path, and agentgrep is recall augmentation, not a windowed enumerator. If it is **not** installed and you opted into sessions, the skill offers a one-time choice — Install (explicit Yes) / Continue Cursor-only / Don't ask again — remembers it in the skill-local cache, and never auto-installs.

---

## Notes on the examples

- The Git/Linear/Slack entries above are illustrative — drawn from a plausible workday on the PLA project. Real runs cite real events surfaced from `gh api`, Linear MCP, and Slack MCP for the resolved identity.
- DM/private Slack snippets appear verbatim in **both** chat and file. If you're screensharing during a run, run the skill privately first.
- The Slack **relevance filter** is channel-aware: named work channels (incident/project/`#ask-*`/team) stay verbatim; DMs, group DMs, and social channels keep a message only if it references a work artifact (PR/ticket/link) or is substantive. Pure scheduling, one-word acks, emoji-only, and jokes are omitted from that tier — but the omitted count is always disclosed in `Notes`, never dropped silently.
- `Linear-comment-only items NOT included` is the standing caveat in the `Notes` block — Linear MCP can't filter `list_issues` by "commented-by me", so issues you only commented on (not assigned, not in a project where you're a member) won't surface from Linear directly. They may still appear via the gh search if the comment was on a linked GitHub PR/issue.
