---
name: playwright
description: >-
  Reproduce, capture, and verify UI behaviour with the Playwright CLI — for
  visual bug fixing and end-to-end testing of the Angular frontend. Use when the
  user reports a visual/layout/rendering bug, asks to "check how it looks",
  "reproduce in the browser", "take a screenshot", "verify the fix in the UI",
  or wants E2E tests. Drives a real browser instead of reasoning about code alone.
---

# Playwright — visual debugging & E2E

Drive a real browser to reproduce visual bugs, screenshot the current state,
compare before/after, and verify fixes. Complements the `verify` workflow:
a visual fix is "done" only when a screenshot confirms it.

> For exact, current Playwright API (assertions, config, selectors), use the
> `find-docs` skill (`ctx7 docs /microsoft/playwright "<question>"`) — the API
> moves and training data drifts.

## Setup (once per project)

```bash
npm init playwright@latest      # scaffolds config + installs browsers
# or, if already a dependency:
npx playwright install          # download browser binaries
```

## Reproduce a visual bug (fastest loop)

Start the app (`scripts\build` / `ng serve`), then capture the broken state:

```bash
# Screenshot a URL at a fixed viewport (deterministic for diffing)
npx playwright screenshot --viewport-size=1280,800 http://localhost:4200/orders before.png

# Full page, specific device, or wait for a selector first:
npx playwright screenshot --full-page --wait-for-selector="app-orders-table" \
  http://localhost:4200/orders before.png
```

Apply the fix, re-capture as `after.png`, and compare the two images to confirm.

## Record a repro / generate a test

```bash
npx playwright codegen http://localhost:4200    # click through; emits test code
```

## Run E2E tests & inspect failures

```bash
npx playwright test                       # run all
npx playwright test orders.spec.ts --ui   # interactive runner
npx playwright show-report                # open HTML report after a run
npx playwright show-trace trace.zip       # step-by-step trace of a failure
```

## Visual regression (pixel diff)

In a test, baseline + diff are handled by:

```ts
await expect(page).toHaveScreenshot('orders-table.png');
```

First run creates the baseline; later runs fail on visual drift and write a diff
image — ideal to catch and confirm visual regressions.

## Tips for the agent

- Always pin `--viewport-size` so screenshots are comparable across runs.
- Wait for content (`--wait-for-selector` / `waitForLoadState`) before shooting,
  to avoid capturing a half-rendered page.
- Screenshots are artefacts: read them back with the Read tool to actually
  *look* at the result before claiming a visual bug is fixed.
- Headless by default; add `--headed`/`--ui` only when a human is watching.
