#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

find "$REPO_ROOT/skills" -maxdepth 1 -mindepth 1 -type d | sort | while read -r d; do
  name=$(basename "$d")
  if [[ -f "$d/SKILL.md" ]]; then
    echo "$name"
  fi
done
