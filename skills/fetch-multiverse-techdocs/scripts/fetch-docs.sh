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

gh_cat() {
  local repo="$1" path="$2"
  gh api "repos/${repo}/contents/${path}" --jq '.content' 2>/dev/null | base64 -d
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
  local path
  path="$(event_to_schema_path "$event")"
  echo "Event: ${event}"
  echo "Schema: Multiverse-io/event-schemas/${path}"
  echo "---"
  gh_cat "Multiverse-io/event-schemas" "$path"
}

list_repo_docs() {
  local repo="$1"
  local catalog mkdocs docs_dir

  catalog="$(gh_cat "$repo" "catalog-info.yaml" 2>/dev/null || true)"
  if [[ -z "$catalog" ]]; then
    echo "No catalog-info.yaml in ${repo}" >&2
    exit 1
  fi

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
