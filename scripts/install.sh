#!/usr/bin/env bash
# Install skills from this repo into the agent directories you choose.
#
# Examples:
#   ./scripts/install.sh --universal
#   ./scripts/install.sh --agent claude
#   ./scripts/install.sh --agent claude --agent codex --agent opencode
#   ./scripts/install.sh --agent all
#   ./scripts/install.sh --agent claude --copy
#
# When more than one agent is selected (or --universal is used), skills are
# placed in ~/.agents/skills/ as the canonical source and symlinked into each
# chosen agent directory. When only one agent is selected, skills are installed
# directly into that agent's skills directory.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"

CANONICAL_DIR="$HOME/.agents/skills"

# Parallel arrays of agent aliases and their default skill directories.
AGENT_NAMES=(
  claude
  claude-code
  codex
  opencode
  kimi
  kimi-code
  cursor
  gemini
)
AGENT_DIRS=(
  "$HOME/.claude/skills"
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
  "$HOME/.config/opencode/skills"
  "$CANONICAL_DIR"
  "$CANONICAL_DIR"
  "$HOME/.cursor/skills"
  "$HOME/.gemini/skills"
)

usage() {
  cat <<'EOF'
Usage: install.sh [options] [skill-name]

Install skills from this repo into the agent directories you choose.
Run without options for an interactive prompt.

Options:
  --agent <agent>   Target agent. Can be repeated. Supported:
                    claude, claude-code, codex, opencode,
                    kimi, kimi-code, cursor, gemini, all
  --universal       Install into ~/.agents/skills/ only
  --copy            Copy skills instead of symlinking
  -l, --list        List available skills and exit
  -h, --help        Show this help

Examples:
  ./scripts/install.sh                          # interactive mode
  ./scripts/install.sh --universal
  ./scripts/install.sh --agent claude
  ./scripts/install.sh --agent claude --agent codex --agent opencode
  ./scripts/install.sh --agent all
  ./scripts/install.sh --agent claude agnes-generate-image

When multiple agents are selected (or --universal is used), skills are placed
in ~/.agents/skills/ and symlinked into each chosen agent directory.
When only one agent is selected, skills are installed directly into that agent.
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

resolve_agent_dir() {
  local agent="$1"
  for i in "${!AGENT_NAMES[@]}"; do
    if [[ "${AGENT_NAMES[$i]}" == "$agent" ]]; then
      echo "${AGENT_DIRS[$i]}"
      return 0
    fi
  done
  return 1
}

interactive_select_agents() {
  # Distinct agents shown to the user (aliases like claude-code share a dir).
  local choices=("claude" "codex" "opencode" "kimi" "cursor" "gemini")

  echo ""
  echo "Which agents do you want to install skills for?"
  local i=1
  for c in "${choices[@]}"; do
    echo "  $i) $c"
    i=$((i + 1))
  done
  echo "  0) all of the above"
  echo "  u) ~/.agents/skills/ only (universal)"
  echo ""

  read -rp "Enter choices (comma/space separated, e.g. 1,3,5 or 0 or u): " raw_input
  local input
  input=$(echo "$raw_input" | tr ',' ' ' | tr -s ' ')

  if [[ "$input" =~ ^[Uu]$ ]]; then
    UNIVERSAL=1
    return
  fi

  if [[ "$input" == "0" || "$input" == "all" ]]; then
    SELECTED_AGENTS+=("all")
    return
  fi

  for token in $input; do
    if [[ "$token" =~ ^[0-9]+$ ]]; then
      local idx=$((token - 1))
      if [[ "$idx" -ge 0 && "$idx" -lt ${#choices[@]} ]]; then
        SELECTED_AGENTS+=("${choices[$idx]}")
      else
        echo "Invalid choice: $token" >&2
        exit 1
      fi
    else
      # Allow typing agent names directly as well.
      SELECTED_AGENTS+=("$token")
    fi
  done
}

SELECTED_AGENTS=()
UNIVERSAL=0
COPY=0
SKILL_NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent)
      SELECTED_AGENTS+=("$2")
      shift 2
      ;;
    --universal)
      UNIVERSAL=1
      shift
      ;;
    --copy)
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

# If no target selected, enter interactive mode when stdin is a TTY.
if [[ ${#SELECTED_AGENTS[@]} -eq 0 && "$UNIVERSAL" -eq 0 ]]; then
  if [[ -t 0 ]]; then
    interactive_select_agents
  else
    echo "No target agent selected. Use --agent or --universal, or run interactively." >&2
    usage >&2
    exit 1
  fi
fi

# Validate agents
for a in ${SELECTED_AGENTS[@]+"${SELECTED_AGENTS[@]}"}; do
  if [[ "$a" == "all" ]]; then
    continue
  fi
  if ! resolve_agent_dir "$a" >/dev/null; then
    echo "Unknown agent: $a" >&2
    echo "Supported agents: ${AGENT_NAMES[*]} all" >&2
    exit 1
  fi
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

# Resolve final target directories.
TARGET_DIRS=()
if [[ ${#SELECTED_AGENTS[@]} -eq 0 ]]; then
  # Only --universal was used.
  TARGET_DIRS+=("$CANONICAL_DIR")
elif [[ " ${SELECTED_AGENTS[*]} " == *" all "* ]]; then
  TARGET_DIRS=("${AGENT_DIRS[@]}")
else
  for a in "${SELECTED_AGENTS[@]}"; do
    dir=$(resolve_agent_dir "$a")
    TARGET_DIRS+=("$dir")
  done
fi

# Deduplicate target dirs while preserving order.
UNIQUE_TARGETS=()
for dir in "${TARGET_DIRS[@]}"; do
  found=0
  for existing in ${UNIQUE_TARGETS[@]+"${UNIQUE_TARGETS[@]}"}; do
    if [[ "$existing" == "$dir" ]]; then
      found=1
      break
    fi
  done
  if [[ "$found" -eq 0 ]]; then
    UNIQUE_TARGETS+=("$dir")
  fi
done

# Decide whether to use canonical (.agents) as the hub.
USE_CANONICAL=0
if [[ "$UNIVERSAL" -eq 1 || ${#UNIQUE_TARGETS[@]} -gt 1 ]]; then
  USE_CANONICAL=1
fi

install_skill() {
  local src="$1"
  local dest_dir="$2"
  local name=$(basename "$src")
  local dest="$dest_dir/$name"

  mkdir -p "$dest_dir"
  if [[ -e "$dest" || -L "$dest" ]]; then
    rm -rf "$dest"
  fi

  if [[ "$COPY" -eq 1 ]]; then
    cp -R "$src" "$dest"
    echo "  copied $name"
  else
    ln -sfn "$src" "$dest"
    echo "  linked $name"
  fi
}

if [[ "$USE_CANONICAL" -eq 1 ]]; then
  # Install skills into canonical directory first.
  echo "Installing into canonical directory: $CANONICAL_DIR"
  for src in "${SKILL_DIRS[@]}"; do
    install_skill "$src" "$CANONICAL_DIR"
  done

  # Symlink into every non-canonical target directory.
  for target in "${UNIQUE_TARGETS[@]}"; do
    if [[ "$target" == "$CANONICAL_DIR" ]]; then
      continue
    fi
    echo "Symlinking into: $target"
    for src in "${SKILL_DIRS[@]}"; do
      name=$(basename "$src")
      canonical_entry="$CANONICAL_DIR/$name"
      mkdir -p "$target"
      dest="$target/$name"
      if [[ -e "$dest" || -L "$dest" ]]; then
        rm -rf "$dest"
      fi
      ln -sfn "$canonical_entry" "$dest"
      echo "  linked $name"
    done
  done
else
  # Single target: install directly.
  target="${UNIQUE_TARGETS[0]}"
  echo "Installing into: $target"
  for src in "${SKILL_DIRS[@]}"; do
    install_skill "$src" "$target"
  done
fi
