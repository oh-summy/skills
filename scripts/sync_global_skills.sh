#!/usr/bin/env bash
# Keep ~/.agents/skills/ as the single source of truth for global skills
# and mirror symlinks into other supported agent skill directories.
set -euo pipefail

CANONICAL="$HOME/.agents/skills"
TARGETS=(
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
  "$HOME/.config/opencode/skills"
  "$HOME/.cursor/skills"
  "$HOME/.gemini/skills"
)

BACKUP_DIR="$HOME/.skills-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$CANONICAL"

echo "Canonical source: $CANONICAL"
echo "Backup dir (if needed): $BACKUP_DIR"
echo ""

# Step 1: Adopt any real directories from target dirs into canonical if canonical is missing them.
for target in "${TARGETS[@]}"; do
  [[ -d "$target" ]] || continue
  for entry in "$target"/*; do
    [[ -e "$entry" || -L "$entry" ]] || continue
    name=$(basename "$entry")
    [[ "$name" == .* ]] && continue
    canonical_entry="$CANONICAL/$name"

    if [[ -d "$entry" && ! -L "$entry" && ! -e "$canonical_entry" ]]; then
      echo "Adopting '$name' from $target into canonical"
      mv "$entry" "$canonical_entry"
    fi
  done
done

# Step 2: Sync canonical skills to every target directory as symlinks.
for target in "${TARGETS[@]}"; do
  mkdir -p "$target"
  echo "Syncing $target"

  # Remove entries that are not symlinks to canonical.
  for entry in "$target"/*; do
    [[ -e "$entry" || -L "$entry" ]] || continue
    name=$(basename "$entry")
    [[ "$name" == .* ]] && continue
    canonical_entry="$CANONICAL/$name"

    if [[ -L "$entry" ]]; then
      current=$(readlink "$entry")
      if [[ "$current" != "$canonical_entry" ]]; then
        echo "  Replacing stale symlink: $name"
        rm "$entry"
      fi
    else
      # Real directory/file that conflicts with canonical. Back it up.
      if [[ ! -e "$canonical_entry" ]]; then
        echo "  Adopting and backing up: $name"
        mv "$entry" "$canonical_entry"
      else
        echo "  Backing up conflicting: $name"
        mkdir -p "$BACKUP_DIR"
        mv "$entry" "$BACKUP_DIR/$name"
      fi
    fi
  done

  # Create/update symlinks for every canonical skill.
  for entry in "$CANONICAL"/*; do
    [[ -e "$entry" || -L "$entry" ]] || continue
    name=$(basename "$entry")
    [[ "$name" == .* ]] && continue
    canonical_entry="$CANONICAL/$name"
    target_entry="$target/$name"

    if [[ -L "$target_entry" ]]; then
      current=$(readlink "$target_entry")
      if [[ "$current" == "$canonical_entry" ]]; then
        continue
      fi
    fi
    ln -sfn "$canonical_entry" "$target_entry"
    echo "  Linked: $name"
  done
done

echo ""
echo "Scanning canonical skills for absolute paths that may reference old agent dirs..."
if grep -R -n -E "(\.claude|\.codex|\.opencode|\.cursor|\.gemini|\.cc-switch)/skills" "$CANONICAL" 2>/dev/null; then
  echo "Found absolute path references above. Review and update them if needed."
else
  echo "No obvious absolute path references found."
fi

echo ""
echo "Done. Global skills are now centralized under $CANONICAL."
