---
name: claw-work-activity
description: >
  Produce a dated, timestamped activity report for a chosen time window by
  pulling the user's own activity from GitHub (gh), Linear (MCP), and Slack
  (public + private + DMs, always included). Strictly read-only across every
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

### Step 4 — Merge + dedupe + sort

- Dedupe across sources by URL or `(source, id)`. A `PullRequestEvent` from `users/<you>/events` and a `gh search prs` hit for the same PR are the same event.
- Sort all entries by timestamp (display in local TZ).
- Bucket by source (Git / Linear / Slack) for the printed report, but keep timestamps so the bucket reads chronologically top-to-bottom.

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

Notes
- Window resolved from: <today | --since arg | interview answer>
- Sources skipped/failed: <list, e.g. "Linear list_comments rate-limited; partial">
- Linear-comment-only items NOT included (MCP limitation - see SKILL).
```

## Interview stages

Pause and ask the user (use `AskQuestion` when available; otherwise ask conversationally). Ask only what's missing.

| Trigger | Ask |
|---------|-----|
| **No window specified** and not obviously "today" | Window? (today / yesterday / since last report / last Nd / custom ISO) |
| **Identity cache missing or stale** | Confirm your Slack display name + GitHub login so I can resolve "me" correctly |
| **Save proposed by caller** (`for-journal` or `standalone-with-save`) | Mid-conversation Yes/No confirmation prompt (see Step 5) |

`standalone` and `for-context` never propose a save → no save prompt at all.

## Related skills

| Skill | Direction | Mode it invokes this skill in |
|-------|-----------|-------------------------------|
| [maintain-work-context](../maintain-work-context/) | downstream consumer | `for-journal` (proposes save, prompts user) |
| [corpo-standup-waffle](../corpo-standup-waffle/) | downstream consumer | `for-context` (chat-only, no prompt) |

## Out of scope (v1)

- **Cursor agent transcripts** (`~/.cursor/projects/.../agent-transcripts/*.jsonl`) — could become a "Chat sessions" bucket; deferred (noise + privacy).
- **Terminal command history** (`~/.cursor/projects/.../terminals/*.txt`) — same; deferred.
- **Linear comment-only items** without assigneeship or project membership — MCP limitation. Noted in `Notes` block; no heroic workaround.
- **Automatic journal write-back.** Even with the file written, the journal stays human-curated. The activity file is a parallel artefact, not the journal itself.

## Related files

- [examples.md](examples.md) — three worked runs covering `standalone`, `for-context`, and `for-journal` (with the Yes/No prompt).
- `me-identity.md` (gitignored, created on first run) — your resolved handles + cache timestamp.
