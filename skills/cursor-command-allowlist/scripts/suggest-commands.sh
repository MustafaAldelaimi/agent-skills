#!/usr/bin/env bash
# suggest-commands.sh — READ-ONLY candidate detector for the Cursor terminal
# allowlist. Surfaces frequently-used + repo-declared commands so the agent can
# classify them (harmless vs needs-approval) per SKILL.md. This script writes
# nothing and classifies nothing — judgement stays with the agent.
#
# Usage: suggest-commands.sh [workspace_dir] [top_n]
#   workspace_dir  directory to scan for declared scripts/tasks (default: $PWD)
#   top_n          how many history entries to show (default: 40)

set -uo pipefail

WORKSPACE="${1:-$PWD}"
TOP_N="${2:-40}"
case "$TOP_N" in
  ''|*[!0-9]*) TOP_N=40 ;;
esac

echo "# ─────────────────────────────────────────────────────────────────────"
echo "# Frequently used commands (shell history, first two tokens)"
echo "#   count  command"
echo "# ─────────────────────────────────────────────────────────────────────"
{
  for hist in "$HOME/.zsh_history" "$HOME/.bash_history"; do
    [ -f "$hist" ] || continue
    # zsh extended history lines look like ': 1700000000:0;<cmd>' — strip prefix.
    sed -E 's/^: [0-9]+:[0-9]+;//' "$hist" 2>/dev/null
  done
} \
  | sed -E 's/^[[:space:]]+//' \
  | grep -vE '^(#|$)' \
  | awk '{ if (NF>=2) print $1, $2; else if (NF==1) print $1 }' \
  | sort | uniq -c | sort -rn | head -n "$TOP_N"

echo
echo "# ─────────────────────────────────────────────────────────────────────"
echo "# Declared commands in: $WORKSPACE"
echo "# ─────────────────────────────────────────────────────────────────────"

if [ -f "$WORKSPACE/package.json" ]; then
  echo "## package.json scripts  (run as: yarn <name>  /  npm run <name>)"
  if command -v jq >/dev/null 2>&1; then
    jq -r '.scripts // {} | keys[]' "$WORKSPACE/package.json" 2>/dev/null | sed 's/^/  /'
  else
    grep -oE '"[A-Za-z0-9:_-]+"[[:space:]]*:' "$WORKSPACE/package.json" | tr -d '":' | sed 's/^/  /'
  fi
  echo
fi

for tf in Taskfile.yml Taskfile.dist.yml Taskfile.yaml; do
  if [ -f "$WORKSPACE/$tf" ]; then
    echo "## $tf tasks  (run as: task <name>)"
    grep -E '^[[:space:]]{2}[A-Za-z0-9_:-]+:' "$WORKSPACE/$tf" | sed -E 's/:.*$//; s/^[[:space:]]*/  /' | sort -u
    echo
  fi
done

if [ -f "$WORKSPACE/mix.exs" ]; then
  echo "## mix.exs aliases  (run as: mix <name>)"
  grep -oE '"[a-z0-9_.]+":' "$WORKSPACE/mix.exs" | tr -d '":' | sed 's/^/  /' | sort -u
  echo
fi

echo "# ─────────────────────────────────────────────────────────────────────"
echo "# Next: classify each candidate with the SKILL.md 'harmless test'."
echo "# ADD only read-only / reversible, subcommand-granular entries."
echo "# NEVER add: destructive (rm, git push, *migrate), wrappers (rtk, sudo,"
echo "#   xargs, env, npx), bare multiplexers (git, yarn, npm, mix, task), or"
echo "#   file-content readers (cat, grep, head)."
echo "# ─────────────────────────────────────────────────────────────────────"
