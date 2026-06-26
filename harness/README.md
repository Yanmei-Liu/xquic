# Agent Harness

Platform-agnostic source for AI coding agent skills, commands, and project instructions.

## Architecture

```
harness/
├── skills/                  # Skill definitions (SKILL.md per skill)
│   ├── validate/            # Build + test validation
│   ├── gh-pr-review/        # GitHub PR review
│   ├── gh-fix-ci/           # CI failure diagnosis
│   ├── gh-address-comments/ # PR comment resolution
│   ├── issue/               # Issue triage pipeline
│   └── xquic-safe-push/     # Safe git push workflow
├── commands/                # Slash commands
│   └── goal.md              # Background goal launcher
├── templates/
│   └── PROJECT_INSTRUCTIONS.md  # Project instruction template
└── README.md                # This file
```

## Installation

```bash
# Install for a specific platform
./scripts/install_harness.sh claude
./scripts/install_harness.sh codex
./scripts/install_harness.sh qoder

# Install for all platforms
./scripts/install_harness.sh all

# Preview without making changes
./scripts/install_harness.sh claude --dry-run

# Remove installed files
./scripts/install_harness.sh claude --clean
```

## Platform Mapping

| Source | Claude Code | Codex CLI | Qoder |
|--------|------------|-----------|-------|
| `harness/skills/*/SKILL.md` | `.claude/skills/*/SKILL.md` | `.codex/skills/*/SKILL.md` | `.qoder/skills/*/SKILL.md` |
| `harness/commands/*.md` | `.claude/commands/*.md` | N/A (use skills) | N/A |
| `harness/templates/PROJECT_INSTRUCTIONS.md` | `CLAUDE.md` | `AGENTS.md` | `AGENTS.md` |
| (generated) | — | `.codex/config.toml` | `.qoder/rules/xquic-project.md` |

## Design Principles

1. **Single source of truth**: All skill/command logic lives in `harness/` and is committed to git.
2. **Platform directories are gitignored**: `.claude/`, `.codex/`, `.qoder/` are generated artifacts.
3. **Idempotent installation**: Run `install_harness.sh` after any edit to `harness/`.
4. **Knowledge base is universal**: `docs_ai/` is consumed by all platforms directly — no installation needed.
5. **SKILL.md format is cross-platform**: Same frontmatter (name + description) works across Claude/Codex/Qoder.

## Adding a New Skill

1. Create `harness/skills/<skill-name>/SKILL.md` with YAML frontmatter:
   ```yaml
   ---
   name: skill-name
   description: When to use this skill and what it does.
   ---
   ```
2. Add optional `openai.yaml` for Codex UI metadata.
3. Run `./scripts/install_harness.sh <platform>` to deploy.

## Updating Project Instructions

Edit `harness/templates/PROJECT_INSTRUCTIONS.md`, then re-run the installer.
The template is copied as `CLAUDE.md` (for Claude) or `AGENTS.md` (for Codex/Qoder).

## Platform Details

### Claude Code
- Reads `CLAUDE.md` at project root + module-level `CLAUDE.md` files in subdirectories
- Skills in `.claude/skills/{name}/SKILL.md`, commands in `.claude/commands/{name}.md`
- Hooks via `.claude/settings.json`

### OpenAI Codex CLI
- Reads `AGENTS.md` from project root down to CWD (concatenated)
- Skills in `.codex/skills/{name}/SKILL.md` with optional `agents/openai.yaml`
- Config in `.codex/config.toml`, can set `project_doc_fallback_filenames = ["CLAUDE.md"]`

### Qoder
- Reads `AGENTS.md` at project root (auto-detected, no config needed)
- Skills in `.qoder/skills/{name}/SKILL.md` (project-level) or `~/.qoder/skills/` (user-level)
- Rules in `.qoder/rules/` (project-level, "always active" type)
- Hooks via `~/.qoder/settings.json` (PreToolUse, PostToolUse, etc.)
- CLI: `qodercli`
