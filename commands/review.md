---
description: Run full AI code review cycle on current PR branch
---

# Rami Code Review

Run the full review-fix-rebut loop on the PR for the current branch. Max 5 iterations.

## Prerequisites

1. **MCP server available.** If Rami MCP tools are not available, stop and display:
   ```
   Rami MCP server needs authentication.

   To authenticate:
   1. Run /mcp in Claude Code
   2. Select "plugin:rami:rami"
   3. Press Enter to login
   4. Complete GitHub authentication in browser
   5. Return here and run /rami:review again
   ```

2. **PR detection.** Get the remote and branch, then call the Rami MCP tool:
   ```bash
   REMOTE=$(git remote get-url origin)
   BRANCH=$(git branch --show-current)
   ```
   ```
   mcp__plugin_rami-code-review_rami__get_current_branch_pr(remote_url=$REMOTE, branch=$BRANCH)
   ```

   | Result | Action |
   |--------|--------|
   | `status: success` | Use `pr_url`, proceed |
   | `status: not_found` | **Stop**: "No PR found for branch `$BRANCH`" |
   | Any error | **Stop**: Report the error |

$ARGUMENTS

## Run the loop

Invoke the **`rami-code-review`** skill with the detected `pr_url`. The skill is the single source of truth for the loop algorithm:

- Phase 1: PR detection (skipped — already done above).
- Phase 2: Iterate up to 5 times. Each iteration calls `get_review_results`, exits when `ready_for_review == true`, otherwise triages issues by severity (Blocking → High → Medium → Low) and either fixes them or rebuts via `rebut`. Pushes after each iteration.
- Phase 3: Report a summary table.

The skill enforces the rules that make the loop correct: exit on `ready_for_review`, never `issue_count == 0`; rebut via the MCP tool, never via a GitHub thread reply or "Resolve conversation" click.

## Error handling

| Error | Action |
|-------|--------|
| MCP tools unavailable | Display the auth instructions above |
| `status: auth_required` from any tool | Display the message from the response (GitHub App install needed) |
| Rate limited | Wait `interval` seconds from the response, retry once, then abort |
