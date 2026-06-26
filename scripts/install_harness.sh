#!/usr/bin/env bash
#
# install_harness.sh — Install xquic agent harness for a specific AI coding platform.
#
# Usage:
#   ./scripts/install_harness.sh <platform>
#
# Platforms:
#   claude  — Claude Code (.claude/skills/, .claude/commands/, CLAUDE.md)
#   codex   — OpenAI Codex CLI (.codex/skills/, AGENTS.md)
#   qoder   — Qoder (.qoder/skills/, .qoder/rules/, AGENTS.md)
#   all     — Install for all platforms simultaneously
#
# What it does:
#   1. Copies skills from harness/skills/ to the platform-specific directory
#   2. Copies commands (if supported) to the platform-specific directory
#   3. Installs the project instruction file (CLAUDE.md / AGENTS.md)
#   4. Updates .gitignore to exclude platform-specific directories
#   5. Generates platform-specific config stubs (if needed)
#
# Idempotent: safe to run multiple times.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HARNESS_DIR="$PROJECT_ROOT/harness"

# Colors (disabled if not a terminal)
if [ -t 1 ]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BOLD='\033[1m'; NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BOLD=''; NC=''
fi

usage() {
    echo "Usage: $0 <platform>"
    echo ""
    echo "Platforms:"
    echo "  claude  — Claude Code"
    echo "  codex   — OpenAI Codex CLI"
    echo "  qoder   — Qoder"
    echo "  all     — All platforms"
    echo ""
    echo "Options:"
    echo "  --dry-run   Show what would be done without making changes"
    echo "  --clean     Remove installed harness files for the platform"
    exit 1
}

log_info()  { echo -e "${GREEN}[harness]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[harness]${NC} $*"; }
log_error() { echo -e "${RED}[harness]${NC} $*" >&2; }

DRY_RUN=false
CLEAN=false
PLATFORM=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --clean)   CLEAN=true; shift ;;
        claude|codex|qoder|all) PLATFORM="$1"; shift ;;
        -h|--help) usage ;;
        *) log_error "Unknown argument: $1"; usage ;;
    esac
done

[ -z "$PLATFORM" ] && usage

# Verify harness source exists
if [ ! -d "$HARNESS_DIR/skills" ]; then
    log_error "harness/skills/ not found. Run from project root."
    exit 1
fi

# -------------------------------------------------------------------
# Helper functions
# -------------------------------------------------------------------

ensure_dir() {
    if [ "$DRY_RUN" = true ]; then
        echo "  mkdir -p $1"
    else
        mkdir -p "$1"
    fi
}

copy_file() {
    local src="$1" dst="$2"
    if [ "$DRY_RUN" = true ]; then
        echo "  cp $src -> $dst"
    else
        cp "$src" "$dst"
    fi
}

copy_dir() {
    local src="$1" dst="$2"
    if [ "$DRY_RUN" = true ]; then
        echo "  cp -r $src -> $dst"
    else
        cp -r "$src" "$dst"
    fi
}

remove_path() {
    local target="$1"
    if [ ! -e "$target" ]; then return; fi
    if [ "$DRY_RUN" = true ]; then
        echo "  rm -rf $target"
    else
        rm -rf "$target"
    fi
}

ensure_gitignore() {
    local entry="$1"
    local gitignore="$PROJECT_ROOT/.gitignore"
    if [ ! -f "$gitignore" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "  echo '$entry' >> .gitignore (create)"
        else
            echo "$entry" > "$gitignore"
        fi
        return
    fi
    if ! grep -qxF "$entry" "$gitignore" 2>/dev/null; then
        if [ "$DRY_RUN" = true ]; then
            echo "  echo '$entry' >> .gitignore"
        else
            echo "$entry" >> "$gitignore"
        fi
    fi
}

# -------------------------------------------------------------------
# Platform installers
# -------------------------------------------------------------------

install_claude() {
    local skills_dir="$PROJECT_ROOT/.claude/skills"
    local commands_dir="$PROJECT_ROOT/.claude/commands"

    if [ "$CLEAN" = true ]; then
        log_info "Cleaning Claude Code harness..."
        remove_path "$PROJECT_ROOT/.claude"
        remove_path "$PROJECT_ROOT/CLAUDE.md"
        return
    fi

    log_info "Installing harness for Claude Code..."

    # Skills
    ensure_dir "$skills_dir"
    for skill_dir in "$HARNESS_DIR"/skills/*/; do
        local skill_name
        skill_name="$(basename "$skill_dir")"
        ensure_dir "$skills_dir/$skill_name"
        copy_file "$skill_dir/SKILL.md" "$skills_dir/$skill_name/SKILL.md"
    done

    # Commands
    ensure_dir "$commands_dir"
    for cmd_file in "$HARNESS_DIR"/commands/*.md; do
        [ -f "$cmd_file" ] || continue
        copy_file "$cmd_file" "$commands_dir/$(basename "$cmd_file")"
    done

    # Project instruction file
    copy_file "$HARNESS_DIR/templates/PROJECT_INSTRUCTIONS.md" "$PROJECT_ROOT/CLAUDE.md"

    # Gitignore
    ensure_gitignore ".claude/"

    log_info "Claude Code: .claude/skills/ + .claude/commands/ + CLAUDE.md installed"
}

install_codex() {
    local skills_dir="$PROJECT_ROOT/.codex/skills"

    if [ "$CLEAN" = true ]; then
        log_info "Cleaning Codex harness..."
        remove_path "$PROJECT_ROOT/.codex"
        # Don't remove AGENTS.md — it may be the canonical shared file
        return
    fi

    log_info "Installing harness for OpenAI Codex..."

    # Skills
    ensure_dir "$skills_dir"
    for skill_dir in "$HARNESS_DIR"/skills/*/; do
        local skill_name
        skill_name="$(basename "$skill_dir")"
        local target_dir="$skills_dir/$skill_name"
        ensure_dir "$target_dir"
        copy_file "$skill_dir/SKILL.md" "$target_dir/SKILL.md"
        # Codex uses agents/openai.yaml for UI metadata
        if [ -f "$skill_dir/openai.yaml" ]; then
            ensure_dir "$target_dir/agents"
            copy_file "$skill_dir/openai.yaml" "$target_dir/agents/openai.yaml"
        fi
    done

    # Codex config stub (enable reading CLAUDE.md as fallback)
    local config_file="$PROJECT_ROOT/.codex/config.toml"
    if [ ! -f "$config_file" ] || [ "$DRY_RUN" = true ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "  write $config_file"
        else
            ensure_dir "$PROJECT_ROOT/.codex"
            cat > "$config_file" << 'TOML'
# Codex project configuration
# Generated by install_harness.sh

[project]
# Also read CLAUDE.md if present (cross-tool compatibility)
project_doc_fallback_filenames = ["CLAUDE.md"]

[skills]
include_instructions = true
TOML
        fi
    fi

    # AGENTS.md as project instruction file (copy from template if not exists)
    if [ ! -f "$PROJECT_ROOT/AGENTS.md" ]; then
        copy_file "$HARNESS_DIR/templates/PROJECT_INSTRUCTIONS.md" "$PROJECT_ROOT/AGENTS.md"
    fi

    # Gitignore
    ensure_gitignore ".codex/"

    log_info "Codex: .codex/skills/ + .codex/config.toml + AGENTS.md installed"
}

install_qoder() {
    local skills_dir="$PROJECT_ROOT/.qoder/skills"
    local rules_dir="$PROJECT_ROOT/.qoder/rules"

    if [ "$CLEAN" = true ]; then
        log_info "Cleaning Qoder harness..."
        remove_path "$PROJECT_ROOT/.qoder"
        return
    fi

    log_info "Installing harness for Qoder..."

    # Skills (.qoder/skills/{skill-name}/SKILL.md)
    ensure_dir "$skills_dir"
    for skill_dir in "$HARNESS_DIR"/skills/*/; do
        local skill_name
        skill_name="$(basename "$skill_dir")"
        ensure_dir "$skills_dir/$skill_name"
        copy_file "$skill_dir/SKILL.md" "$skills_dir/$skill_name/SKILL.md"
    done

    # Rules (.qoder/rules/) — generate project rules from template
    ensure_dir "$rules_dir"
    local rules_file="$rules_dir/xquic-project.md"
    if [ ! -f "$rules_file" ] || [ "$DRY_RUN" = true ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "  write $rules_file"
        else
            cat > "$rules_file" << 'MARKDOWN'
# XQUIC Project Rules

## Task Routing

- Code changes: follow `docs_ai/dev_pipeline.md`
- Bug fixes: follow `docs_ai/bugfix_pipeline.md`
- Test/Build: follow `docs_ai/validation_guide.md`
- Queries: read code + `docs_ai/code_map.md`

## Coding Guidelines

- Use `snake_case` with `xqc_` prefix
- Comments explain "why", not "what"
- When modifying a module, update docs via `docs_ai/auto_doc_lookup.md`
- Non-trivial changes must include tests

## Key References

- Architecture: `docs_ai/architecture/overview.md`
- Code map: `docs_ai/code_map.md`
- Change obligations: `docs_ai/change_map.md`
- Behavior contracts: `docs_ai/behavior_specs.md`
- Build guide: `docs_ai/build/build_guide.md`
- Test guide: `docs_ai/testing/test_guide.md`
MARKDOWN
        fi
    fi

    # AGENTS.md (Qoder auto-detects this file)
    if [ ! -f "$PROJECT_ROOT/AGENTS.md" ]; then
        copy_file "$HARNESS_DIR/templates/PROJECT_INSTRUCTIONS.md" "$PROJECT_ROOT/AGENTS.md"
    fi

    # Gitignore
    ensure_gitignore ".qoder/"

    log_info "Qoder: .qoder/skills/ + .qoder/rules/ + AGENTS.md installed"
}

# -------------------------------------------------------------------
# Main
# -------------------------------------------------------------------

cd "$PROJECT_ROOT"

if [ "$DRY_RUN" = true ]; then
    log_warn "DRY RUN — no changes will be made"
    echo ""
fi

case "$PLATFORM" in
    claude) install_claude ;;
    codex)  install_codex ;;
    qoder)  install_qoder ;;
    all)
        install_claude
        install_codex
        install_qoder
        ;;
esac

echo ""
if [ "$DRY_RUN" = true ]; then
    log_info "Dry run complete. Re-run without --dry-run to apply."
elif [ "$CLEAN" = true ]; then
    log_info "Clean complete for platform: $PLATFORM"
else
    log_info "Installation complete for platform: $PLATFORM"
    log_info ""
    log_info "Canonical source: harness/ (committed to git)"
    log_info "Installed files:  platform-specific dirs (gitignored)"
    log_info ""
    log_info "To update after editing harness/, re-run:"
    log_info "  ./scripts/install_harness.sh $PLATFORM"
fi
