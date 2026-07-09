#!/usr/bin/env bash
#
# model-lookup.sh
#
# Look up recommended models for an SDLC task type or quick alias.
#
# Usage:
#   ./scripts/model-lookup.sh write_plan
#   ./scripts/model-lookup.sh sprint_planning
#   ./scripts/model-lookup.sh --list
#
# Requires: bash, jq.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ROUTING_FILE="$REPO_ROOT/assets/sdlc-model-routing.json"

usage() {
  sed -n '/^# Usage:/,/^$/s/^# \{0,1\}//p' "$0"
  exit "${1:-0}"
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

command -v jq >/dev/null || die "jq not found in PATH"
[[ -f "$ROUTING_FILE" ]] || die "routing file not found: $ROUTING_FILE"

case "${1:-}" in
  -h|--help) usage 0 ;;
  --list)
    jq -r '.quick_lookup | to_entries[] | [.key, .value] | @tsv' "$ROUTING_FILE"
    exit 0
    ;;
  "") usage 2 ;;
esac

QUERY="$1"

TASK_TYPE="$(
  jq -r --arg query "$QUERY" '
    if .task_types[$query] then
      $query
    elif .quick_lookup[$query] then
      .quick_lookup[$query]
    else
      empty
    end
  ' "$ROUTING_FILE"
)"

[[ -n "$TASK_TYPE" ]] || die "unknown task type or alias: $QUERY"

jq -r --arg task_type "$TASK_TYPE" '
  .task_types[$task_type].recommended_models[]
  | [.rank, .provider, .model, .why]
  | @tsv
' "$ROUTING_FILE"
