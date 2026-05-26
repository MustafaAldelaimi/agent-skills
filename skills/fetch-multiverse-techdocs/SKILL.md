---
name: fetch-multiverse-techdocs
description: >
  Fetch and read Multiverse TechDocs from GitHub (Reef source of truth). Use when
  the user asks for internal documentation, Reef docs, service setup guides,
  catalog-info metadata, or event schema docs — or pastes a reef.tech-tools.multiverse.io URL.
---

# Fetch Multiverse TechDocs

Reef (`reef.tech-tools.multiverse.io`) is the UI. **GitHub is the source of truth**
for TechDocs markdown. Always **fetch the latest version from the default branch**
(`main`) and read that — do not rely on stale local clones or scrape the Reef website
(Google SSO blocks unauthenticated access).

---

## Workflow

1. **Resolve** the target (repo, component, page, or event).
2. **Fetch latest** from GitHub (`main` unless the user names a branch).
3. **Read** `catalog-info.yaml` + `mkdocs.yml` (or event schema YAML).
4. **Pull** only the markdown pages relevant to the question.
5. **Answer** from fetched content. Cite Reef URLs for the user; cite file paths for yourself.

Copy this checklist and track progress:

```
- [ ] Resolved repo / component / event
- [ ] Fetched catalog-info.yaml + mkdocs.yml (or schema) from GitHub main
- [ ] Identified relevant doc pages from mkdocs nav
- [ ] Fetched and read page content
- [ ] Cross-checked code if docs look incomplete or outdated
```

---

## Step 1: Resolve the target

| User input | Resolve to |
|---|---|
| Reef component URL `.../docs/default/component/{name}/...` | Repo: search `Multiverse-io/{name}` or grep local `catalog-info.yaml` for `metadata.name: {name}` |
| Reef catalog URL `.../catalog/default/component/{name}` | Same as above |
| Reef event URL `.../catalog/default/event/{event.type.vN}` | `Multiverse-io/event-schemas` → `schemas/...` (see event resolution below) |
| Repo name only (`platform`, `atlas`, `notifications`) | `Multiverse-io/{repo}` |
| Cross-cutting docs (events guidelines, ADRs, Bugbot) | `Multiverse-io/global-tech-docs` |

**Event name → schema path:** `multiverse.apprenticeship.summary_updated.v2` →
`schemas/apprenticeship/summary_updated/v2.yaml` on `main`.

**Component name ≠ repo name** (examples): `rabbitmq-ops` → repo `rabbitmq_ops`;
`aurora-backend` → repo `aurora`. Read `catalog-info.yaml` if unsure.

---

## Step 2: Fetch latest from GitHub

Prefer **`gh api`** (uses the user's GitHub auth):

```bash
# Repo metadata
gh api repos/Multiverse-io/platform/contents/catalog-info.yaml --jq '.content' | base64 -d

# mkdocs config (try mkdocs.yml then mkdocs.yaml)
gh api repos/Multiverse-io/platform/contents/mkdocs.yml --jq '.content' | base64 -d

# A doc page (path from mkdocs nav, usually under docs/ or techdocs/)
gh api repos/Multiverse-io/platform/contents/techdocs/getting-started.md --jq '.content' | base64 -d
```

Or use the helper script (from this skill directory):

```bash
bash scripts/fetch-docs.sh Multiverse-io/platform
bash scripts/fetch-docs.sh Multiverse-io/platform techdocs/getting-started.md
bash scripts/fetch-docs.sh --event multiverse.apprenticeship.summary_updated.v2
```

**Auth:** needs `gh auth login` or `GITHUB_TOKEN` with read access to `Multiverse-io`.

### Fallback order

1. **GitHub API** (`gh api`) — always try first (latest `main`).
2. **Local clone** — only if GitHub is unavailable; prefer `~/Desktop/MV_Dev/{repo}`.
   Warn the user the clone may be stale.
3. **Reef Backstage API** — only if the user has internal VPC access and an API token.
   Ask `#ask-core-infrastructure` otherwise. Do not attempt to scrape the Reef UI.

---

## Step 3: Parse mkdocs navigation

TechDocs repos have `catalog-info.yaml` with `backstage.io/techdocs-ref: dir:.` (or `dir:./docs`).

Common layouts:

| Repo | Docs directory |
|---|---|
| `platform` | `techdocs/` |
| `global-tech-docs` | `docs/` |
| `notifications`, `aurora`, `rabbitmq_ops` | `docs/` |

Read `mkdocs.yml` → `docs_dir` + `nav` to list pages. Fetch only pages that match
the user's question (don't pull the entire repo unless asked).

Construct the Reef link for citations:

```
https://reef.tech-tools.multiverse.io/docs/default/component/{component_name}/{nav_path}
```

`component_name` comes from `metadata.name` in `catalog-info.yaml`.

---

## Step 4: Enrich with catalog metadata

When the question involves **dependencies, events, or owners**, also read
`catalog-info.yaml`:

- `spec.owner` — Backstage team slug
- `spec.consumesEvents` / `spec.producesEvents` — declared event contracts
- `spec.dependsOn` — related components

**Caveat:** declared consumers in catalog-info can be incomplete. For “who consumes
this event?”, also `grep` the event name across `Multiverse-io` on GitHub if the
answer must be authoritative.

---

## Step 5: When docs aren't enough

If fetched docs don't cover the edge case:

1. Say explicitly that docs were checked and what was missing.
2. Read the **code** next (source of truth for behaviour).
3. Do not guess from memory.

This matches how Reef/Surfbot works: docs are a starting point, not a guarantee.

---

## Examples

### “How do I set up platform locally?”

```bash
bash scripts/fetch-docs.sh Multiverse-io/platform techdocs/getting-started.md
```

### User pastes a Reef event URL

Event: `multiverse.apprenticeship.summary_updated.v2`

```bash
bash scripts/fetch-docs.sh --event multiverse.apprenticeship.summary_updated.v2
gh api repos/Multiverse-io/platform/contents/catalog-info.yaml --jq '.content' | base64 -d | rg summary_updated
```

### “What is rabbitmq_ops?”

```bash
bash scripts/fetch-docs.sh Multiverse-io/rabbitmq_ops docs/index.md
```

---

## Do not

- Scrape `reef.tech-tools.multiverse.io` with WebFetch/browser (SSO required).
- Assume a local clone is up to date without fetching from GitHub first.
- Treat Reef's consumer list as complete without code search for non-trivial questions.
