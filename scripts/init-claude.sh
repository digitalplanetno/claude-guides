#!/bin/bash
# init-claude.sh — Initialize Claude Code configuration for a project
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/[user]/claude-guides/main/scripts/init-claude.sh | bash
#   # or
#   ./init-claude.sh [framework]
#
# Frameworks: laravel, nextjs, auto (default)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://raw.githubusercontent.com/digitalplanetno/claude-guides/main"
CLAUDE_DIR=".claude"
PROMPTS_DIR="$CLAUDE_DIR/prompts"

echo -e "${BLUE}Claude Code Configuration Initializer${NC}"
echo "========================================"
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

# Templates to download
TEMPLATES=(
    "SECURITY_AUDIT.md"
    "PERFORMANCE_AUDIT.md"
    "CODE_REVIEW.md"
    "DEPLOY_CHECKLIST.md"
)

# Determine template path based on framework
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

echo -e "${YELLOW}Downloading templates from $TEMPLATE_PATH...${NC}"

# Download templates
for template in "${TEMPLATES[@]}"; do
    echo -n "  - $template... "

    # Try to download, fall back to base if framework-specific doesn't exist
    if curl -fsSL "$REPO_URL/$TEMPLATE_PATH/$template" -o "$PROMPTS_DIR/$template" 2>/dev/null; then
        echo -e "${GREEN}OK${NC}"
    elif curl -fsSL "$REPO_URL/templates/base/$template" -o "$PROMPTS_DIR/$template" 2>/dev/null; then
        echo -e "${YELLOW}OK (base template)${NC}"
    else
        echo -e "${RED}FAILED${NC}"
    fi
done

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

- **Security Audit:** \`/SECURITY_AUDIT\` or read \`.claude/prompts/SECURITY_AUDIT.md\`
- **Performance Audit:** \`/PERFORMANCE_AUDIT\` or read \`.claude/prompts/PERFORMANCE_AUDIT.md\`
- **Code Review:** \`/CODE_REVIEW\` or read \`.claude/prompts/CODE_REVIEW.md\`
- **Deploy Checklist:** \`/DEPLOY_CHECKLIST\` or read \`.claude/prompts/DEPLOY_CHECKLIST.md\`

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

# Create .gitignore entries if needed
if [ -f ".gitignore" ]; then
    if ! grep -q ".claude/reports" .gitignore 2>/dev/null; then
        echo "" >> .gitignore
        echo "# Claude Code reports (optional - may contain sensitive info)" >> .gitignore
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
echo "  └── reports/"
echo "  CLAUDE.md"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Edit CLAUDE.md to add project-specific instructions"
echo "2. Customize templates in .claude/prompts/ for your project"
echo "3. Run audits: read the prompt file and follow instructions"
echo ""
echo -e "${GREEN}Happy coding!${NC}"
