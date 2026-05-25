#!/bin/bash
# aggregate-skills.sh
# Scans a directory for skills and outputs the aggregate command for skill-tree-generator.
# Run this script first, then the target agent will use the output to invoke skill-tree-generator.
#
# Usage:
#   ./scripts/aggregate-skills.sh <skill-directory> [--domain <domain-name>] [--agent claude|codex|opencode|bitfun|openclaw|hermes]
#
# Examples:
#   ./scripts/aggregate-skills.sh .claude/skills
#   ./scripts/aggregate-skills.sh .opencode/skills --agent opencode
#   ./scripts/aggregate-skills.sh .agent/skills --agent codex
#   ./scripts/aggregate-skills.sh .bitfun/skills --agent bitfun
#   ./scripts/aggregate-skills.sh .openclaw/skills --agent openclaw
#   ./scripts/aggregate-skills.sh .hermes/skills --agent hermes
#   ./scripts/aggregate-skills.sh tasks/my-project/environment/skills --domain data-processing --agent codex

set -euo pipefail

SKILL_DIR="${1:?Usage: $0 <skill-directory> [--domain <domain-name>] [--agent claude|codex|opencode|bitfun|openclaw|hermes]}"
shift

DOMAIN=""
AGENT="claude"   # Default: backward-compatible with the original Claude Code behaviour
while [[ $# -gt 0 ]]; do
    case "$1" in
        --domain)
            DOMAIN="${2:?--domain requires a value}"
            shift 2
            ;;
        --agent)
            AGENT="${2:?--agent requires a value (claude|codex|opencode|bitfun|openclaw)}"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1" >&2
            echo "Usage: $0 <skill-directory> [--domain <domain-name>] [--agent claude|codex|opencode|bitfun|openclaw|hermes]" >&2
            exit 2
            ;;
    esac
done

case "$AGENT" in
    claude|codex|opencode|bitfun|openclaw|hermes) ;;
    *)
        echo "Unknown agent: $AGENT (use 'claude', 'codex', 'opencode', 'bitfun', 'openclaw', or 'hermes')" >&2
        exit 2
        ;;
esac

echo "=== Skill Scanner ==="
echo "Scanning: $SKILL_DIR"
echo "Agent:    $AGENT"
echo ""

# Find all SKILL.md files, skipping *-tree directories
SKILL_NAMES=()
while IFS= read -r -d '' file; do
    # Skip files inside *-tree directories (already structured)
    # Skip skill-tree-generator itself (meta skill, not a task skill)
    if [[ "$file" == *"-tree/"* ]] || [[ "$file" == *"skill-tree-generator"* ]]; then
        continue
    fi

    skill_dir=$(dirname "$file")

    # Skill name = directory name containing SKILL.md
    # Or filename if SKILL.md is directly in SKILL_DIR
    if [[ "$skill_dir" == "$SKILL_DIR" ]]; then
        skill_name=$(basename "$file" .md)
    else
        skill_name=$(basename "$skill_dir")
    fi

    echo "  - $skill_name"
    SKILL_NAMES+=("$skill_name")
done < <(find "$SKILL_DIR" -name "SKILL.md" -print0 2>/dev/null | sort -z)

count=${#SKILL_NAMES[@]}

if [[ $count -eq 0 ]]; then
    echo "No skills found in $SKILL_DIR"
    exit 1
fi

echo ""
echo "Found $count skill(s)"
echo ""

# Build the aggregate command
if [[ $count -eq 1 ]]; then
    CMD="/skill-tree-generator ${SKILL_NAMES[0]}"
else
    AGGREGATE_LIST=$(IFS=,; echo "${SKILL_NAMES[*]}")
    CMD="/skill-tree-generator --aggregate $AGGREGATE_LIST"
fi

if [[ -n "$DOMAIN" ]]; then
    CMD="$CMD --domain $DOMAIN"
fi

echo "=== Next Step ==="
case "$AGENT" in
    claude)
        echo "Run this slash command in Claude Code:"
        echo ""
        echo "  $CMD"
        echo ""
        echo "Output will be written to:"
        echo "  - $SKILL_DIR/{skill-name}-tree/"
        echo "  - <repo-root>/CLAUDE.md  (appended if it already exists)"
        ;;
    codex)
        echo "In Codex CLI, either:"
        echo ""
        echo "  (a) If you ran scripts/install-codex-prompt.sh, use the custom prompt:"
        echo ""
        echo "        $CMD"
        echo ""
        echo "  (b) Otherwise, paste this instruction into Codex directly:"
        echo ""
        echo "        Read $SKILL_DIR/skill-tree-generator/SKILL.md and execute:"
        echo "        $CMD"
        echo ""
        echo "Output will be written to:"
        echo "  - $SKILL_DIR/{skill-name}-tree/"
        echo "  - <repo-root>/AGENTS.md  (appended if it already exists)"
        ;;
    opencode)
        echo "In OpenCode, paste this instruction directly:"
        echo ""
        echo "        Read $SKILL_DIR/skill-tree-generator/SKILL.md and execute:"
        echo "        $CMD"
        echo ""
        echo "Output will be written to:"
        echo "  - $SKILL_DIR/{skill-name}-tree/"
        echo "  - <repo-root>/AGENTS.md  (appended if it already exists)"
        ;;
    bitfun)
        echo "In Bitfun, paste this instruction directly:"
        echo ""
        echo "        $CMD"
        echo ""
        echo "Output will be written to:"
        echo "  - $SKILL_DIR/{skill-name}-tree/"
        echo "  - <repo-root>/AGENTS.md  (appended if it already exists)"
        ;;
    openclaw)
        echo "In OpenClaw, paste this instruction directly:"
        echo ""
        echo "        $CMD"
        echo ""
        echo "Output will be written to:"
        echo "  - $SKILL_DIR/{skill-name}-tree/"
        echo "  - <repo-root>/AGENTS.md  (appended if it already exists)"
        ;;
    hermes)
        echo "In Hermes, paste this instruction directly:"
        echo ""
        echo "        $CMD"
        echo ""
        echo "Output will be written to:"
        echo "  - $SKILL_DIR/{skill-name}-tree/"
        echo "  - <repo-root>/AGENTS.md  (appended if it already exists)"
        ;;
esac
echo ""
