#!/bin/bash

# Claude Guides Initialization Script
# Usage: curl -sSL https://raw.githubusercontent.com/digitalplanetno/claude-guides/main/scripts/init-claude.sh | bash
# Or: curl -sSL ... | bash -s -- laravel
# Or: curl -sSL ... | bash -s -- --dry-run

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Config
REPO_URL="https://raw.githubusercontent.com/digitalplanetno/claude-guides/main"
CLAUDE_DIR=".claude"
DRY_RUN=false
FRAMEWORK=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        laravel|nextjs|base)
            FRAMEWORK="$1"
            shift
            ;;
        *)
            echo -e "${RED}Unknown argument: $1${NC}"
            exit 1
            ;;
    esac
done

# Detect framework if not specified
detect_framework() {
    if [[ -f "artisan" ]]; then
        echo "laravel"
    elif [[ -f "next.config.js" ]] || [[ -f "next.config.mjs" ]] || [[ -f "next.config.ts" ]]; then
        echo "nextjs"
    else
        echo "base"
    fi
}

if [[ -z "$FRAMEWORK" ]]; then
    FRAMEWORK=$(detect_framework)
fi

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Claude Guides Initialization       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "📁 Framework detected: ${GREEN}$FRAMEWORK${NC}"
echo -e "📂 Target directory: ${GREEN}$CLAUDE_DIR${NC}"
echo ""

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}🔍 DRY RUN - No files will be created${NC}"
    echo ""
fi

# Files to download
declare -a FILES=(
    # Core
    "templates/$FRAMEWORK/CLAUDE.md:CLAUDE.md"
    "templates/$FRAMEWORK/settings.json:settings.json"
    
    # Prompts
    "templates/$FRAMEWORK/SECURITY_AUDIT.md:prompts/SECURITY_AUDIT.md"
    "templates/$FRAMEWORK/PERFORMANCE_AUDIT.md:prompts/PERFORMANCE_AUDIT.md"
    "templates/$FRAMEWORK/CODE_REVIEW.md:prompts/CODE_REVIEW.md"
    "templates/$FRAMEWORK/DEPLOY_CHECKLIST.md:prompts/DEPLOY_CHECKLIST.md"
    
    # Agents
    "templates/base/agents/code-reviewer.md:agents/code-reviewer.md"
    "templates/base/agents/test-writer.md:agents/test-writer.md"
    "templates/base/agents/planner.md:agents/planner.md"
    
    # Commands
    "commands/plan.md:commands/plan.md"
    "commands/tdd.md:commands/tdd.md"
    "commands/context-prime.md:commands/context-prime.md"
    "commands/checkpoint.md:commands/checkpoint.md"
    "commands/handoff.md:commands/handoff.md"
    "commands/audit.md:commands/audit.md"
    "commands/test.md:commands/test.md"
    "commands/refactor.md:commands/refactor.md"
    "commands/doc.md:commands/doc.md"
    "commands/fix.md:commands/fix.md"
    "commands/explain.md:commands/explain.md"
)

# Add framework-specific files
if [[ "$FRAMEWORK" == "laravel" ]]; then
    FILES+=(
        "templates/laravel/agents/laravel-expert.md:agents/laravel-expert.md"
        "templates/laravel/skills/laravel/SKILL.md:skills/laravel/SKILL.md"
    )
elif [[ "$FRAMEWORK" == "nextjs" ]]; then
    FILES+=(
        "templates/nextjs/agents/nextjs-expert.md:agents/nextjs-expert.md"
        "templates/nextjs/skills/nextjs/SKILL.md:skills/nextjs/SKILL.md"
    )
fi

# Create directory structure
create_structure() {
    echo -e "${BLUE}📁 Creating directory structure...${NC}"
    
    local dirs=(
        "$CLAUDE_DIR"
        "$CLAUDE_DIR/prompts"
        "$CLAUDE_DIR/agents"
        "$CLAUDE_DIR/commands"
        "$CLAUDE_DIR/skills"
        "$CLAUDE_DIR/scratchpad"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ "$DRY_RUN" == true ]]; then
            echo "  Would create: $dir"
        else
            mkdir -p "$dir"
            echo -e "  ${GREEN}✓${NC} $dir"
        fi
    done
}

# Download files
download_files() {
    echo ""
    echo -e "${BLUE}📥 Downloading files...${NC}"
    
    for file_spec in "${FILES[@]}"; do
        IFS=':' read -r src dest <<< "$file_spec"
        local full_dest="$CLAUDE_DIR/$dest"
        local full_url="$REPO_URL/$src"
        
        # Create parent directory
        local parent_dir=$(dirname "$full_dest")
        
        if [[ "$DRY_RUN" == true ]]; then
            echo "  Would download: $src → $full_dest"
        else
            mkdir -p "$parent_dir"
            if curl -sSL "$full_url" -o "$full_dest" 2>/dev/null; then
                echo -e "  ${GREEN}✓${NC} $dest"
            else
                echo -e "  ${YELLOW}⚠${NC} $dest (using base template)"
                # Try base template as fallback
                local base_src="${src/templates\/$FRAMEWORK/templates\/base}"
                curl -sSL "$REPO_URL/$base_src" -o "$full_dest" 2>/dev/null || true
            fi
        fi
    done
}

# Create .gitignore
create_gitignore() {
    echo ""
    echo -e "${BLUE}📝 Creating .gitignore...${NC}"
    
    local gitignore="$CLAUDE_DIR/.gitignore"
    
    if [[ "$DRY_RUN" == true ]]; then
        echo "  Would create: $gitignore"
    else
        cat > "$gitignore" << 'GITIGNORE'
# Claude Code local files
scratchpad/
activity.log
audit.log
*.local.md
GITIGNORE
        echo -e "  ${GREEN}✓${NC} .gitignore"
    fi
}

# Create initial scratchpad
create_scratchpad() {
    echo ""
    echo -e "${BLUE}📋 Creating scratchpad template...${NC}"
    
    local scratchpad="$CLAUDE_DIR/scratchpad/current-task.md"
    
    if [[ "$DRY_RUN" == true ]]; then
        echo "  Would create: $scratchpad"
    else
        cat > "$scratchpad" << 'SCRATCHPAD'
# Current Task

## Description
[What are you working on?]

## Progress
- [ ] Phase 1
- [ ] Phase 2
- [ ] Phase 3

## Notes
[Any relevant notes]

## Blockers
- None
SCRATCHPAD
        echo -e "  ${GREEN}✓${NC} scratchpad/current-task.md"
    fi
}

# Main
main() {
    create_structure
    download_files
    create_gitignore
    create_scratchpad
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     ✅ Initialization Complete!        ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "Next steps:"
    echo -e "  1. Review and customize ${BLUE}$CLAUDE_DIR/CLAUDE.md${NC}"
    echo -e "  2. Update project-specific sections"
    echo -e "  3. Commit the ${BLUE}$CLAUDE_DIR${NC} directory"
    echo ""
    echo -e "Available commands:"
    echo -e "  ${YELLOW}/plan${NC}     — Create implementation plan"
    echo -e "  ${YELLOW}/tdd${NC}      — Test-driven development"
    echo -e "  ${YELLOW}/audit${NC}    — Run security/performance audit"
    echo ""
}

main
