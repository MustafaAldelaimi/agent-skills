#!/usr/bin/env bash
# Fetch latest TechDocs or event schema markdown/YAML from Multiverse-io GitHub (main).
#
# Usage:
#   fetch-docs.sh Multiverse-io/platform                    # list mkdocs nav + component name
#   fetch-docs.sh Multiverse-io/platform docs/setup.md      # fetch one file
#   fetch-docs.sh --event multiverse.foo.bar.v2             # fetch event schema
#
# Requires: gh CLI authenticated with read access to Multiverse-io.

set -euo pipefail

REEF_BASE="https://reef.tech-tools.multiverse.io"

gh_auth_hint() {
  echo "Run: gh auth login -h github.com" >&2
  echo "If Multiverse-io uses SSO: gh auth refresh -s read:org" >&2
}

ensure_gh_auth() {
  if ! gh auth status &>/dev/null; then
    echo "ERROR: GitHub CLI is not authenticated." >&2
    gh auth status >&2 || true
    gh_auth_hint
    exit 2
  fi
}

gh_cat() {
  local repo="$1" path="$2"
  local api_output exit_code=0

  api_output="$(gh api "repos/${repo}/contents/${path}" --jq '.content' 2>&1)" || exit_code=$?

  if [[ "$exit_code" -ne 0 ]]; then
    if echo "$api_output" | rg -qi '401|403|forbidden|bad credentials|not authenticated'; then
      echo "ERROR: GitHub API auth failed fetching ${repo}/${path}." >&2
      gh auth status >&2 || true
      gh_auth_hint
      exit 2
    fi

    echo "ERROR: Failed to fetch ${repo}/${path}: ${api_output}" >&2
    exit 1
  fi

  if [[ -z "$api_output" || "$api_output" == "null" ]]; then
    echo "ERROR: Empty response fetching ${repo}/${path} (file may not exist on main)." >&2
    exit 1
  fi

  echo "$api_output" | base64 -d
}

event_to_schema_path() {
  local event="$1"
  # multiverse.namespace.name.vN -> schemas/namespace/name/vN.yaml
  local rest="${event#multiverse.}"
  local version="${rest##*.v}"
  local without_version="${rest%.v*}"
  local namespace="${without_version%%.*}"
  local name="${without_version#*.}"
  echo "schemas/${namespace}/${name}/v${version}.yaml"
}

fetch_event() {
  local event="$1"
  local path reef_url
  path="$(event_to_schema_path "$event")"
  reef_url="${REEF_BASE}/catalog/default/event/${event}"

  echo "Event: ${event}"
  echo "Schema: Multiverse-io/event-schemas/${path}"
  echo "Reef: ${reef_url}"
  echo "---"
  gh_cat "Multiverse-io/event-schemas" "$path"
}

list_repo_docs() {
  local repo="$1"
  local catalog mkdocs docs_dir

  catalog="$(gh_cat "$repo" "catalog-info.yaml")"

  local component
  component="$(echo "$catalog" | rg '^  name:' | head -1 | sed 's/^  name: //')"

  mkdocs="$(gh_cat "$repo" "mkdocs.yml" 2>/dev/null || gh_cat "$repo" "mkdocs.yaml" 2>/dev/null || true)"
  if [[ -z "$mkdocs" ]]; then
    echo "Component: ${component}"
    echo "Reef: ${REEF_BASE}/docs/default/component/${component}"
    echo "No mkdocs.yml found." >&2
    exit 1
  fi

  docs_dir="$(echo "$mkdocs" | rg '^docs_dir:' | head -1 | sed 's/^docs_dir: *"\?\([^"]*\)"\?/\1/' || echo "docs")"

  echo "Repo: ${repo}"
  echo "Component: ${component}"
  echo "Docs dir: ${docs_dir}"
  echo "Reef: ${REEF_BASE}/docs/default/component/${component}"
  echo ""
  echo "mkdocs nav:"
  echo "$mkdocs" | sed -n '/^nav:/,$p'
}

main() {
  ensure_gh_auth

  if [[ "${1:-}" == "--event" ]]; then
    [[ -n "${2:-}" ]] || { echo "Usage: fetch-docs.sh --event multiverse.namespace.name.vN" >&2; exit 1; }
    fetch_event "$2"
    exit 0
  fi

  local repo="${1:-}"
  local file="${2:-}"

  [[ -n "$repo" ]] || {
    echo "Usage: fetch-docs.sh OWNER/REPO [path/to/file.md]" >&2
    echo "       fetch-docs.sh --event multiverse.namespace.name.vN" >&2
    exit 1
  }

  if [[ -n "$file" ]]; then
    echo "Fetching ${repo}/${file} (main)..."
    echo "---"
    gh_cat "$repo" "$file"
  else
    list_repo_docs "$repo"
  fi
}

main "$@"
