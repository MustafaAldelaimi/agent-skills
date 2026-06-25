---
name: fetch-multiverse-techdocs
description: >-
  Use whenever the user wants internal Multiverse documentation — Reef docs,
  TechDocs, a service's setup guide or README, catalog-info metadata, event
  schema docs, or when they paste a reef.tech-tools.multiverse.io URL. Fetches
  and reads the latest TechDocs markdown from GitHub (the Reef source of
  truth), not the SSO-gated website or stale local clones.
---

# Fetch Multiverse TechDocs

Reef (`reef.tech-tools.multiverse.io`) is the UI. **GitHub is the source of truth**
for TechDocs markdown. Always **fetch the latest version from the default branch**
(`main`) and read that — do not rely on stale local clones or scrape the Reef website
(Google SSO blocks unauthenticated access).

**Helper script:** `~/.cursor/skills/fetch-multiverse-techdocs/scripts/fetch-docs.sh`

---

## Workflow

0. **Preflight** — verify GitHub auth (see below). If auth fails, tell the user before
   falling back to local clones.
1. **Resolve** the target (repo, component, page, or event).
2. **Fetch latest** from GitHub (`main` unless the user names a branch).
3. **Read** `catalog-info.yaml` + `mkdocs.yml` (or event schema YAML).
4. **Pull** only the markdown pages relevant to the question.
5. **Answer** from fetched content. Cite Reef URLs for the user; cite file paths for yourself.

Copy this checklist and track progress:

```
- [ ] Verified gh auth (or warned user and noted stale local fallback)
- [ ] Resolved repo / component / event
- [ ] Fetched catalog-info.yaml + mkdocs.yml (or schema) from GitHub main
- [ ] Identified relevant doc pages from mkdocs nav
- [ ] Fetched and read page content
- [ ] Cross-checked code if docs look incomplete or outdated
- [ ] Docs reconciled against GitHub (code/schema/catalog); if stale, paused and offered a doc-fix PR
```

> **Docs are a hint, not the truth.** TechDocs drift from the services they describe. For
> anything behavioural or contract-related (calculations, fields, events, endpoints,
> ownership), confirm against the actual GitHub state (code, event schema, `catalog-info.yaml`)
> on `main` — do not answer from the doc alone. When a doc disagrees with GitHub, GitHub wins,
> and you should offer to fix the doc (see **Step 6**).

---

## Step 0: GitHub auth preflight

Always run `gh auth status` before fetching. If it fails:

1. Tell the user explicitly: **GitHub auth is invalid — run `gh auth login`**
2. If the org uses SSO (Multiverse-io does): also run `gh auth refresh -s read:org`
3. Only then fall back to local clones — and **warn that data may be stale**

```bash
gh auth status
# If invalid:
#   gh auth login -h github.com
#   gh auth refresh -s read:org

# Quick sanity check against a private org repo:
gh api repos/Multiverse-io/event-schemas/contents/catalog-info.yaml --jq '.name'
```

**Auth options:** `gh auth login` (preferred) or `GITHUB_TOKEN` env var with read access
to `Multiverse-io`. Agents may need full network permissions for `gh api` calls.

**Common failure:** token in macOS keyring expired, or SSO authorization lapsed (~90 days).

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

**Reef URL patterns:**

```
# Component docs
https://reef.tech-tools.multiverse.io/docs/default/component/{component_name}/{nav_path}

# Event catalog entry
https://reef.tech-tools.multiverse.io/catalog/default/event/{event.type.vN}
```

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

Or use the helper script:

```bash
bash ~/.cursor/skills/fetch-multiverse-techdocs/scripts/fetch-docs.sh Multiverse-io/platform
bash ~/.cursor/skills/fetch-multiverse-techdocs/scripts/fetch-docs.sh Multiverse-io/platform techdocs/getting-started.md
bash ~/.cursor/skills/fetch-multiverse-techdocs/scripts/fetch-docs.sh --event multiverse.apprenticeship.summary_updated.v2
```

The script exits with code **2** on auth failure and prints remediation steps.

### Fallback order

1. **GitHub API** (`gh api`) — always try first (latest `main`).
2. **Local clone** — only if GitHub is unavailable; prefer `~/Desktop/MV_Dev/{repo}`.
   **Always warn the user** the clone may be stale and that auth should be fixed.
3. **Reef Backstage API** — only if the user has internal VPC access and an API token.
   Ask `#ask-core-infrastructure` otherwise. Do not attempt to scrape the Reef UI.

---

## Event service-interaction workflow

Use this when the user asks how an event interacts with other services (consumers,
producers, side effects):

1. **Fetch schema** from GitHub main:
   `bash ~/.cursor/skills/fetch-multiverse-techdocs/scripts/fetch-docs.sh --event multiverse.{ns}.{name}.vN`
2. **Declared contracts** — grep `consumesEvents` / `producesEvents` in catalog-info:
   ```bash
   rg 'multiverse\.{event_name}' ~/Desktop/MV_Dev/*/catalog-info.yaml
   ```
3. **Authoritative consumer search** (when gh auth works):
   ```bash
   gh api search/code -f q='multiverse.{event_name} org:Multiverse-io' \
     --jq '.items[] | "\(.repository.full_name): \(.path)"'
   ```
4. **Find producer** if missing from catalog — grep routing key and event type in code:
   ```bash
   rg 'apprenticeship\.summary_updated|SummaryUpdated' ~/Desktop/MV_Dev --glob '*.{ex,exs,ts,py}'
   ```
   Data-pipeline events (e.g. from Learner Performance Service) often never appear in
   `producesEvents`. Infer from field names (`lps_last_synced_at`, `updated_at`) and
   consumer code comments.
5. **Read consumer handlers** for side effects: DB writes, downstream event publishes,
   notification emails, retry/stale-event logic.
6. **Report auth status** — if GitHub fetch failed, say so and note local clone date.

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
this event?”, also search GitHub code (step above) or grep local clones if auth fails.

---

## Step 5: When docs aren't enough

If fetched docs don't cover the edge case:

1. Say explicitly that docs were checked and what was missing.
2. Read the **code** next (source of truth for behaviour).
3. Do not guess from memory.

This matches how Reef/Surfbot works: docs are a starting point, not a guarantee.

---

## Step 6: Detect stale docs → pause and offer a documentation PR

Whenever you cross-check a doc against GitHub and find the **doc is outdated or wrong**
(e.g. it describes module-level behaviour but the code/schema shows competency-level; a
field/endpoint/owner differs; a process no longer matches reality):

1. **Do not silently work around it.** Record the exact discrepancy:
   - Doc: Reef URL + repo path (e.g. `aurora/docs/how-it-works.md`).
   - GitHub truth: repo + file path + line(s) (code, `*.yaml` schema, or `catalog-info.yaml`).
   - One line on what's wrong and what it should say.
2. **PAUSE and ASK the user** whether to spin up a sub-agent that raises a PR to update the
   documentation in the relevant `Multiverse-io` repo. Offer the choice explicitly:
   - **Yes, now (sync):** launch a sub-agent and wait for the PR before continuing.
   - **Yes, async (background):** launch a background sub-agent (`run_in_background: true`)
     and **continue your original task** in parallel.
   - **No:** continue as normal, but state the discrepancy in your answer so the user isn't
     misled by the stale doc.
3. **Then continue** with the user's original request regardless of the choice — the doc fix
   is a side-quest, not a blocker.

### Sub-agent brief (doc-fix PR)

Give the sub-agent everything it needs to work autonomously:

- Repo + exact doc file path; the precise wording change (old → new) grounded in the GitHub
  source of truth you cited.
- Constraints: **edit documentation only, never product code**; one focused PR; clear title
  and body that link the doc section to the authoritative GitHub file/lines proving the change.
- Mechanics (GitHub API must be reachable — see auth preflight; `api.github.com` must be in
  the sandbox network allowlist):
  ```bash
  # branch, edit the markdown, commit, push, open PR
  git checkout -b docs/<repo>-fix-<topic>
  # ...edit the doc file...
  git commit -m "docs: correct <topic> to match <service> behaviour"
  git push -u origin HEAD
  gh pr create --title "docs: correct <topic>" --body "Doc said X; <repo>/<file>#Ln shows Y. ..."
  ```
- Follow git safety rules: no config changes, no force-push, only commit the doc file(s).

> If multiple unrelated doc errors are found, batch them per repo or raise one PR each —
> ask the user which they prefer when there are several.

---

## Examples

### “How do I set up platform locally?”

```bash
bash ~/.cursor/skills/fetch-multiverse-techdocs/scripts/fetch-docs.sh Multiverse-io/platform techdocs/getting-started.md
```

### User pastes a Reef event URL

Event: `multiverse.apprenticeship.summary_updated.v2`

```bash
bash ~/.cursor/skills/fetch-multiverse-techdocs/scripts/fetch-docs.sh --event multiverse.apprenticeship.summary_updated.v2
gh api repos/Multiverse-io/platform/contents/catalog-info.yaml --jq '.content' | base64 -d | rg summary_updated
rg 'summary_updated' ~/Desktop/MV_Dev/*/catalog-info.yaml
```

### “What is rabbitmq_ops?”

```bash
bash ~/.cursor/skills/fetch-multiverse-techdocs/scripts/fetch-docs.sh Multiverse-io/rabbitmq_ops docs/index.md
```

### “How does this event interact with other services?”

Follow the **Event service-interaction workflow** above. Start with schema + catalog,
then grep code for undeclared producers/consumers and read handler side effects.

---

## Do not

- Scrape `reef.tech-tools.multiverse.io` with WebFetch/browser (SSO required).
- Assume a local clone is up to date without fetching from GitHub first.
- Silently fall back to local clones without telling the user auth failed.
- Treat Reef's consumer list as complete without code search for non-trivial questions.
- Answer behavioural/contract questions from a doc without confirming against GitHub. If the
  doc turns out stale, don't just work around it — pause and offer a doc-fix PR (Step 6).
