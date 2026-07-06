---
description: Set up and connect Rami — GitHub App, MCP server, OAuth, and a verification call
---

# Set Up Rami

Connect Rami end to end so reviews and the autofix loop work.

Read and follow @${CLAUDE_PLUGIN_ROOT}/workflows/rami-setup-mcp/SKILL.md. It is the single source of truth for setup and mirrors the public guidance at https://rami.reviews/llms.txt: install the GitHub App, register the MCP server for the user's client (Claude Code / Cursor / Codex / other), complete OAuth, and verify with a side-effect-free `get_usage` call.

It can also offer — only with explicit consent — to add a short, fenced, removable Rami section to this repo's `CLAUDE.md` / `AGENTS.md` (the review-thread state-ownership rule).

If the user already has Rami connected and just wants to confirm what (if anything) is missing, run `/rami:doctor` instead.
