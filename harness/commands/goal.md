Start a background goal-directed long task for the xquic project.

Usage: /goal <task description>

Arguments: $ARGUMENTS

Instructions:

1. Parse the task description from $ARGUMENTS.
2. Read the project instruction file (CLAUDE.md or AGENTS.md) to determine the task type (code change / test execution / build / query).
3. Run the goal as a background agent using the Bash tool:

```
bash scripts/goal.sh "<task description>"
```

4. Report back the session ID and how to check progress:
   - List all running goals
   - Check output/logs
   - Attach interactively
   - Stop/cancel

If $ARGUMENTS is empty, ask the user what goal to run.
