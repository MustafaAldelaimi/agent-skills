# Org map (cache)

Dynamically generated, then cached. Not a hand-maintained directory.

This file is the only durable artefact the `corpo-standup-waffle` skill produces. The skill reads it before any MCP/`gh` lookups, regenerates entries that are missing or stale, and writes the result back. **Never present a stale entry as ground truth.**

## Why dynamic, not hand-typed

Orgs re-org. Catalog files drift. Hand-typed contact lists rot within months and then leak into AI-generated standup scripts as confident lies. Instead:

1. **Discover** from live sources (`gh`, Slack, Linear).
2. **Verify** against a second live signal (CODEOWNERS, recent commit authors, actual Slack channel activity).
3. **Cache** here with `Last verified` + `Source / confidence`.
4. **Refresh** entries older than 30 days, or on any lookup failure.

## Discovery procedure

Prior art: `surfbot` (`Multiverse-io/surfbot`) builds an `owner → repos` map by scanning every org repo's `catalog-info.yaml` `spec.owner` (e.g. `group:crocodiles`) and resolves channels via the `ask-{owner}` convention (`owner_fetcher.py`, `channel_config.py`). surfbot has no queryable API — this skill **replicates the approach** rather than calling it.

### A. Service → owning team

```bash
# Single repo
gh api repos/Multiverse-io/<repo>/contents/catalog-info.yaml --jq '.content' \
  | base64 -d | yq '.spec.owner'

# Strip "group:" / "team:" prefix from the result.
```

For a project that touches many repos, iterate the repo list once and cache the owner per repo.

### B. Verify the owner is current

`catalog-info.yaml` can be **stale** (re-orgs land in CODEOWNERS and commit history before anyone updates the catalog). Always corroborate:

```bash
# CODEOWNERS for the path that actually matters
gh api repos/Multiverse-io/<repo>/contents/CODEOWNERS --jq '.content' | base64 -d

# Recent committers on the specific file/dir
gh api "repos/Multiverse-io/<repo>/commits?path=<path>&per_page=20" \
  --jq '.[].author.login'
```

If `catalog-info.yaml` says team A but CODEOWNERS + recent commits both say team B, prefer the live signal and put both in `Notes:` with the discrepancy flagged.

### C. Team → Slack channel

```
slack_search_channels { query: "ask-<owner>" }   # convention first
slack_search_channels { query: "<owner>" }       # fallback
```

Record `#channel` + the channel id (Slack ids look like `C0XXXXXX`).

### D. People & handles

```
slack_search_users      { query: "<first name>" }
slack_read_user_profile { user: "<U-id>" }       # to confirm role/title
list_users              {}                        # Linear
get_user                { id: "<u-id>" }          # Linear, for a specific assignee
```

Cross-reference Linear `list_teams` for the team's Linear name/key (it often differs from the catalog `spec.owner`).

### E. Name normalization (re-org)

Old `spec.owner` slugs may still use the April-2026-pre-reorg animal/fish names (e.g. `seadragons`, `crocodiles`, `anchovies`). Cross-reference the `re-org-migration` skill's mapping table so both old and new names resolve to the same entry. Record both as aliases:

```
### dp-learner (was: seadragons)
- Aliases: seadragons
- ...
```

### F. What NOT to rely on

- **`kind: Group` Backstage entities** with `members` and `slack` fields are not in the per-repo `catalog-info.yaml` files — they live in the central Reef catalog. Don't depend on them being present locally; derive people/channels via Slack/Linear instead.
- **surfbot's in-memory map** isn't queryable from outside the bot. Replicate its catalog-info scan; don't try to call surfbot.

## Per-entry shape

Append entries under `## Cache` below in this exact shape:

```markdown
### <Team / function name>
- Aliases: <old-name>, <other-name>           # for re-org-pre-2026 slugs; omit if none
- Owns: <services / repo paths>               # what they're responsible for
- Slack: #<channel> (<C0XXXXXX>)              # primary team channel
- Key people: <First Last> (@handle, <role>); <First Last> (@handle, <role>)
- Linear team: <name> (<KEY>)
- Typical asks: <one-liner — e.g. "schema/event review", "DWH model owner">
- Source / confidence: <catalog | CODEOWNERS | gh-commits | slack | linear | user-confirmed>
- Last verified: <YYYY-MM-DD>
- Notes: <discrepancies, gotchas — e.g. "catalog says X, CODEOWNERS says Y; prefer Y">
```

`Source / confidence` lists every signal that corroborates the entry. A single-source entry (e.g. `catalog`) is weakest; `CODEOWNERS + gh-commits + user-confirmed` is strongest.

## Staleness

- Entries older than **30 days** are stale on read — re-verify before using.
- Any lookup that fails → re-verify and rewrite the entry on the spot.
- A discrepancy between sources is not a staleness signal; it's a `Notes:` flag.

## Promotion

This file lives inside the skill for portability. If other skills (e.g. `request-review`) want to reuse the cache, promote it to a shared location (e.g. `docs/work/org-map.md` in the consuming repo) and have both skills read/write the same path.

## Cache

(Empty on first install. Populated by the skill on first use — see Discovery procedure above.)

### Seeds (team-level, unverified)

Below are **un-verified seeds**. They name teams that commonly appear in standup chase-lists in this user's projects so the skill has discovery targets on first run. **Treat all fields below as TBC until verified live.** First real use of the skill must overwrite each with `Last verified: <today>` + a confirmed `Source / confidence`.

```markdown
### dp-learner
- Aliases: seadragons
- Owns: aurora, user_home (per recent catalog-info)
- Slack: TBC — try ask-dp-learner / ask-seadragons
- Key people: TBC (discover via Slack/Linear)
- Linear team: Learner DP (SEA)
- Typical asks: skill-scan/PLA calc, learner-facing flows
- Source / confidence: catalog (unverified)
- Last verified: never
- Notes: April-2026 re-org renamed seadragons → dp-learner; verify both spellings against current CODEOWNERS.

### data-engineering
- Aliases:
- Owns: mv_data_ops_api, mv_data_warehouse
- Slack: TBC
- Key people: TBC
- Linear team: TBC
- Typical asks: DWH models, event ingestion, snowflake catalog
- Source / confidence: catalog (unverified)
- Last verified: never

### sync-learning-impact
- Aliases:
- Owns: client-xp
- Slack: TBC
- Key people: TBC
- Linear team: TBC
- Typical asks: recommendation logic, learner-experience pipelines
- Source / confidence: catalog (unverified)
- Last verified: never

### tech (Platform default owner)
- Aliases:
- Owns: platform (OTJ/fee paths without a dedicated CODEOWNERS entry)
- Slack: TBC
- Key people: TBC
- Linear team: TBC
- Typical asks: OTJ targets, PandaDoc fee logic, orientation/enrolment infra
- Source / confidence: catalog (unverified)
- Last verified: never
- Notes: "tech" is the Platform default. Confirm against CODEOWNERS for the specific path before chasing — there is usually a more specific squad.

### events-guild
- Aliases:
- Owns: event-schemas
- Slack: TBC
- Key people: TBC
- Linear team: TBC
- Typical asks: schema bumps, deprecations, contract reviews
- Source / confidence: catalog (unverified)
- Last verified: never

### workforce-diagnostics (WFD)
- Aliases: OTT
- Owns: Qualtrics non-DPT PLA surveys; Aurora admin skill-scan statements + funding adjustments
- Slack: TBC
- Key people: TBC
- Linear team: TBC
- Typical asks: per-competency funding values, cut-off sign-off
- Source / confidence: user-context (unverified)
- Last verified: never
- Notes: WFD is the new name; OTT is the legacy name. Both still appear in chat.
```
