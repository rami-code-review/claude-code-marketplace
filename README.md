<p align="center">
  <img src="https://rami.reviews/static/images/rami_logo_full.png" alt="Rami" width="200">
</p>

# Rami Code Review

AI-powered code review for your pull requests, integrated directly into Claude Code and Codex.

Rami analyzes your code changes for security vulnerabilities, bugs, performance issues, and more — then helps you fix them automatically.

## Getting Started

### 1. Install the GitHub App

[Install Rami](https://github.com/apps/rami-code-remeow) on your repository to enable code review.

### 2. Add the Marketplace

Claude Code:

```
/plugin marketplace add rami-code-review/claude-code-marketplace
```

Codex:

```
Install the Rami plugin from this repository's Codex marketplace metadata.
```

### 3. Install the Plugin

Claude Code:

```
/plugin install rami@rami-code-review
```

Codex:

```
Install the rami plugin from the rami-code-review marketplace.
```

### 4. Run a Review

Open a PR branch in Claude Code or Codex and run:

```
/rami:review
```

Rami will review your changes, show you the issues, and help fix them one by one.

## Codex Support

This repository includes Codex plugin metadata:

- `.codex-plugin/plugin.json`
- `.agents/plugins/marketplace.json`
- `skills/rami-code-review/SKILL.md`
- `.mcp.json`

The Codex plugin exposes the same Rami MCP server used by the Claude plugin and gives Codex sessions the `/rami:review`, `/rami:status`, and `/rami:usage` workflows.

## Commands

### `/rami:review`

Runs a full review cycle on your current PR branch. Rami will:

- Fetch review results for your PR
- Walk through each issue by priority (blocking → high → medium → low)
- Either fix the issue or let you dispute it with evidence
- Commit and push the fixes
- Repeat until the review is clean (up to 5 iterations)

### `/rami:status`

Quick check on your review status without triggering a new review. Useful when you want to see if a previous review has completed.

### `/rami:usage`

Check your remaining review quota and credit balance.

## Disputing Issues

Not every issue Rami finds needs to be fixed. You can dispute issues with evidence:

- **False positive** — The code is actually correct
- **Framework guarantee** — The framework handles this case
- **Intentional design** — This is by design, not a mistake
- **Duplicate** — Same issue reported elsewhere

Rami will evaluate your dispute and either accept it or ask you to fix the issue.

## Troubleshooting

**"No PR found for branch"**
Make sure you've pushed your branch and created a pull request.

**"Authentication required"**
Install the [Rami GitHub App](https://github.com/apps/rami-code-remeow) on your repository.

**Review taking too long?**
Use `/rami:status` to check progress without triggering a new review.

## Links

- [Rami Website](https://rami.reviews)
- [GitHub App](https://github.com/apps/rami-code-remeow)

## License

MIT
