---
name: rami-record-decision
description: Auto-trigger when the user states a standing decision about the repository that Rami reviews should respect — phrases like "we decided X", "this is required by our ADR", "this module intentionally does Y", or "tell Rami to remember this". Routes the decision through the Rami MCP record_decision tool.
user-invocable: false
---

# Rami Record Decision

Read and follow @${CLAUDE_PLUGIN_ROOT}/workflows/rami-record-decision/SKILL.md.

This skill is triggered by natural-language user intent, not by a `/rami:*` slash command. Use Rami's MCP `record_decision` tool only for durable decisions; to challenge a finding, use the rebut workflow instead.
