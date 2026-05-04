---
description: Run full AI code review cycle on current PR branch
---

# Rami Code Review

Fix or rebut all review issues until clean. Max 5 iterations.

## Prerequisites Check

1. **MCP Server Available**

   If rami MCP tools are not available, **stop** and display:
   ```
   Rami MCP server needs authentication.

   To authenticate:
   1. Run /mcp in Claude Code
   2. Select "plugin:rami:rami"
   3. Press Enter to login
   4. Complete GitHub authentication in browser
   5. Return here and run /rami:review again
   ```

2. **PR Detection**
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
   | Any error | **Stop**: Report error message |

$ARGUMENTS

---

## Review Loop

**Initialize:**
- `iteration = 0`
- `max_iterations = 5`
- `history = []`

**Loop:**

1. `iteration++`
2. `mcp__plugin_rami-code-review_rami__get_review_results(pr_url)` → response
3. **Exit if** `ready_for_review == true` OR `iteration > max_iterations`
   - `ready_for_review` is the authoritative done signal. It is `true` only when `blocking_issue_count == 0` AND `pending_history_count == 0` AND `github_unresolved_count == 0`.
   - **Do NOT** exit on `issue_count == 0` alone. New-pass `issue_count` ignores carryover findings tracked in `pending_history_count` and human/bot threads in `github_unresolved_count`. A PR can have `issue_count: 0` and still be unmergeable.
4. Record: `history.push({iteration, issues, pending_history_count, github_unresolved_count})`
5. For each issue (Blocking → High → Medium → Low) — including `pending_history_issues`:
   - `mcp__plugin_rami-code-review_rami__get_fix_prompt(pr_url, issue_index)` → instructions
   - Either:
     - **Fix**: Apply changes using Edit tool
     - **Rebut**: `mcp__plugin_rami-code-review_rami__rebut(pr_url, issue_index, author_reply="<evidence>")`
       - `verdict: valid` → Dismissed, next issue
       - `verdict: invalid|partial` → **Must fix.** The rebuttal failed; Rami still believes the finding stands. Either push a code change that addresses the specific concern Rami cited, or stop and ask the user. **Do NOT** fall back to a plain GitHub thread reply or click "Resolve conversation" — Rami does not ingest those, so the thread will keep blocking `ready_for_review`.
6. `git add -A && git commit -m "fix: address rami review feedback" && git push`
7. Continue loop

---

## Report

```
## Rami Review Summary

**PR**: {pr_url}
**Iterations**: {iteration}
**Status**: {Clean | N issues remaining}

### Per-Iteration Breakdown
| Iter | Found | Fixed | Rebutted | Remaining |
|------|-------|-------|----------|-----------|
| 1    | 5     | 4     | 1        | 0         |

### Rebuttals
- Issue #2: [verdict: valid] - False positive: framework validates input
```

---

## Constraints

- Rebut only with evidence: false positive, framework guarantee, intentional design, duplicate
- Never rebut to avoid work or for style preferences
- Stop if same issue persists 2+ iterations (likely unfixable by AI)

---

## Rami owns Rami review state

Rami posts inline review threads on the PR. Those threads are part of Rami's state machine, not GitHub's UI. The only sanctioned ways to change a Rami thread's status are through the MCP tools listed above.

**Do NOT** take any of these actions on Rami threads:

- Do not click "Resolve conversation" on a Rami thread. GitHub-side resolution does not tell Rami the underlying finding was fixed; Rami can stop re-raising it without ever verifying, which lets unfixed bugs ship.
- Do not reply via the GitHub review thread (`POST /pulls/:number/comments` with `in_reply_to`). Rami does not parse those replies as state changes. Use `rebut` instead.
- Do not edit, delete, or hide a Rami review comment.
- Do not dismiss the Rami review on GitHub.
- Do not approve and merge a PR while `ready_for_review == false` — that bypasses the gate Rami exists to provide.

The done condition is what `get_review_results` reports, not what the GitHub UI shows. If a thread *looks* resolved on GitHub but `ready_for_review` is still `false`, trust `ready_for_review`.

If you genuinely believe Rami is wrong and `rebut` keeps returning `invalid`, stop and ask the user. Do not work around Rami via GitHub UI.

---

## Error Handling

| Error | Action |
|-------|--------|
| MCP tools unavailable | Display auth instructions from Prerequisites Check step 1 |
| `status: auth_required` | Display message from response (GitHub App installation needed) |
| Rate limited | Wait `interval` seconds from response, retry once, then abort |
