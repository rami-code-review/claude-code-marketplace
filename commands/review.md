---
description: Run full AI code review cycle on current PR branch
---

# Rami Code Review

Fix or rebutt all review issues until clean. Max 5 iterations.

## Prerequisites Check

1. **Auth Status** (non-blocking)
   ```
   Read resource: rami://auth/status
   ```
   - `authenticated: true` → Proceed
   - `authenticated: false` → Warn with message from response

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
2. `mcp__plugin_rami-code-review_rami__get_review_results(pr_url)` → issues
3. **Exit if** `issue_count == 0` OR `iteration > max_iterations`
4. Record: `history.push({iteration, issues})`
5. For each issue (Blocking → High → Medium → Low):
   - `mcp__plugin_rami-code-review_rami__get_fix_prompt(pr_url, issue_index)` → instructions
   - Either:
     - **Fix**: Apply changes using Edit tool
     - **Rebutt**: `mcp__plugin_rami-code-review_rami__rebutt(pr_url, issue_index, author_reply="<evidence>")`
       - `verdict: valid` → Dismissed, next issue
       - `verdict: invalid|partial` → Must fix
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

- Rebutt only with evidence: false positive, framework guarantee, intentional design, duplicate
- Never rebutt to avoid work or for style preferences
- Stop if same issue persists 2+ iterations (likely unfixable by AI)

---

## Error Handling

| Error | Action |
|-------|--------|
| MCP unavailable | "Rami MCP server not responding. Check network or server status." |
| `status: auth_required` | Display message from response (directs to GitHub App installation) |
| Rate limited | Wait `interval` seconds from response, retry once, then abort |
