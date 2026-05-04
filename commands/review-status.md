---
description: Check Rami review status without triggering new review
---

# Rami Status Check

Report the current Rami review state for the PR on this branch without triggering a new review.

## Prerequisites

If Rami MCP tools are not available, **stop** and display:

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

1. **Get PR URL.**
   ```bash
   REMOTE=$(git remote get-url origin)
   BRANCH=$(git branch --show-current)
   ```
   ```
   mcp__plugin_rami-code-review_rami__get_current_branch_pr(remote_url=$REMOTE, branch=$BRANCH)
   ```

2. **Check status.**
   ```
   mcp__plugin_rami-code-review_rami__get_review_status(pr_url)
   ```

3. **Report.** Use `ready_for_review` as the authoritative done signal — not `issue_count == 0`.

   | Response | Report |
   |---|---|
   | `status: pending` / `in_progress` / `queued` | "Review in progress (stage: `<current_stage>`)" |
   | `status: completed`, `ready_for_review: true` | "Ready for review. No blocking findings." |
   | `status: completed`, `ready_for_review: false` | "Not ready: `issue_count` new + `pending_history_count` carryover + `github_unresolved_count` thread(s) outstanding. Run `/rami:review` to triage." |
   | `status: not_found` | "No review found for this PR." |
   | Error | Report the error message. |

   Do not infer doneness from `issue_count == 0` alone. Carryover findings (`pending_history_count`) and unresolved threads (`github_unresolved_count`) can keep `ready_for_review` false even when the new pass found nothing.
