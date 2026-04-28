#!/bin/bash
# install-codex-prompt.sh
# Installs the skill-tree-generator SKILL.md as a Codex CLI custom prompt.
# After running this, you can trigger /skill-tree-generator inside Codex CLI,
# the same way you would in Claude Code.
#
# Usage:
#   ./scripts/install-codex-prompt.sh
#   ./scripts/install-codex-prompt.sh --dest /custom/path   # override destination

set -euo pipefail

# Resolve repo root (directory above this script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SRC="$REPO_ROOT/skill-tree-generator/SKILL.md"

DEST_DIR="${HOME}/.codex/prompts"
if [[ $# -ge 2 && "$1" == "--dest" ]]; then
    DEST_DIR="$2"
    shift 2
fi

if [[ ! -f "$SRC" ]]; then
    echo "ERROR: cannot find source $SRC" >&2
    echo "       Run this script from inside the skills repo checkout." >&2
    exit 1
fi

mkdir -p "$DEST_DIR"
DEST="$DEST_DIR/skill-tree-generator.md"

# Strip Claude Code–specific frontmatter (the first YAML block delimited by ---)
# Codex custom prompts do not consume the name/description/argument-hint fields,
# and leaving them in would show up as literal text when the prompt is invoked.
awk '
    BEGIN { in_fm = 0; seen_end = 0 }
    NR == 1 && /^---[[:space:]]*$/ { in_fm = 1; next }
    in_fm && /^---[[:space:]]*$/  { in_fm = 0; seen_end = 1; next }
    in_fm { next }
    { print }
' "$SRC" > "$DEST"

echo "Installed Codex custom prompt:"
echo "  source: $SRC"
echo "  dest:   $DEST"
echo ""
echo "Now in Codex CLI you can invoke:"
echo "  /skill-tree-generator <args>"
