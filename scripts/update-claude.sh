#!/bin/bash
# update-claude.sh — Update Claude Code templates to latest version
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/digitalplanetno/claude-guides/main/scripts/update-claude.sh | bash
#   # or
#   ./update-claude.sh [--dry-run] [--no-backup]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
REPO_URL="https://raw.githubusercontent.com/digitalplanetno/claude-guides/main"
CLAUDE_DIR=".claude"
PROMPTS_DIR="$CLAUDE_DIR/prompts"
BACKUP_DIR="$CLAUDE_DIR/backups"

# Flags
DRY_RUN=false
NO_BACKUP=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --no-backup)
            NO_BACKUP=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

echo -e "${BLUE}Claude Code Templates Updater${NC}"
echo "================================"
echo ""

# Check if .claude exists
if [ ! -d "$CLAUDE_DIR" ]; then
    echo -e "${RED}Error: $CLAUDE_DIR directory not found${NC}"
    echo "Run init-claude.sh first to initialize the project"
    exit 1
fi

# Detect framework
detect_framework() {
    if [ -f "artisan" ]; then
        echo "laravel"
    elif [ -f "next.config.js" ] || [ -f "next.config.ts" ] || [ -f "next.config.mjs" ]; then
        echo "nextjs"
    elif [ -f "manage.py" ]; then
        echo "django"
    elif [ -f "Gemfile" ] && grep -q "rails" Gemfile 2>/dev/null; then
        echo "rails"
    elif [ -f "go.mod" ]; then
        echo "golang"
    elif [ -f "Cargo.toml" ]; then
        echo "rust"
    elif [ -f "package.json" ]; then
        echo "nodejs"
    else
        echo "generic"
    fi
}

FRAMEWORK=$(detect_framework)
echo -e "Detected framework: ${GREEN}$FRAMEWORK${NC}"

# Determine template path
case $FRAMEWORK in
    laravel)
        TEMPLATE_PATH="templates/laravel"
        ;;
    nextjs)
        TEMPLATE_PATH="templates/nextjs"
        ;;
    *)
        TEMPLATE_PATH="templates/base"
        ;;
esac

# Templates to update
TEMPLATES=(
    "SECURITY_AUDIT.md"
    "PERFORMANCE_AUDIT.md"
    "CODE_REVIEW.md"
    "DEPLOY_CHECKLIST.md"
)

# Dry run mode
if [ "$DRY_RUN" = true ]; then
    echo ""
    echo -e "${YELLOW}DRY RUN MODE - No changes will be made${NC}"
    echo ""
    echo "Would update the following files:"
    for template in "${TEMPLATES[@]}"; do
        if [ -f "$PROMPTS_DIR/$template" ]; then
            echo "  - $PROMPTS_DIR/$template (update)"
        else
            echo "  - $PROMPTS_DIR/$template (create)"
        fi
    done
    echo ""
    echo "Source: $REPO_URL/$TEMPLATE_PATH/"
    exit 0
fi

# Create backup
if [ "$NO_BACKUP" = false ]; then
    BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_PATH="$BACKUP_DIR/$BACKUP_TIMESTAMP"

    echo -e "${YELLOW}Creating backup...${NC}"
    mkdir -p "$BACKUP_PATH"

    if [ -d "$PROMPTS_DIR" ]; then
        cp -r "$PROMPTS_DIR"/* "$BACKUP_PATH/" 2>/dev/null || true
        echo -e "  Backup saved to: ${GREEN}$BACKUP_PATH${NC}"
    fi
    echo ""
fi

# Download updated templates
echo -e "${YELLOW}Downloading updates from $TEMPLATE_PATH...${NC}"

UPDATED=0
FAILED=0

for template in "${TEMPLATES[@]}"; do
    echo -n "  - $template... "

    if curl -fsSL "$REPO_URL/$TEMPLATE_PATH/$template" -o "$PROMPTS_DIR/$template.new" 2>/dev/null; then
        # Check if file changed
        if [ -f "$PROMPTS_DIR/$template" ]; then
            if diff -q "$PROMPTS_DIR/$template" "$PROMPTS_DIR/$template.new" > /dev/null 2>&1; then
                rm "$PROMPTS_DIR/$template.new"
                echo -e "${BLUE}unchanged${NC}"
            else
                mv "$PROMPTS_DIR/$template.new" "$PROMPTS_DIR/$template"
                echo -e "${GREEN}updated${NC}"
                UPDATED=$((UPDATED + 1))
            fi
        else
            mv "$PROMPTS_DIR/$template.new" "$PROMPTS_DIR/$template"
            echo -e "${GREEN}created${NC}"
            UPDATED=$((UPDATED + 1))
        fi
    elif curl -fsSL "$REPO_URL/templates/base/$template" -o "$PROMPTS_DIR/$template.new" 2>/dev/null; then
        mv "$PROMPTS_DIR/$template.new" "$PROMPTS_DIR/$template"
        echo -e "${YELLOW}updated (base)${NC}"
        UPDATED=$((UPDATED + 1))
    else
        rm -f "$PROMPTS_DIR/$template.new"
        echo -e "${RED}failed${NC}"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo -e "${GREEN}Done!${NC}"
echo ""
echo "Summary:"
echo "  - Updated: $UPDATED"
echo "  - Failed: $FAILED"
if [ "$NO_BACKUP" = false ] && [ -d "$BACKUP_PATH" ]; then
    echo "  - Backup: $BACKUP_PATH"
fi
echo ""

if [ $FAILED -gt 0 ]; then
    echo -e "${YELLOW}Some updates failed. Check your internet connection.${NC}"
    exit 1
fi
