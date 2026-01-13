#!/bin/bash
# init-local.sh — Initialize Claude Code configuration from local claude-guides
#
# Usage:
#   /path/to/claude-guides/scripts/init-local.sh [framework]
#
# Frameworks: laravel, nextjs, auto (default)

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUIDES_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CLAUDE_DIR=".claude"
PROMPTS_DIR="$CLAUDE_DIR/prompts"

echo -e "${BLUE}Claude Code Configuration Initializer (Local)${NC}"
echo "==============================================="
echo -e "Source: ${YELLOW}$GUIDES_DIR${NC}"
echo ""

# Detect framework
detect_framework() {
    if [ -f "artisan" ]; then
        echo "laravel"
    elif [ -f "next.config.js" ] || [ -f "next.config.ts" ] || [ -f "next.config.mjs" ]; then
        echo "nextjs"
    elif [ -f "package.json" ]; then
        echo "nodejs"
    else
        echo "generic"
    fi
}

FRAMEWORK=${1:-$(detect_framework)}
echo -e "Detected framework: ${GREEN}$FRAMEWORK${NC}"
echo ""

# Create directory structure
echo -e "${YELLOW}Creating directory structure...${NC}"
mkdir -p "$PROMPTS_DIR"
mkdir -p "$CLAUDE_DIR/reports"

# Templates to copy
TEMPLATES=(
    "SECURITY_AUDIT.md"
    "PERFORMANCE_AUDIT.md"
    "CODE_REVIEW.md"
    "DEPLOY_CHECKLIST.md"
)

# Determine template path based on framework
case $FRAMEWORK in
    laravel)
        TEMPLATE_PATH="$GUIDES_DIR/templates/laravel"
        ;;
    nextjs)
        TEMPLATE_PATH="$GUIDES_DIR/templates/nextjs"
        ;;
    *)
        TEMPLATE_PATH="$GUIDES_DIR/templates/base"
        ;;
esac

echo -e "${YELLOW}Copying templates from $TEMPLATE_PATH...${NC}"

# Copy templates
for template in "${TEMPLATES[@]}"; do
    echo -n "  - $template... "

    if [ -f "$TEMPLATE_PATH/$template" ]; then
        cp "$TEMPLATE_PATH/$template" "$PROMPTS_DIR/$template"
        echo -e "${GREEN}OK${NC}"
    elif [ -f "$GUIDES_DIR/templates/base/$template" ]; then
        cp "$GUIDES_DIR/templates/base/$template" "$PROMPTS_DIR/$template"
        echo -e "${YELLOW}OK (base template)${NC}"
    else
        echo -e "${RED}NOT FOUND${NC}"
    fi
done

# Copy commands if they exist
if [ -d "$GUIDES_DIR/commands" ]; then
    echo ""
    echo -e "${YELLOW}Copying commands...${NC}"
    mkdir -p "$CLAUDE_DIR/commands"

    for cmd in "$GUIDES_DIR/commands"/*.md; do
        if [ -f "$cmd" ]; then
            filename=$(basename "$cmd")
            cp "$cmd" "$CLAUDE_DIR/commands/$filename"
            echo -e "  - $filename... ${GREEN}OK${NC}"
        fi
    done
fi

# Create CLAUDE.md if it doesn't exist
if [ ! -f "CLAUDE.md" ]; then
    echo ""
    echo -e "${YELLOW}Creating CLAUDE.md...${NC}"

    PROJECT_NAME=$(basename "$(pwd)")

    cat > CLAUDE.md << EOF
# $PROJECT_NAME — Claude Code Instructions

## Project Overview

**Framework:** $FRAMEWORK
**Description:** [Brief description of the project]

---

## Key Directories

\`\`\`
[List your main directories and what they contain]
\`\`\`

---

## Development Workflow

### Running Locally
\`\`\`bash
# Add your local development commands
\`\`\`

### Testing
\`\`\`bash
# Add your test commands
\`\`\`

### Building
\`\`\`bash
# Add your build commands
\`\`\`

---

## Project-Specific Rules

1. [Add project-specific coding rules]
2. [Add architecture decisions]
3. [Add naming conventions]

---

## Available Prompts

Run audits and reviews using the prompts in \`.claude/prompts/\`:

- **Security Audit:** Read \`.claude/prompts/SECURITY_AUDIT.md\` and follow instructions
- **Performance Audit:** Read \`.claude/prompts/PERFORMANCE_AUDIT.md\` and follow instructions
- **Code Review:** Read \`.claude/prompts/CODE_REVIEW.md\` and follow instructions
- **Deploy Checklist:** Read \`.claude/prompts/DEPLOY_CHECKLIST.md\` and follow instructions

---

## Contacts

- **Maintainer:** [Your name]
- **Documentation:** [Link to docs]
EOF

    echo -e "  ${GREEN}Created CLAUDE.md${NC}"
else
    echo ""
    echo -e "${YELLOW}CLAUDE.md already exists, skipping...${NC}"
fi

# Add to .gitignore if needed
if [ -f ".gitignore" ]; then
    if ! grep -q ".claude/reports" .gitignore 2>/dev/null; then
        echo "" >> .gitignore
        echo "# Claude Code reports" >> .gitignore
        echo ".claude/reports/" >> .gitignore
        echo -e "${YELLOW}Added .claude/reports/ to .gitignore${NC}"
    fi
fi

echo ""
echo -e "${GREEN}Done!${NC}"
echo ""
echo "Created structure:"
echo "  .claude/"
echo "  ├── prompts/"
for template in "${TEMPLATES[@]}"; do
    echo "  │   ├── $template"
done
if [ -d "$GUIDES_DIR/commands" ]; then
    echo "  ├── commands/"
    echo "  │   └── ..."
fi
echo "  └── reports/"
echo "  CLAUDE.md"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Edit CLAUDE.md to add project-specific instructions"
echo "2. Customize templates in .claude/prompts/ for your project"
echo "3. Run audits by reading prompt files and following instructions"
echo ""
