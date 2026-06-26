#!/bin/bash
# goal.sh -- Launch a background Claude Code agent for a long-running task.
#
# Usage:
#   ./scripts/goal.sh "Implement feature X"
#   ./scripts/goal.sh --attach <session-id>
#   ./scripts/goal.sh --list
#   ./scripts/goal.sh --stop <session-id>
#
# The agent reads CLAUDE.md and follows project rules automatically.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

usage() {
    cat <<'EOF'
Usage:
  goal.sh "<task description>"     Start a background goal
  goal.sh --list                   List all running goals
  goal.sh --attach <id>            Attach to a running goal
  goal.sh --logs <id>              View goal output
  goal.sh --stop <id>              Stop a running goal
  goal.sh --stop-all               Stop all running goals
  goal.sh --respawn <id>           Restart a goal with context
EOF
    exit 1
}

if [ $# -eq 0 ]; then
    usage
fi

case "${1:-}" in
    --list)
        claude agents
        ;;
    --attach)
        [ -z "${2:-}" ] && { echo "Error: session id required"; exit 1; }
        claude attach "$2"
        ;;
    --logs)
        [ -z "${2:-}" ] && { echo "Error: session id required"; exit 1; }
        claude logs "$2"
        ;;
    --stop)
        [ -z "${2:-}" ] && { echo "Error: session id required"; exit 1; }
        claude stop "$2"
        ;;
    --stop-all)
        claude agents --json 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for s in data:
        print(s.get('id', ''))
except:
    pass
" | while read -r sid; do
            [ -n "$sid" ] && claude stop "$sid" 2>/dev/null && echo "Stopped: $sid"
        done
        ;;
    --respawn)
        [ -z "${2:-}" ] && { echo "Error: session id required"; exit 1; }
        claude respawn "$2"
        ;;
    --help|-h)
        usage
        ;;
    *)
        TASK_DESC="$*"

        echo "=== Starting Goal ==="
        echo "Task: $TASK_DESC"
        echo "Project: $PROJECT_DIR"
        echo ""

        claude --bg \
            --permission-mode auto \
            "You are working on the xquic_ops project at $PROJECT_DIR.
Read AGENTS.md first to understand task routing and project rules.
Then execute the following goal autonomously:

$TASK_DESC

Follow the appropriate workflow based on task type:
- Code change: follow docs_ai/dev_pipeline.md
- Bug fix: follow docs_ai/bugfix_pipeline.md
- Test execution: follow docs_ai/validation_guide.md
- Build: follow docs_ai/validation_guide.md

When done, summarize what was accomplished."

        echo ""
        echo "=== Goal Dispatched ==="
        echo "Commands:"
        echo "  claude agents          -- list all goals"
        echo "  claude logs <id>       -- check output"
        echo "  claude attach <id>     -- take over"
        echo "  claude stop <id>       -- cancel"
        ;;
esac
