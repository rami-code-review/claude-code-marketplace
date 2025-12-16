---
description: Check Rami quota and credit balance
---

# Rami Usage Check

Check remaining quota and credit balance.

## Prerequisites

If rami MCP tools are not available, **stop** and display:
```
Rami MCP server needs authentication.

To authenticate:
1. Run /mcp in Claude Code
2. Select "plugin:rami:rami"
3. Press Enter to login
4. Complete GitHub authentication in browser
5. Return here and run /rami:usage again
```

## Execution

```
mcp__plugin_rami-code-review_rami__get_usage()
```

## Report

Display:
- Remaining reviews this period
- Credit balance (if applicable)
- Plan tier
- Reset date
