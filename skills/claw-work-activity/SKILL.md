---
name: claw-work-activity
description: >
  Produce a dated, timestamped activity report for a chosen time window by
  pulling the user's own activity from GitHub (gh), Linear (MCP), and Slack
  (public + private + DMs; social/logistics noise filtered, omissions
  disclosed), plus optional local agent-session summaries (opt-in, read-only;
  Cursor by default, cross-agent via agentgrep when available). Strictly
  read-only across every
  source. Save behaviour is caller-proposed and user-confirmed: standalone +
  for-context invocations are chat-only with no save prompt; for-journal
  (invoked by maintain-work-context) and standalone-with-save propose a save
  to docs/work/activity/YYYY-MM-DD.md and require a mid-conversation Yes/No
  confirmation before writing. Feeds maintain-work-context (journal Done
  section) and corpo-standup-waffle (Done/Progressed feedstock). Use when the
  user asks for "what did I do today", "claw my work", "activity report",
  "since last standup", "timestamped log of my work", or similar.
---

# Claw Work Activity

Produces a chronological, bucketed activity report (Git / Linear / Slack) for a chosen time window. The report's body is **identical** whether printed to chat or saved to a file; the only difference is whether a file gets written.

The skill is the **factual** companion to:
- `maintain-work-context` (narrative journal — uses this skill's file when present).
- `corpo-standup-waffle` (spoken standup script — uses this skill's chat output as Done/Progressed feedstock).

## Hard guardrails (read first)

- **Read-only across every source.** Never call `slack_send_*`, `slack_schedule_message`, Linear `save_*`, `gh pr create`/`gh issue create`/`gh pr review`, or any git command that mutates state (no `commit`, `push`, `tag`, `rebase`).
- **No file write in `standalone` or `for-context` modes — ever.** These modes do not even *propose* a save, so the Yes/No confirmation prompt never appears.
- **No silent writes in any mode.** When a save is proposed (`for-journal` or `standalone-with-save`), the file is written **only after the user picks Yes** in the mid-conversation confirmation prompt. A caller cannot opt out of the prompt.
- **Identity cache is skill-local and gitignored.** `me-identity.md` lives next to `SKILL.md` and is in the repo's `.gitignore` so handles are never pushed.
- **Never invent activity.** If a source fails or returns empty, say so in the `Notes` block and move on. Empty days exist and that's the correct output for them.
- **Slack scope is symmetric.** Public, private, and DM message snippets appear verbatim in **both** chat output and the saved file. If you're about to screenshare during a run, run the skill privately first.
- **Slack relevance filter never drops silently.** The channel-aware filter (Step 3) applies **identically** to chat and file, and only ever omits clearly non-work chatter from the DM/social tier — the omitted count is always disclosed in `Notes`, and when unsure you keep the message. Work channels are never filtered.
- **Cursor sessions are opt-in and read-only.** The bucket is off by default; it is only built when the user explicitly opts in for the run. The Cursor SQLite state DB is opened **read-only/immutable** (`file:...?immutable=1`) — never copied, moved, or written. Transcript `.jsonl` files are read, never modified.
- **Likely-personal sessions are excluded by default.** Sessions whose title or first query match personal keywords (job/CV/HR/contract/review/etc.) are listed separately and only included on an explicit tick — never auto-included.
- **Extra consent before saving session content.** When a save is proposed (`for-journal` / `standalone-with-save`) and any included session is flagged-personal, require a second explicit acknowledgement before its content is written to `docs/work/activity/*.md` (that path may be a git repo).
- **Never read full transcripts into the parent.** Transcripts can run to hundreds of messages; summarise each selected session in a readonly subagent and ingest only the short summary (see Step 3, Cursor sessions).
- **The agentgrep backend is optional and non-fatal.** It only ever widens coverage to other agents; if it is missing, prereq-blocked (needs Python >=3.14), or errors, fall back silently to the SQLite + filesystem path and note it — never fail the run because the optional backend is unavailable.

## Workflow (5 steps)

### Step 1 — Resolve identity (once, cached)

On first run (or when `me-identity.md` is missing/stale), resolve "you" across all sources and cache the result locally.

```bash
gh api user --jq '.login + " " + .email'   # GitHub login + email
git config --global user.email              # git author email (may differ from gh email)
```

```
# Slack: slack_search_users { query: "<your name>" } -> pick the U-id matching your handle
# Linear: assignee: "me" is supported natively;
#         list_users { query: "<your name>" } once for display name + uid
```

`me-identity.md` shape (skill-local, **not** pushed):

```yaml
github_login: <login>
github_email: <email>
git_author_email: <email>
slack_user_id: <U-id>
slack_display_name: <name>
linear_user_id: <u-id>
last_verified: <YYYY-MM-DD>
```

Treat as stale after 30 days or on any lookup failure → re-resolve and rewrite.

### Step 2 — Resolve time window

Default = today (local 00:00 → now). If the user didn't specify and it's not obviously "today", trigger the **No window specified** interview stage.

| Option | Window |
|--------|--------|
| `today` | local 00:00 → now |
| `yesterday` | yesterday 00:00 → 24:00 |
| `since-last-report` | mtime of most recent `docs/work/activity/*.md` → now |
| `last-Nd` | rolling N days back from now |
| `custom` | ISO `<from>` → `<to>` |

Always carry the TZ in the output header (default: local).

### Step 3 — Claw sources (in parallel, read-only)

**GitHub** (via `gh`, no MCP needed):

- Events: `gh api "users/<login>/events?per_page=100" --paginate` — filter `created_at >= <since>`. Covers `PushEvent`, `PullRequestEvent` (opened/closed/merged), `PullRequestReviewEvent`, `IssueCommentEvent`, `PullRequestReviewCommentEvent`, `CreateEvent`.
- Cross-org PRs: `gh search prs --author=@me --updated=">=<since>"` and `gh search prs --reviewed-by=@me --updated=">=<since>"`.
- Cross-org comments: `gh api "search/issues?q=commenter:<login>+updated:>=<since>"`.
- Optional local-only deepening: in the current workspace, `git log --author="<email>" --since=<since> --pretty=format:'%h %aI %s'` catches commits not yet pushed.

**Linear MCP** (read-only):

- `list_issues { assignee: "me", updatedAt: "-P<N>D", includeArchived: false, limit: 250 }` — issues you touched.
- For each issue whose state changed in-window, optionally `get_issue { id }` for status transitions.
- `list_comments { issueId }` per issue to pull your in-window comments. Skip if the issue's `updatedAt` is outside the window.

> **Linear MCP v1 limitation:** `list_issues` cannot filter by "commented-by me". Issues you *only* commented on (not assigned, not in a project where you're a member) won't surface from Linear directly — they may still show up via the gh comments call when the comment was on a linked GitHub issue/PR. Note the gap in the `Notes` block.

**Slack MCP** (read-only; public + private + DMs always included):

- Resolve `slack_user_id` from `me-identity.md`.
- `slack_search_public_and_private { query: "from:<@uid> after:<YYYY-MM-DD>", limit: 250 }`.
- For each result, optionally `slack_read_thread` to grab one line of parent context (your message + the immediate parent message). Skip if rate-limited.
- Channel display: resolve channel id → `#name` via `slack_search_channels` (cache the mapping in-session).
- **Relevance filter (channel-aware, disclosed — never silent).** Cuts social/logistics noise without fabricating or hiding anything:
  - **Work channels** (named public/private channels — incident, project, `#ask-*`, team/squad): keep **all** your messages verbatim. High signal, low risk. Exception: obviously-social channels (`#random`, `#social`, `#watercooler`, `*-banter`) are treated as the social tier below.
  - **DMs + group DMs + social channels**: keep a message only if it (a) references a work artifact — PR/issue URL, ticket ID (`[A-Z]{2,}-\d+`), or a github/linear/metabase/notion link — **or** (b) is substantive (more than a one-word ack, not emoji-only, not pure scheduling/banter).
  - **Omit** from that tier: emoji-only or blank messages, one-word acknowledgements (`thanks`, `ok`, `lgtm` alone), and pure scheduling/social chatter (`2pm?`, `Slack?`, jokes).
  - **Always disclose** the omitted count in `Notes` (e.g. `Slack: 2 work messages kept; 5 social/logistics omitted`). Never omit without counting. When in doubt, keep it.

**Cursor sessions** (local agent transcripts; **opt-in**, read-only):

Captures in-chat work — investigations, planning, debugging, decisions — that often leaves no Git/Linear/Slack trace. Off by default; build it only when the user opts in for the run. Works across **all** workspaces opened in Cursor on this machine, not just the current one.

*Discovery + metadata first — no transcript reads yet, so the parent context stays tiny.* Titles and timestamps come from Cursor's SQLite state DB; workspace and transcript path come from the filesystem. Join on the chat UUID (`composerId`).

```bash
DB="$HOME/Library/Application Support/Cursor/User/globalStorage/state.vscdb"
# Real sidebar titles. immutable=1 => snapshot read: no WAL lock, no multi-GB copy.
sqlite3 "file:$DB?immutable=1" \
  "SELECT json_extract(value,'\$.composerId'), json_extract(value,'\$.name'), \
          json_extract(value,'\$.createdAt'), json_extract(value,'\$.lastUpdatedAt') \
   FROM cursorDiskKV WHERE key LIKE 'composerData:%';"
```

- Keep sessions whose `lastUpdatedAt` (epoch ms) falls in the window.
- Resolve workspace + transcript file from the filesystem: `~/.cursor/projects/<workspace>/agent-transcripts/<uuid>/<uuid>.jsonl` (exclude `subagents/`). Derive the workspace/repo label from `<workspace>`.
- If a transcript file exists but has no `composerData` row, fall back to a title derived from the first `<user_query>` and note it.

**Timestamps:** each user turn in the `.jsonl` carries a `<timestamp>` tag — use the first as session start, and `lastUpdatedAt`/file mtime as last-activity. (Assistant turns are not timestamped.)

**Flag likely-personal sessions** (case-insensitive) on title + first user query:
`cv|resume|job|applic|eligib|salary|offer|\bhr\b|contract|promotion|performance review|interview|visa|immigration|beapplied|personal`

**Selection (opt-in):** present the titled list via `AskQuestion` multi-select with **nothing selected by default**. List flagged-personal sessions in a separate "Likely personal (excluded)" group that must be ticked explicitly. Only ticked UUIDs proceed.

**Summarise via subagent** (keeps full transcripts out of the parent's context): for each selected UUID, spawn a readonly `Task` subagent (one transcript each, parallelisable) with this fixed contract:

> Read ONLY `<abs path to that .jsonl>`. Return, in <=120 words: title; workspace; start (first `<timestamp>`) and last-activity; 2-5 bullets of what was actually done; artifacts (PR/issue URLs, ticket IDs, files touched); one-line outcome. Do not paste the raw transcript.

The parent ingests only these summaries — never the raw `.jsonl`.

**Optional cross-agent backend ([agentgrep](https://agentgrep.org)).** If the `agentgrep` MCP server is available **or** the `agentgrep` CLI is on `PATH`, widen the bucket beyond Cursor IDE to every agent it indexes (Codex, Claude Code, Cursor CLI, Gemini, Grok, Pi, OpenCode). It is read-only and entirely optional — when absent or erroring, fall back **silently** to the SQLite + filesystem path above (Cursor IDE only) and never fail the run on its account.

- **Detect:** `command -v agentgrep` (CLI) or the presence of the agentgrep MCP server. If neither, skip this sub-step.
- **Enumerate (window-list, not keyword):** `agentgrep find --json` with no query term streams all records; filter them to the window by their timestamp client-side. (agentgrep's `search`/`grep` are term-driven — use `find` for "everything in window".)
- Each record carries `agent`, `title`, `path`. Label each session with its `agent`.
- **Dedupe against the SQLite rows:** a Cursor IDE record from agentgrep and the same `composerData` row are one session — prefer the SQLite title (the exact sidebar name) and drop the agentgrep duplicate. Non-Cursor agents add net-new sessions.
- Feed the merged, de-duped set into the **same** opt-in selection + per-session subagent summarisation as above (the subagent reads `record.path`). Personal-flagging applies to every agent.
- **Prereqs:** agentgrep needs Python `>=3.14` and a runner (`uv`/`uvx`/`pipx`). If it is configured but unavailable, note it in `Notes` and continue with the SQLite path.

When agentgrep contributes non-Cursor sessions, title the output bucket **Agent sessions** instead of **Cursor sessions**.

### Step 4 — Merge + dedupe + sort

- Dedupe across sources by URL or `(source, id)`. A `PullRequestEvent` from `users/<you>/events` and a `gh search prs` hit for the same PR are the same event.
- Dedupe Cursor sessions against Git/Linear: if a session summary references a PR/ticket already listed in another bucket, annotate that entry (e.g. "(worked in Cursor session …)") rather than listing it twice.
- Sort all entries by timestamp (display in local TZ).
- Bucket by source (Git / Linear / Slack / Cursor sessions) for the printed report, but keep timestamps so the bucket reads chronologically top-to-bottom.

### Step 5 — Output (mode-routed, Yes/No save prompt)

The skill always prints the chat report. Whether it *proposes* a save is determined by the invocation mode; if a save is proposed, the file is written only after the user picks Yes in the confirmation prompt.

| Mode | When | Proposes save? |
|------|------|----------------|
| `standalone` (default) | User invokes directly ("claw my work today", "what did I do this week") | **No.** Chat-only, no save prompt. |
| `for-context` | Another skill invokes solely to gather context (e.g. `corpo-standup-waffle` enriching Done/Progressed) | **No.** Chat-only, no save prompt. |
| `for-journal` | `maintain-work-context` invokes during a Phase-3 journal update | **Yes.** Print chat, then propose save to `docs/work/activity/<YYYY-MM-DD>.md` and prompt for Yes/No. |
| `standalone-with-save` | User explicitly asks "save it" as a follow-up to a standalone run | **Yes.** Same prompt as `for-journal`. |

Mode detection (in order):

1. Caller is `maintain-work-context` Phase 3 → `for-journal`.
2. Caller is another skill (e.g. `corpo-standup-waffle`) → `for-context`.
3. Otherwise → `standalone`. A subsequent user "save it" turn upgrades to `standalone-with-save`.

**Confirmation prompt (only when a save is proposed):**

```
About to save this report to docs/work/activity/<YYYY-MM-DD>.md
(proposed by <caller>). Proceed?

- Yes
- No
```

On `Yes`: create parent dir if needed, write the file using the same body as the chat output, confirm the path in chat. On `No`: do nothing, return control to the caller (the caller continues with the chat output as feedstock).

The chat body is **identical across all four modes** — only the side-effect (save prompt + potential file write) differs.

### Output template

```
Activity report: <YYYY-MM-DD HH:MM> -> <YYYY-MM-DD HH:MM> <TZ>
Identity: <github_login> / @<slack_handle> / <linear_name>

Git (<N> events)
- HH:MM - <repo> #<num> opened: "<title>"
- HH:MM - <repo> #<num> merged
- HH:MM - <repo> #<num> reviewed (approved | comment | changes-requested)
- HH:MM - <repo> commented on #<num>
- HH:MM - <repo> pushed N commits to <branch>

Linear (<N> events)
- HH:MM - <TICKET-id> "<title>" -> <new status>
- HH:MM - <TICKET-id> commented: "<first 80 chars>..."

Slack (<N> messages)
- HH:MM - #<channel> - "<first 100 chars of message>..."
- HH:MM - DM <name> - "<first 100 chars of message>..."

Cursor sessions (<N>)   # only when opted in; omit the bucket entirely otherwise
                        # title it "Agent sessions" if agentgrep added non-Cursor agents
- HH:MM - <workspace> - "<title>" - <one-line outcome> [PR/ticket refs]
- HH:MM - <agent> - "<title>" - <one-line outcome>   # cross-agent rows (agentgrep) carry their agent label

Notes
- Window resolved from: <today | --since arg | interview answer>
- Sources skipped/failed: <list, e.g. "Linear list_comments rate-limited; partial">
- Linear-comment-only items NOT included (MCP limitation - see SKILL).
- Slack relevance filter: <N work messages kept; M social/logistics omitted (DM/social tier only; work channels verbatim)>.
- Cursor sessions: <not requested | opted in: N of M in-window sessions included; K flagged-personal excluded>.
- agentgrep (cross-agent): <not installed | used: P agents covered | configured but unavailable - fell back to SQLite/Cursor-only>.
```

## Interview stages

Pause and ask the user (use `AskQuestion` when available; otherwise ask conversationally). Ask only what's missing.

| Trigger | Ask |
|---------|-----|
| **No window specified** and not obviously "today" | Window? (today / yesterday / since last report / last Nd / custom ISO) |
| **Identity cache missing or stale** | Confirm your Slack display name + GitHub login so I can resolve "me" correctly |
| **Save proposed by caller** (`for-journal` or `standalone-with-save`) | Mid-conversation Yes/No confirmation prompt (see Step 5) |
| **Cursor sessions requested** (user opts in for the run) | Titled multi-select of in-window sessions (default none; flagged-personal shown in a separate excluded group) |
| **Flagged-personal session included in a save mode** | Second explicit acknowledgement before its content is written to `docs/work/activity/*.md` |

`standalone` and `for-context` never propose a save → no save prompt at all.

## Related skills

| Skill | Direction | Mode it invokes this skill in |
|-------|-----------|-------------------------------|
| [maintain-work-context](../maintain-work-context/) | downstream consumer | `for-journal` (proposes save, prompts user) |
| [corpo-standup-waffle](../corpo-standup-waffle/) | downstream consumer | `for-context` (chat-only, no prompt) |

## Out of scope (v1)

- **Cursor agent transcripts** — now supported as the opt-in **Cursor sessions** bucket (Step 3): titles via the SQLite state DB, per-session subagent summaries, flagged-personal excluded by default. Off unless the user opts in. Optionally widened to other agents (Codex/Claude/Gemini/etc.) via agentgrep when present.
- **Terminal command history** (`~/.cursor/projects/.../terminals/*.txt`) — deferred (noise + privacy).
- **Linear comment-only items** without assigneeship or project membership — MCP limitation. Noted in `Notes` block; no heroic workaround.
- **Automatic journal write-back.** Even with the file written, the journal stays human-curated. The activity file is a parallel artefact, not the journal itself.

## Related files

- [examples.md](examples.md) — worked runs covering `standalone`, `for-context`, `for-journal` (with the Yes/No prompt), and the opt-in Cursor sessions bucket.
- `me-identity.md` (gitignored, created on first run) — your resolved handles + cache timestamp.
