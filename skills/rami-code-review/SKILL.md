---
name: rami-code-review
description: Use when the user asks for Rami PR review workflows, including /rami:review, /rami:status, /rami:review-status, or /rami:usage. Requires access to the Rami MCP server.
---

# Rami Code Review

Use the Rami MCP server for PR review workflows. Do not substitute a manual review unless the MCP server is unavailable and the user explicitly asks for a fallback.

## Commands

### `/rami:review`

Run the full review loop on the current PR branch.

1. Verify Rami MCP tools are available.
2. Get repo and branch:

```bash
git remote get-url origin
git branch --show-current
```

3. Call the Rami MCP `get_current_branch_pr` tool with the remote URL and branch.
4. If no PR is found, stop and report the branch name.
5. Loop up to 5 iterations:
   - Call `get_review_results(pr_url)`.
   - Stop if the issue count is 0.
   - Handle issues in priority order: Blocking, High, Medium, Low.
   - For each issue, call `get_fix_prompt(pr_url, issue_index)`.
   - Fix the issue with normal file edits, or call `rebut(pr_url, issue_index, author_reply)` only with evidence: false positive, framework guarantee, intentional design, or duplicate.
   - If a rebuttal is invalid or partial, fix the issue.
   - Stop if the same issue persists for 2 iterations.
6. After fixes, follow the repository's normal commit and push policy. Do not commit or push unless the user requested that workflow and local project gates pass.

Report:

```text
## Rami Review Summary

PR: <pr_url>
Iterations: <count>
Status: <Clean | N issues remaining>

Per-iteration:
- Iteration N: found X, fixed Y, rebutted Z, remaining R

Rebuttals:
- Issue #N: [verdict] evidence summary
```

### `/rami:status` or `/rami:review-status`

Check status without triggering a new review.

1. Verify Rami MCP tools are available.
2. Get the current branch PR with `get_current_branch_pr`.
3. Call `get_review_status(pr_url)`.
4. Report pending, completed issue count and summary, not found, or error.

### `/rami:usage`

Call the Rami MCP `get_usage` tool and report remaining reviews, credit balance if present, plan tier, and reset date.

## MCP Unavailable

If Rami MCP tools are unavailable, stop and display:

```text
Rami MCP server is not available in this session.

Install or authenticate the Rami plugin for this client, then rerun the command. The plugin should expose the Rami MCP server at https://rami.reviews/mcp.
```
