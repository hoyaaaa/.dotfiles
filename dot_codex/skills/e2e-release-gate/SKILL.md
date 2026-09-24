---
name: e2e-release-gate
description: Evaluate, debug, and certify integration or Playwright E2E suites as release evidence. Use when asked whether E2E is complete, production-ready, stable, flaky, or suitable as a deployment gate, especially when reruns disagree.
---

# E2E Release Gate

Treat a release claim as an evidence problem, not a test-count problem.

## Required workflow

1. Read the repository's canonical E2E runbook and exact suite contract before running anything.
2. Freeze a run identity containing test-source digest, product revisions/runtime build IDs, every FE/API origin, DB identity/schema generation, fixture generation, browser/config, worker/retry settings, and auth mode. Record no secrets.
3. Run preflight against every actual hostname and critical dependency used by the suite. A generic health endpoint is insufficient when routing, TLS, proxying, DB, or a second frontend can fail independently.
4. Use one authoritative entrypoint and one authoritative runner for a stateful shared validation environment. Do not deploy, restart, reset fixtures, change schemas, edit tests, or run a competing live suite after the start fingerprint.
5. Let the full contracted collection finish. Report collected, executed, first-attempt passed, failed, flaky, skipped, and did-not-run separately. Never add results from different runs.
6. Classify each non-pass as direct product failure, test defect, fixture/data defect, infrastructure failure, or cascade from a prior failure. Cascades are not independent bugs, but remain incomplete coverage.
7. Only after collection, reproduce direct roots with an exploratory browser or targeted test. Targeted passes prove only the proposed diagnosis/fix.
8. Before rerunning, remove non-hermetic causes in every affected state-producing path. A created resource must use a run-unique identity, derive its response contract from the authoritative API schema or product type, be read back through an exact identifier or exact unique marker, and be cleaned up with an exact zero-remaining assertion. Never select generic historical data with positional `.first()` or `.last()`.
9. Batch supported fixes, then run the complete affected dependency chain serially **twice in succession** from clean run-owned state with the same frozen fingerprint. Both runs must have zero failed, flaky, skipped, and did-not-run tests. A targeted pass or one affected-chain pass is diagnostic evidence only.
10. Run the entire release contract again from its authoritative entrypoint with a fresh run ID and unchanged start/end fingerprint. Claim completion only if the exact contract passes with zero failed, flaky, skipped, and did-not-run tests and the evidence integrity gate passes.

## Hard rules

- Never promote a targeted pass, a retry pass, a historical pass, or a synthetic aggregate to release evidence.
- A test that passes only after retry is flaky, not clean.
- A serial dependent suite that skips later cases after one failure has one direct failure plus incomplete downstream coverage.
- Preserve failed-run artifacts before debugging. Do not overwrite the last verified full-run artifact with a partial run.
- Prefer isolated tests and run-owned disposable data. Where a real workflow must be serial, make dependencies explicit and keep cleanup independently executable.
- Do not swallow readiness or state-transition timeouts on paths that create or mutate data. A timeout must fail at the true producing step, not surface later as a misleading cascade.
- Evidence must identify the exact run and preserve sanitized failure diagnostics plus success proof. Follow repository security rules for screenshots, traces, tokens, credentials, and PII.
- If the environment changes during a run, invalidate the whole run even if all assertions passed.

## Reporting language

Use `PASS` only for a clean authoritative run. Otherwise use `INCOMPLETE`, with a compact table of suite counts, direct roots, cascades, environment drift, and next verification step. State separately whether the evidence is sufficient for deployment.

For the evaluation rationale and source links, read [references/evaluation-model.md](references/evaluation-model.md).
