#!/usr/bin/env bash
# Install skills from this repo into agent skill directories.
# Global install uses ~/.agents/skills/ as the single source of truth
# and mirrors symlinks into ~/.claude/skills/, ~/.codex/skills/, etc.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"

CANONICAL_DIR="$HOME/.agents/skills"
TARGET_DIRS=(
  "$HOME/.claude/skills"
  "$HOME/.config/opencode/skills"
  "$HOME/.codex/skills"
  "$HOME/.cursor/skills"
  "$HOME/.gemini/skills"
)

ALL_PROJECT_DIRS=(
  ".claude/skills"
  ".opencode/skills"
  ".codex/skills"
  ".agents/skills"
  ".cursor/skills"
  ".gemini/skills"
)

usage() {
  cat <<'EOF'
Usage: install.sh [options] [skill-name]

Install skills from this repo into agent skill directories.

Options:
  -a, --agent <agent>   Target agent: claude, claude-code, opencode, codex,
                        kimi, kimi-code, cursor, gemini, all (default: all)
  -g, --global          Install to the global canonical directory (~/.agents/skills)
                        and mirror symlinks into other agent directories (default)
  -p, --project         Install to project-local agent directories
  -c, --copy            Copy instead of symlink
  -l, --list            List available skills and exit
  -h, --help            Show this help

Global install always keeps ~/.agents/skills/ as the single source of truth.
Run it whenever you add or remove skills to keep all agents in sync.
EOF
}

list_skills() {
  find "$SKILLS_DIR" -maxdepth 1 -mindepth 1 -type d | sort | while read -r d; do
    name=$(basename "$d")
    if [[ -f "$d/SKILL.md" ]]; then
      echo "  - $name"
    fi
  done
}

resolve_agent_index() {
  case "$1" in
    claude|claude-code) echo 0 ;;
    opencode) echo 1 ;;
    codex) echo 2 ;;
    kimi|kimi-code) echo 3 ;;
    cursor) echo 4 ;;
    gemini) echo 5 ;;
    *) echo -1 ;;
  esac
}

AGENT="all"
SCOPE="global"
COPY=0
SKILL_NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -a|--agent)
      AGENT="$2"
      shift 2
      ;;
    -g|--global)
      SCOPE="global"
      shift
      ;;
    -p|--project)
      SCOPE="project"
      shift
      ;;
    -c|--copy)
      COPY=1
      shift
      ;;
    -l|--list)
      list_skills
      exit 0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [[ -z "$SKILL_NAME" ]]; then
        SKILL_NAME="$1"
      else
        echo "Only one skill name may be specified." >&2
        exit 1
      fi
      shift
      ;;
  esac
done

# Resolve source skill directories
SKILL_DIRS=()
if [[ -n "$SKILL_NAME" ]]; then
  if [[ ! -d "$SKILLS_DIR/$SKILL_NAME" ]]; then
    echo "Skill '$SKILL_NAME' not found in $SKILLS_DIR" >&2
    exit 1
  fi
  if [[ ! -f "$SKILLS_DIR/$SKILL_NAME/SKILL.md" ]]; then
    echo "Directory '$SKILL_NAME' does not contain a SKILL.md file." >&2
    exit 1
  fi
  SKILL_DIRS+=("$SKILLS_DIR/$SKILL_NAME")
else
  while IFS= read -r d; do
    SKILL_DIRS+=("$d")
  done < <(find "$SKILLS_DIR" -maxdepth 1 -mindepth 1 -type d | sort)
fi

if [[ ${#SKILL_DIRS[@]} -eq 0 ]]; then
  echo "No skills found in $SKILLS_DIR" >&2
  exit 1
fi

install_to_dir() {
  local target="$1"
  mkdir -p "$target"
  echo "Installing into $target"
  for src in "${SKILL_DIRS[@]}"; do
    name=$(basename "$src")
    dest="$target/$name"
    if [[ -e "$dest" || -L "$dest" ]]; then
      rm -rf "$dest"
    fi
    if [[ "$COPY" -eq 1 ]]; then
      cp -R "$src" "$dest"
      action="copied"
    else
      ln -sfn "$src" "$dest"
      action="linked"
    fi
    echo "  $action $name"
  done
}

if [[ "$SCOPE" == "global" ]]; then
  # Install into the canonical global directory first.
  install_to_dir "$CANONICAL_DIR"

  # Then keep all supported agent directories in sync as symlinks.
  echo ""
  echo "Mirroring canonical skills into other agent directories..."
  "$SCRIPT_DIR/sync_global_skills.sh"
else
  # Project-local install: link/copy directly into project-local agent dirs.
  if [[ "$AGENT" == "all" ]]; then
    for d in "${ALL_PROJECT_DIRS[@]}"; do
      install_to_dir "$REPO_ROOT/$d"
    done
  else
    idx=$(resolve_agent_index "$AGENT")
    if [[ "$idx" -lt 0 ]]; then
      echo "Unknown agent: $AGENT" >&2
      usage >&2
      exit 1
    fi
    install_to_dir "$REPO_ROOT/${ALL_PROJECT_DIRS[$idx]}"
  fi
fi
