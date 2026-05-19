---
name: platform-prodscript-review-playbook
description: >
  Review and manually validate Platform prodscripts (lib/platform/prod_scripts)
  against a local anonymised production database snapshot. Use when writing,
  reviewing, or testing a prodscript, mix gen.prodscript, or Platform.ProdScripts
  modules in the Multiverse platform repo.
---

# Platform prodscript review playbook

Prodscripts are one-off data migration / fix scripts run in production via the
Platform admin UI (`Platform.ProdScripts.*`). They live under
`lib/platform/prod_scripts/` and are generated with `mix gen.prodscript`.

This playbook sets up a **safe local loop**: anonymised prod data as a
checkpoint (`platform_dev`), a working copy for destructive runs
(`platform_dev_restored`), backup/restore between iterations, and manual
validation before merge.

**Repository context**: Multiverse `platform` repo. Run shell commands from the
repo root unless stated otherwise.

---

## Step 0: Opt in

**Pause** and use `AskQuestion` (or ask conversationally if unavailable):

> Do you want to follow the **prodscript review playbook** for this session?

Briefly explain:

- It prepares an anonymised local copy of production data, keeps a clean
  checkpoint database, and walks through backup → test → restore cycles so you
  can validate the prodscript safely before it ships.

If the user declines, stop following this skill unless they ask again.

---

## Step 1: Confirm the database is not in use

**Pause** before any destructive or restore operations.

Confirm with the user that **no process is using the local Platform database**:

- Platform web server / `mix phx.server` is stopped
- No DB viewer (TablePlus, pgAdmin, etc.) is connected to `platform_dev` or
  `platform_dev_restored`
- No other app or test runner is connected

Offer choices via `AskQuestion` where possible:

1. **I'll disconnect now** — wait for confirmation, then continue
2. **Help me find and kill connections** — list Postgres connections (e.g.
   `psql postgres -c "SELECT pid, datname, application_name, state FROM pg_stat_activity WHERE datname LIKE 'platform%';"`)
   and, only if the user confirms, terminate them (e.g. `pg_terminate_backend(pid)`)

Do not run `copy_anonymised_db`, restore, or drop/create databases until the
user confirms the DB is free.

---

## Step 2: Anonymised production snapshot

Ask whether they already have an **anonymised copy of the latest S3 production
database snapshot** loaded locally.

### If they do **not**

From the platform repo root, run:

```bash
./scripts/copy_anonymised_db platform
```

(`copy_anonymised_db` targets `platform_dev` by default; the `platform` argument
matches team conventions when multiple DB copy scripts exist.)

Remind them: shut down the Platform server first (the script also warns about
this).

### If they **do**

Ask:

1. Is the snapshot **up to date** with the latest anonymised S3 backup they need?
2. Do they already have a **backup** of the current local state? If yes, **what
   is it saved as** (e.g. `platform_dev.bak` from `./scripts/backup_local_platform_db`)?

If they do not have a current backup, create one:

```bash
./scripts/backup_local_platform_db backup
```

Default backup file: `platform_dev.bak` in the repo root (see `scripts/README.md`).

---

## Step 3: Checkpoint vs working database

Establish this convention for the rest of the playbook:

| Database | Role |
|----------|------|
| **`platform_dev`** | Source of truth / checkpoint — anonymised prod snapshot. Do **not** run the prodscript against this DB except when refreshing from S3. |
| **`platform_dev_restored`** | Working copy — restore from backup here, run and iterate on the prodscript here. |

If `platform_dev_restored` does not exist yet, create it by restoring from the
backup into a separate database name (clone from `platform_dev` or restore backup
into `platform_dev_restored` — use the project's usual Postgres workflow).

When running the app or `mix` tasks against the working copy, set
`DATABASE_NAME=platform_dev_restored` (or equivalent in `config/dev.exs` /
shell env) so `platform_dev` stays clean.

---

## Step 4: Manual testing loop

Guide the user to **manually test** the prodscript:

1. Cover **happy path**, **edge cases**, and **invalid args** (mirror
   `test/platform/prod_scripts/*_test.exs` but validate against real anonymised
   shape/volume).
2. Use **preview/1** if implemented — confirm the summary matches expectations
   before `script/1` runs.
3. After each test run that mutates data, **restore** the working database from
   backup:
   ```bash
   ./scripts/backup_local_platform_db restore
   ```
   (Adjust if their backup targets `platform_dev_restored` — document the exact
   command they use.)
4. **Iterate** on the script until results match expectations.

Encourage running unit tests in parallel:

```bash
mix test test/platform/prod_scripts/<script_name>_test.exs
```

---

## Step 5: Real production data (non-anonymised)

**Pause** and ask explicitly:

> Do you need any data that can **only** be obtained from the **real production**
> database (non-anonymised)?

- If **no**: continue with PR review / merge guidance only.
- If **yes**: do **not** pull non-anonymised data into local dev without explicit
  user approval and company policy. Outline approved options (bastion read-only
  query, staging repro, ticket for infra) and stop short of copying PII locally.

---

## Reference

- Generate scaffold: `mix gen.prodscript <name>`
- Scripts: `scripts/copy_anonymised_db`, `scripts/backup_local_platform_db`
- Docs: `techdocs/getting-started.md` (prodscript section), `scripts/README.md`
