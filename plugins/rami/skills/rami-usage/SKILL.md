---
name: rami-usage
description: Check Rami quota, credit balance, plan tier, and reset date. Use when the user asks about Rami usage, credits, quota, limits, or plan status.
---

# Rami Usage

If Rami MCP tools are unavailable or unauthenticated, stop and tell the user to authenticate the Rami MCP server in their current client or run the Rami setup workflow, then retry.

Call `get_usage()` on the Rami MCP server and report:

- remaining reviews in the current period
- credit balance, when applicable
- plan tier
- reset date
