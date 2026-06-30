# Changelog

All notable changes to the Rami plugin are documented here. The version is the `version` field in `.claude-plugin/plugin.json`, which is the single source of truth that `/rami:upgrade` and the SessionStart update nudge compare against.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [2.3.0]

### Added

- `/rami:setup` — guided onboarding (GitHub App, MCP server, OAuth) as a first-class command, delegating to the `rami-setup-mcp` skill.
- `/rami:doctor` — read-only health check that probes authentication, GitHub App coverage, quota, and plugin version, then prints a checklist with the fix for each issue.
- `/rami:upgrade` — updates the plugin to the latest published version and shows what changed.
- SessionStart update nudge — a throttled (once/day), network-safe hook that surfaces a notification when the installed plugin is behind the latest version. Silent when up to date.
- Optional, consent-gated project-instructions addendum: `/rami:setup` can add a fenced, removable Rami section (the review-thread state-ownership rule) to the repo's `CLAUDE.md`/`AGENTS.md` — only when the user agrees.
- `CHANGELOG.md`.

### Fixed

- Corrected stale `/rami:status` references to `/rami:review-status` in the setup skill and the status command's auth instructions.

## [2.2.1]

- Forbid `gh` CLI and GitHub MCP for resolving Rami threads; Rami owns its review state via its MCP tools.
- Thin commands delegate to the `rami-code-review` skill (single source of truth for the review loop).
- Added rebut and setup skills; encoded Rami state-ownership rules.
- Codex plugin support.
