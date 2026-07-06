---
name: rami-rebut-finding
description: Auto-trigger when the user wants to challenge, rebut, or dispute a Rami code review finding — phrases like "rebut this", "this is a false positive", "Rami is wrong about X", or "tell Rami this is intentional". Routes disagreement through the Rami MCP rebuttal protocol instead of a public slash command.
---

# Rami Rebut Finding

Read and follow @${CLAUDE_PLUGIN_ROOT}/workflows/rami-rebut-finding/SKILL.md.

This skill is intentionally triggered by natural-language user intent, not by a `/rami:*` slash command. Use Rami's MCP `rebut` tool as the only state-changing channel for disputed Rami findings; never reply to or resolve the GitHub review thread as a substitute.
