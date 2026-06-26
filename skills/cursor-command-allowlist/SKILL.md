---
name: cursor-command-allowlist
description: >-
  Use when the user wants Cursor's local agent to run terminal commands more
  hands-off without approving every one — "stop asking me to approve commands",
  "allowlist this", "auto-run safe commands", "make Cursor less interruptive",
  "I keep approving the same command" — or when you hit a repeated approval
  prompt for a harmless command. Safely grows the Cursor terminal allowlist in
  permissions.json: classifies commands as harmless (read-only / reversible) vs
  needs-approval, adds only the harmless ones, and NEVER allowlists destructive,
  wrapper, or bare-multiplexer commands. Read-only on classification; only ever
  edits permissions.json.
---

# Cursor command allowlist

Make the local Cursor agent hands-off for safe commands while keeping a hard floor under destructive ones. The lever is `permissions.json`'s `terminalAllowlist`, plus `autoRun` steering for the long tail.

The goal: a friction the user pays today (approving `yarn test` for the 20th time) should not be paid tomorrow — without ever auto-running something that deletes data or rewrites history.

## Hard guardrails (read first)

- **The allowlist BYPASSES every other check.** An allowlisted entry auto-runs with **no sandbox and no classifier**. Matching is a **case-sensitive prefix**. So an entry is only safe if it is harmless for **every possible argument suffix**. `autoRun.block_instructions` do **not** protect an allowlisted prefix.
- **Never allowlist these** (no exceptions):
  - **Destructive / irreversible:** `rm`, `rmdir`, `trash`, `git push`, `git reset`, `git rebase`, `git clean`, `git commit --amend`, `mix ecto.reset/drop/migrate`, `prisma migrate`, `prisma db push`, `terraform apply/destroy`, `kubectl apply/delete`, `docker push`, `npm publish`, `gh pr merge`, `gh release create`.
  - **Wrappers that execute an arbitrary inner command:** `rtk`, `sudo`, `env`, `xargs`, `nohup`, `time`, `watch`, `npx`/`yarn dlx` (bare), `bash -c`, `sh -c`, `ssh`.
  - **Bare multiplexers** (some subcommands are destructive): `git`, `yarn`, `npm`, `pnpm`, `mix`, `task`, `docker`, `kubectl`, `gh`, `cargo`. Allowlist the **specific safe subcommand** (`git status`, not `git`).
  - **Arbitrary file-content readers** (secret-exfil risk — the suffix is an open file path): `cat`, `head`, `tail`, `grep`, `rg`, `bat`, `less`. The agent reads files via the Read/Grep tools anyway, which don't need terminal approval.
- **Allowlist is NOT a security boundary** (Cursor says so). It is convenience. The real backstop is the protection toggles — see [Keep protections on](#keep-protections-on).
- **Edit only `permissions.json`.** This skill does not change Run Mode, toggles, project code, or other config. Classification is judgement; the only write is the allowlist.
- **When unsure, leave it off.** A command that prompts is a minor annoyance; a wrongly-allowlisted one is a silent risk. Default to exclusion.

## The harmless test

A command is allowlist-safe only if **all** hold:

1. **Read-only or reversible.** It inspects, or its only writes are build output / formatting / staging that git can undo. (`git status`, `yarn test`, `tsc`, `mix format`.)
2. **Safe for any suffix.** Appending arbitrary args can't make it dangerous. (Fails for `cat`, `git remote`, `gh api`, `find` — `find . -delete` exists.)
3. **Not a wrapper.** It doesn't take another command as its argument.

If any fail → it stays off the allowlist (it still runs via the Auto-review classifier, just with a prompt).

Borderline calls:
- `git add` — reversible staging → **allowed**. `git commit` / `git push` → **off** (the user should see commits land).
- `mix format` / `yarn lint:fix` / `prettier` — auto-fixers that only rewrite tracked source → **allowed** (git is the undo).
- `git fetch` — read-only network → **allowed**. `git pull` → **off** (can merge/conflict).
- `docker logs` / `kubectl logs` — useful but can print secrets → opt-in only, never by default.

## permissions.json mechanics

Two locations, **concatenated** (not overridden) when both exist:

```text
~/.cursor/permissions.json            # per-user, applies everywhere
<workspace>/.cursor/permissions.json  # per-repo, commit to share with the team
```

- Defining `terminalAllowlist` **replaces** the in-app Settings allowlist entirely (the UI editor goes read-only). Per-user ∪ per-repo entries still merge.
- **JSONC** (comments) is supported and re-read live on save.
- Only takes effect when **Run Mode = Auto-review** (or Allowlist / Run Everything). `autoRun.*_instructions` are consulted **only in Auto-review**.

Allowlist entry format (case-sensitive prefix):

| Entry | Auto-runs |
| --- | --- |
| `git` | **everything** starting `git` — including `git push` ❌ never do this |
| `git status` | `git status` and `git status …` ✅ |
| `npm:install*` | `npm install`, `npm install express` (`:` = base + args glob) |

**Gotcha — env-var prefixes break matching.** `MIX_ENV=test mix credo` does *not* match `mix credo` (it starts with `MIX_ENV`). Add the explicit form as its own entry.

**Gotcha — redirections & compounds ride along.** The match is on the leading command, so an allowlisted prefix still auto-runs trailing `> file`, `&&`, `;`, or `|` (`git status && rm -rf x` prefix-matches `git status`; `echo x > tracked.ts` clobbers via an allowlisted `echo`). This can't be fixed in the allowlist — it's why [protections](#keep-protections-on) must stay on (in-workspace clobbers are git-reversible; deletes and out-of-workspace writes are blocked by the toggles).

`autoRun` (Auto-review long tail, for non-allowlisted commands):

```jsonc
{
  "autoRun": {
    "allow_instructions": ["Read-only inspections … are fine."],
    "block_instructions": ["Anything that deletes files … must be approved first."]
  }
}
```

## Workflow

### 1. Find candidates

Run the read-only detector to surface frequently-used + repo-declared commands:

```bash
bash ~/.cursor/skills/cursor-command-allowlist/scripts/suggest-commands.sh [workspace_dir] [top_n]
```

It prints shell-history frequency (first two tokens, e.g. `git status`, `yarn test`) plus declared `package.json` scripts, `Taskfile` tasks, and `mix.exs` aliases. It classifies nothing — that's the next step. You can also use commands the user just approved repeatedly in this session.

### 2. Classify each candidate

Apply [The harmless test](#the-harmless-test). Keep the harmless ones at **subcommand granularity** (`git status`, not `git`). Discard destructive / wrapper / bare-multiplexer / file-reader candidates.

### 3. Add to the right file

- General-purpose safe commands → `~/.cursor/permissions.json` (per-user).
- Repo-specific commands the team should share → `<workspace>/.cursor/permissions.json` (commit it).

Merge into the existing `terminalAllowlist` (dedupe; preserve JSONC comments — edit in place, don't regenerate). If neither file exists, create the per-user one. Group entries with comments by tool for future readers.

### 4. Report

Tell the user, briefly: which entries were added, to which file, and any candidates you **rejected and why** (the rejections are the valuable part). Confirm the prerequisites in the next section are set.

## Keep protections on

The allowlist is prefix-naive (`git status && rm -rf x` prefix-matches `git status`). These do the real enforcing — confirm they're set (the user toggles them; this skill can't):

- **Run Mode = Auto-review** — `Settings → Agents → Approvals & Execution`. Required for `permissions.json` to apply at all.
- **File-Deletion Protection = ON** — forces approval for `rm`/deletions even inside an allowlisted compound command.
- **External-File Protection = ON** — forces approval for writes outside the workspace.

If the user wants genuinely hands-off, irreversible-safe autonomy, point them at **Cloud Agents** (isolated VM, PR handoff) or a **git worktree** — isolation, not allowlisting, is the safe path for that.

## Ongoing use

Fire this skill whenever the user approves the same harmless command repeatedly, or says any trigger phrase. Add the one command, report it, move on. Small, frequent, additive edits — not a big upfront list.

## Anti-patterns

- Allowlisting a bare multiplexer/wrapper "to save time" → re-read [Hard guardrails](#hard-guardrails-read-first).
- Regenerating `permissions.json` from scratch and dropping the user's comments/entries → always merge in place.
- Adding `git commit`/`git push` because the agent commits a lot → commits/pushes should stay visible.
- Treating `block_instructions` as protection for an allowlisted prefix → it isn't; the allowlist bypasses it.

## Related skills

| Skill | Relationship |
| --- | --- |
| [raise-pr](../raise-pr/) | If sharing a per-repo allowlist with the team, commit + PR it via raise-pr mechanics. |
| [propose-skill-improvement](../propose-skill-improvement/) | If a new class of safe command keeps recurring, propose encoding it into this skill's taxonomy. |
