<p align="center">
  <img src="https://rami.reviews/static/images/rami_logo_full.png" alt="Rami" width="200">
</p>

# Rami Code Review

**Works with Claude Code AND Codex.** Rami reviews every PR for security, bugs, and performance — then fixes the findings through MCP. You stay in control of what merges.

<p align="center">
  <img src="https://rami.reviews/static/images/rami_pr_check.png" alt="Rami PR check" width="720">
</p>

## Disputing Findings

Not every finding needs a fix. Push back when you have evidence — Rami evaluates the dispute and either accepts it or asks you to fix:

- **False positive** — the code is actually correct
- **Framework guarantee** — the framework handles this case
- **Intentional design** — this is by design, not a mistake
- **Duplicate** — the same issue is reported elsewhere

The dispute loop runs in the same session as the review, so accepted disputes drop out and only real issues land in your commits.

## Getting Started

### 1. Install the GitHub App

[Install Rami](https://github.com/apps/rami-code-remeow) on your repository.

### 2. Add the marketplace

Claude Code:

```
/plugin marketplace add rami-code-review/claude-code-marketplace
```

Codex:

```
Install the Rami plugin from this repository's Codex marketplace metadata.
```

### 3. Install the plugin

Claude Code:

```
/plugin install rami@rami-code-review
```

Codex:

```
Install the rami plugin from the rami-code-review marketplace.
```

### 4. Run a review

On a PR branch, run:

```
/rami:review
```

Rami fetches the review, walks each finding by priority, and applies fixes (or accepts disputes) until the PR is clean.

## Commands

### `/rami:review`

Full review-fix-dispute loop on the current PR branch:

- Fetches review results
- Walks findings by priority (blocking → high → medium → low)
- Fixes each one — or lets you dispute with evidence
- Commits and pushes
- Repeats until clean (up to 5 iterations)

### `/rami:review-status`

Check review status without triggering a new review.

### `/rami:usage`

Check remaining quota and credit balance.

## Troubleshooting

**"No PR found for branch"** — push the branch and open a pull request.

**"Authentication required"** — install the [Rami GitHub App](https://github.com/apps/rami-code-remeow) on the repo.

**Review taking too long?** — `/rami:review-status` checks progress without triggering a new review.

## Links

- [Rami](https://rami.reviews)
- [GitHub App](https://github.com/apps/rami-code-remeow)

## License

MIT
