---
description: Check Rami review status without triggering new review
---

# Rami Status Check

Check current review status for the PR on this branch.

## Prerequisites

If rami MCP tools are not available, **stop** and display:
```
Rami MCP server needs authentication.

To authenticate:
1. Run /mcp in Claude Code
2. Select "plugin:rami:rami"
3. Press Enter to login
4. Complete GitHub authentication in browser
5. Return here and run /rami:status again
```

## Execution

1. **Get PR URL**
   ```bash
   REMOTE=$(git remote get-url origin)
   BRANCH=$(git branch --show-current)
   ```
   ```
   mcp__plugin_rami-code-review_rami__get_current_branch_pr(remote_url=$REMOTE, branch=$BRANCH)
   ```

2. **Check Status**
   ```
   mcp__plugin_rami-code-review_rami__get_review_status(pr_url)
   ```

3. **Report**
   - `status: pending` → "Review in progress..."
   - `status: completed` → Report issue count and summary
   - `status: not_found` → "No review found for this PR"
   - `status: error` → Report error message
