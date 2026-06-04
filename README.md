# agent-skills

Personal Cursor and Claude Code skills — versioned and synced from one repo.

## Skills

| Skill | Description | Origin |
|-------|-------------|--------|
| [create-linear-ticket](skills/create-linear-ticket/) | Create well-formed Linear issues with codebase context | [Multiverse-io/ai-rules#43](https://github.com/Multiverse-io/ai-rules/pull/43) |
| [raise-pr](skills/raise-pr/) | Raise PRs via `gh` with optional Bugbot review loop | [Multiverse-io/ai-rules#44](https://github.com/Multiverse-io/ai-rules/pull/44) |
| [platform-prodscript-review-playbook](skills/platform-prodscript-review-playbook/) | Safe local validation loop for Platform prodscripts | Custom (Multiverse platform repo) |
| [fetch-multiverse-techdocs](skills/fetch-multiverse-techdocs/) | Fetch latest TechDocs from GitHub (Reef source) for any Multiverse repo or event | Custom |
| [maintain-work-context](skills/maintain-work-context/) | Live project + daily work journal so agents stay context-aware | Custom |
| [request-review](skills/request-review/) | Draft `#dp-learner` Slack review pings (`:git_rereview_requested:` + PR links) | Custom |
| [corpo-standup-waffle](skills/corpo-standup-waffle/) | Generate an impromptu standup script from PROJECT.md/journal + read-only Linear/Slack/GitHub — output-only, never sends | Custom |
| [claw-work-activity](skills/claw-work-activity/) | Produce a dated, timestamped activity report from git/Linear/Slack (public + private + DMs) — caller-proposed, user-confirmed save to `docs/work/activity/YYYY-MM-DD.md` | Custom |

## Install (Cursor)

```bash
git clone https://github.com/MustafaAldelaimi/agent-skills.git ~/agent-skills
mkdir -p ~/.cursor/skills
for skill in ~/agent-skills/skills/*/; do
  ln -sfn "$skill" ~/.cursor/skills/"$(basename "$skill")"
done
```

Update later: `cd ~/agent-skills && git pull`

## Install (Claude Code)

```bash
mkdir -p ~/.claude/skills
for skill in ~/agent-skills/skills/*/; do
  ln -sfn "$skill" ~/.claude/skills/"$(basename "$skill")"
done
```

Or add per-project: symlink into `<repo>/.claude/skills/`.

## Per-project skills (optional)

To share with a team repo:

```bash
mkdir -p /path/to/your-repo/.cursor/skills
ln -sfn ~/agent-skills/skills/raise-pr /path/to/your-repo/.cursor/skills/raise-pr
```

## Attribution

`create-linear-ticket` and `raise-pr` are adapted from [Multiverse-io/ai-rules](https://github.com/Multiverse-io/ai-rules) (internal). Do not redistribute those if your employer restricts it.

`platform-prodscript-review-playbook` is specific to the Multiverse Platform repo workflows.

## License

MIT — see [LICENSE](LICENSE).
