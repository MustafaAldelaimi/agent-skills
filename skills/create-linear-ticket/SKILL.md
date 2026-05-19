---
name: create-linear-ticket
description: >
  Create a Linear ticket with codebase context and inferred metadata. Use when
  the user wants to create a Linear issue, file a bug, raise a ticket, or track
  work in Linear.
---

# Create Linear Ticket

Guide the user through creating a well-formed Linear ticket. The ticket should
describe the problem and provide codebase context — it must NOT prescribe a
solution or list implementation steps.

## Phase 1: Problem Intake

1. Accept the problem description from the user, or infer it from conversation context.
2. Ask the user which Linear **team** and (optionally) **project** the ticket belongs to.
   - If the user is unsure, fetch options via `list_teams` / `list_projects` and present them using `AskQuestion`.

## Phase 2: Codebase Context Gathering

Search the codebase for context relevant to the problem:

- File paths and function/class names involved
- Error messages, stack traces, or log output the user has shared
- Related configuration, schema definitions, or test files

Compile this into a concise context section for the ticket description.

## Phase 3: Ticket Description Authoring

Before writing the description, check if the team has an existing issue template:

1. Fetch recent tickets from the same team/project via `list_issues`.
2. Look for a consistent description structure across those tickets (common headings, sections, formatting patterns).
3. If a template or recurring structure is found, use it as the basis for the description.
4. If no template is apparent, fall back to the default structure below.

**Title**: A concise summary of the problem (not a solution).

**Default description structure** (use only if no team template exists):

```markdown
## Problem

[What is happening and why it matters]

## Codebase Context

[Relevant file paths, code snippets, error traces gathered in Phase 2]

## Additional Notes

[Any extra context from the user — reproduction steps, affected environments, etc.]
```

**Critical rules** (apply regardless of template):
- Describe the problem and its impact — do NOT tell the reader how to fix it.
- Do NOT include step-by-step implementation instructions.
- Include enough codebase context that someone unfamiliar can orient themselves.

Present the draft title and description to the user for review. Revise if requested before proceeding.

## Phase 4: Metadata Inference

Attempt to infer metadata from related tickets before asking the user.

1. Fetch recent tickets from the same project or team via `list_issues`.
2. From those tickets, identify common values for:
   - **Labels** — look at which labels appear most frequently
   - **Priority** — check if there is a dominant priority level
   - **Status** — determine the appropriate initial status
   - **Cycle** — check if tickets are associated with a current cycle
3. Also fetch the full set of available options via `list_issue_labels` and `list_issue_statuses`.

**If inference succeeds**: present the inferred values to the user for verification or override.

**If inference is not possible** (no related tickets, inconsistent patterns, or missing data): present the full list of available options and ask the user to select.

Use `AskQuestion` for structured selection where possible.

## Phase 5: Relationships and Blocking

Search Linear for potentially related tickets:

1. Use `list_issues` with keyword queries derived from the ticket title and problem description.
2. Present any candidate tickets to the user and ask them to confirm:
   - **Related to** — tickets covering similar or adjacent concerns
   - **Blocked by** — tickets that must be resolved before this one can proceed
   - **Blocks** — tickets that depend on this one being resolved first
   - **Duplicate of** — if the problem is already tracked elsewhere
3. If no candidates are found, inform the user and move on.

## Phase 6: Ticket Creation

1. Create the ticket via `save_issue` with all gathered data:
   - Title and description
   - Team and project
   - Labels, priority, status, cycle
   - Relationships (related, blocks, blocked by, duplicate of)
2. Return the ticket identifier (e.g. `TEAM-123`) and URL to the user.
