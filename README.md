<p align="center">
  <img src="https://rami.reviews/static/images/rami_logo_full.png" alt="Rami" width="200">
</p>

# Rami Code Review

AI-powered code review for your pull requests, integrated directly into Claude Code.

Rami analyzes your code changes for security vulnerabilities, bugs, performance issues, and more — then helps you fix them automatically.

## Getting Started

### 1. Install the GitHub App

[Install Rami](https://github.com/apps/rami-code-remeow) on your repository to enable code review.

### 2. Add the Marketplace

```
/plugin marketplace add rami-code-review/claude-code-marketplace
```

### 3. Install the Plugin

```
/plugin install rami@rami-code-review
```

### 4. Run a Review

Open a PR branch in Claude Code and run:

```
/rami:review
```

Rami will review your changes, show you the issues, and help fix them one by one.

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
