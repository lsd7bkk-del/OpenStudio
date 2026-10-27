---
name: verification-loop
description: Verify OpenStudio changes before committing or opening a PR — build, lint, tests, secret scan, and diff review — then give a PASS/FAIL report. Use after finishing a feature or refactor, before pushing, or when asked to check that nothing is broken.
metadata:
  origin: Adapted from ECC (github.com/affaan-m/ECC, MIT). Commands rewritten for this repo (JS, Next.js + Vite/Electron, node:test).
---

# Verification Loop

Run the phases in order. If a phase fails, stop, fix it, and rerun from that phase.
Only run phases that apply to what changed.

## Phase 1: Build

```bash
set -o pipefail
npm run build 2>&1 | tail -30          # Next.js web app
```

If the diff touches `electron/`, `src/`, `vite.config.mjs`, or `index.html`, also run:

```bash
npm run vite:build 2>&1 | tail -30     # renderer used by the Electron app
```

If the diff touches `packages/<name>/`, build that workspace (`npm run build:studio`,
`build:workflow`, or `build:agent`).

## Phase 2: Lint

```bash
set -o pipefail
npm run lint 2>&1 | sed -n '1,40p'
```

If lint is not configured and prompts for setup, report "Lint: SKIPPED (not configured)"
rather than creating a config.

## Phase 3: Tests

Tests use Node's built-in runner and live in `tests/`.

```bash
node --test tests/*.test.js 2>&1 | tail -30
```

Report passed/failed counts. If you changed `electron/lib/`, a matching test should exist
or be added.

## Phase 4: Secret and Debug Scan (changed files only)

```bash
git diff --name-only HEAD | grep -E '\.(js|jsx|mjs|ts|tsx|json|sh|ps1)$' \
  | xargs -r grep -nE '(sk-[A-Za-z0-9]{16,}|api[_-]?key\s*[:=]\s*["'\''][^"'\'']{12,}|Bearer [A-Za-z0-9._-]{20,})' 2>/dev/null
git diff HEAD | grep -nE '^\+.*console\.log' | head -20
```

Any hardcoded key is a FAIL. New `console.log` lines that print headers, config, or keys
are a FAIL; other debug logs are a warning.

## Phase 5: Diff Review

```bash
git diff --stat HEAD
```

Read each changed file and check for:
- Changes unrelated to the task
- Missing error handling around MuAPI calls (network failure, 4xx/5xx, timeouts)
- UI states left out: loading, empty, error
- Anything the `security-review` skill covers (keys, proxy routes, uploads, Electron)

## Report

```
VERIFICATION REPORT
Build:     PASS/FAIL
Vite:      PASS/FAIL/SKIPPED
Lint:      PASS/FAIL/SKIPPED (N warnings)
Tests:     PASS/FAIL (X/Y)
Secrets:   PASS/FAIL
Diff:      N files changed
Overall:   READY / NOT READY

Issues to fix:
1. file:line — problem — fix
```
