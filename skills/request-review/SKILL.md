---
name: request-review
description: >
  Draft Slack PR review requests in the DP Learner team format for #dp-learner.
  Gathers open PRs from Linear (In Review), GitHub URLs, or gh. Use when the user
  asks to request a review, ping for review, draft a review message, or post in
  #dp-learner with :git_rereview_requested.
---

# Request Review (DP Learner Slack)

Draft a **copy-paste Slack message** for `#dp-learner` (`C089CQ8A01L`). Default output is **minimal** — review ask, `@` mention, PR URLs, sign-off. No ticket sections, no background, unless the user asks for verbose.

## Default output template

Use this unless the user requests more context:

```text
:git_rereview_requested: @<Reviewer Name> could you review when you have a sec?

<full PR URL, one per line>

Thanks!
```

Rules:

- First line **must** start with `:git_rereview_requested:` (team convention).
- `@` the reviewer by **display name** (e.g. `@Claudia Mihai`) — resolve via Slack `slack_search_users` when the user names someone.
- PR links: **bare** `https://github.com/Multiverse-io/...` URLs, **one per line**, no bullets, no Slack `<url|label>` unless the user asks.
- Do **not** group by Linear ticket or add per-ticket headings unless the user explicitly asks.
- Sign-off: `Thanks!` (or `:pray:` if the user prefers).
- Return **only** the message body ready to paste — no preamble or meta commentary.

## Verbose mode (opt-in only)

If the user asks for context, incident follow-up, or merge order, use:

```text
:git_rereview_requested: <SEA-XXXX>: <short title>. @<Reviewer> could you review when you have a sec?

<1–2 sentences of context, optional>

Merge order:
<PR URLs, dependency order>

<optional sizing note, e.g. "All small, revert diffs.">

Thanks!
```

Do not add verbose sections by default.

## Gather PR links

Collect URLs from whatever the user provides, then dedupe.

| Source | How |
|--------|-----|
| User | PR URLs, numbers (`#13407`), or branch names |
| Linear | `list_issues` with `assignee: me` and `state: "In Review"` (or a specific issue id); `get_issue` → `attachments[].url` |
| GitHub | `gh pr view <n> --repo Multiverse-io/<repo> --json url,state` |

When the user says "my in review tickets" (or similar), use Linear **In Review** issues assigned to **me** and pull all GitHub attachment URLs.

### Which PRs to include

- Prefer **open** PRs (`state: OPEN`). Skip merged/closed unless the user wants them listed.
- If both a forward PR and its **revert** are attached to the same ticket, include only what the user is asking to be reviewed now (often reverts after recovery; ask if unclear).
- **Dedupe** identical URLs (e.g. one revert PR on two Linear tickets).

### Merge order (only when needed)

Order links when dependencies exist; otherwise list by repo then number:

1. `event-schemas` / shared contracts before consumers (`platform`, `user_home`, `aurora`, …).
2. Stack **base** PR before PRs whose base branch is another feature branch.
3. **Forward fix / prodscript** before **revert** PRs that undo it.
4. Otherwise: ascending PR number within the same repo.

Mention `Merge order:` only in verbose mode or when the user asks.

## Reviewer and channel

- Default channel: `#dp-learner` for Learner DP / Platform work.
- Default reviewer: none — only `@` mention when the user names someone (e.g. Claudia).
- Resolve Slack user: `slack_search_users` with first name; use `Claudia Mihai` style display name in the message.

## Examples

**Minimal (default):**

```text
:git_rereview_requested: @Claudia Mihai could you review when you have a sec?

https://github.com/Multiverse-io/platform/pull/13407
https://github.com/Multiverse-io/platform/pull/13400
https://github.com/Multiverse-io/platform/pull/13406

Thanks!
```

**Verbose (user asked for context):**

```text
:git_rereview_requested: SEA-1725: post-incident cleanup reverts. @Claudia Mihai could you review when you have a sec?

Follow-up to the approved-by-mv-and-client incident. Recovery work is done; these PRs roll back the temporary incident changes.

Merge order:
https://github.com/Multiverse-io/platform/pull/13407
https://github.com/Multiverse-io/platform/pull/13400
https://github.com/Multiverse-io/platform/pull/13406

All small, revert diffs. Thanks!
```

## Do not

- Post to Slack automatically unless the user asks to send.
- Invent PR URLs or ticket ids.
- Split one message per Linear ticket unless the user asks.
- Use `git_rereview_requested` without the leading colon emoji (Slack custom emoji).
