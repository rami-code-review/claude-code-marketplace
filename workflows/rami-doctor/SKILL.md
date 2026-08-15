---
name: rami-doctor
description: Use when the user wants to diagnose, verify, or health-check a Rami install — "is Rami set up", "rami doctor", "check my rami install", "why isn't rami working". Runs read-only probes (MCP auth, GitHub App coverage, quota, plugin version) and prints a ✓/✗ checklist with the fix for each failure.
model: haiku
---

# Rami Doctor

Read-only diagnosis of a Rami install. Run every check, then print one checklist. Never mutate anything — no fixes are applied here; each failed check points at the command that fixes it.

A failure in an early check (no MCP, no auth) makes later checks meaningless — mark those `skipped` rather than failed.

## Checks

### 1. MCP server connected

Are the Rami MCP server's tools (`get_usage`, `get_current_branch_pr`, `get_review_results`, …) available?

- Available → ✓
- Not available → ✗ **MCP server not connected.** Fix: `/rami:setup`, then `/mcp` → authenticate.

### 2. Authenticated

```
ReadMcpResource(uri="rami://auth/status")
```

- `authenticated: true` → ✓ (show `github_login`)
- `authenticated: false` → ✗ **Not authenticated.** Fix: run `/mcp`, select `plugin:rami:rami`, press Enter to log in.

This resource costs no quota.

### 3. GitHub App covers this repo

```bash
REMOTE=$(git remote get-url origin)
BRANCH=$(git branch --show-current)
```
Call `get_current_branch_pr(remote_url=$REMOTE, branch=$BRANCH)` on the Rami MCP server.

- `status: success` → ✓ (App installed; PR `pr_url` found)
- `status: auth_required` → ✗ **GitHub App not installed on this repo.** Fix: install it at https://github.com/apps/rami-code-remeow and scope it to this repo.
- `status: not_found` → ⚠ App reachable, but **no open PR for `$BRANCH`** — push the branch and open a PR to use reviews.

### 4. Quota

Call `get_usage()` on the Rami MCP server.

- `can_execute_review: true` → ✓ (plan `plan`, `quota_remaining` left, `credit_balance` credits)
- `can_execute_review: false` → ⚠ **Out of quota/credits.** Fix: see `dashboard_url`.

### 5. Plugin up to date

The single source of truth for "latest" is the `version` field in `.claude-plugin/plugin.json` on `main` — there is no backend version.

- **Installed:** run `claude plugin list` (Bash) and read the version for `rami@rami-code-review`. If it isn't available, mark this check `skipped`.
- **Latest:**
  ```
  WebFetch(url="https://raw.githubusercontent.com/rami-code-review/claude-code-marketplace/main/.claude-plugin/plugin.json", prompt="Return only the value of the top-level version field.")
  ```
- installed == latest → ✓ (`vX.Y.Z`, up to date)
- installed < latest → ⚠ **Update available (`installed` → `latest`).** Fix: `/rami:upgrade`.
- fetch fails → `skipped` (network); never fail the check on a fetch error.

### 6. Codex approval prompts (Codex sessions only)

Skip this check outside Codex. Read `~/.codex/config.toml` and look for `[mcp_servers.rami.tools.get_review_results]` with `approval_mode = "approve"`.

- Present → ✓ (read-only tools pre-approved)
- Absent → ⚠ **Codex will ask for approval on every Rami call.** The client sends only the PR URL (Rami reads the PR through its GitHub App installation), so the read-only tools are safe to pre-approve; `get_review_results` may start a review when none exists, and re-reviews of the same PR consume no additional quota. It also blocks while a review runs and reports each stage as the review reaches it, so leaving it unapproved stalls the loop behind a prompt on every status update. Fix: with the user's consent, add `approval_mode = "approve"` entries under `[mcp_servers.rami.tools.<name>]` for `get_review_results`, `get_review_status`, `get_fix_prompt`, `get_current_branch_pr`, and `get_usage` — the exact snippet is in `/rami:setup` and at https://rami.reviews/llms.txt. This must be user-level config; Codex ignores approval settings shipped inside a plugin. Leave `rebut`/`defer`/`dismiss` unlisted so they keep prompting.

## Report

Print a single checklist, then a one-line verdict:

```
Rami doctor
  ✓ MCP server connected
  ✓ Authenticated (octocat)
  ✓ GitHub App covers this repo (PR #128)
  ✓ Quota: pro, 87 left
  ⚠ Update available: 2.3.0 → 2.4.0 — run /rami:upgrade

Verdict: ready to review. One optional update pending.
```

If any ✗ remains, the verdict is "not ready" and names the single next command to run.
