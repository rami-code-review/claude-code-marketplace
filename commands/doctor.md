---
description: Diagnose a Rami install — checks auth, GitHub App coverage, quota, and plugin version
---

# Rami Doctor

Run a read-only health check of the Rami setup for this repo and report exactly what is and isn't working.

Read and follow @${CLAUDE_PLUGIN_ROOT}/workflows/rami-doctor/SKILL.md. It probes MCP authentication, GitHub App coverage for the current repository, remaining quota, and whether the installed plugin is up to date, then prints a single ✓/✗ checklist with the precise fix for each failure. It never changes anything.
