# Project Instructions - manage_app

This file is loaded automatically by Claude Code for this project. It points
to the project-specific standards files kept in `.agent/`.

## Reference files

- [.agent/agent-rules-code-standards.md](.agent/agent-rules-code-standards.md) -
  Coding standards for this project: SOLID/DRY/KISS/YAGNI, folder & naming
  conventions, widget reuse, file size limits, layer separation. Apply these
  during every code review and evaluation.
- [.agent/agent-rules-theme.md](.agent/agent-rules-theme.md) -
  Rules for working with Flutter theme extensions and context usage. Apply
  these whenever touching theme/design-token related code.
- [.agent/agent-rules-git-flow.md](.agent/agent-rules-git-flow.md) -
  Commit message format, branch naming, and push flow. Apply these when the
  user says "Let's push this change" - never commit/push proactively.
- [.agent/agent-rules-jira.md](.agent/agent-rules-jira.md) -
  Jira ticket workflow: use "check <ticket>" to fetch a ticket, analyze scope,
  create a plan, await approval, then implement with proper branching and
  committing per git flow rules.

Note: the user's global `~/.claude/CLAUDE.md` separately references
`AGENTS.md` and `THEMING_GUIDELINES.md` as canonical standard file names.
Those files do not exist in this repo - the two files above are the actual
standards in effect here until/unless that's reconciled.
