# E2E evaluation model

## Why these gates exist

- Playwright recommends isolated tests because isolation improves reproducibility, debugging, and prevents cascading failures. It recommends traces for CI diagnosis and exposes screenshots, DOM snapshots, console, and network activity in Trace Viewer: <https://playwright.dev/docs/best-practices>, <https://playwright.dev/docs/trace-viewer>
- Playwright labels a test that fails first and passes on retry as `flaky`; it also documents that serial mode skips later tests after a failure. A retry therefore cannot be counted as a clean first-attempt pass: <https://playwright.dev/docs/test-retries>
- Playwright documents one-worker execution for sequential resource isolation and warns that dependent projects do not run when setup fails: <https://playwright.dev/docs/test-parallel>, <https://playwright.dev/docs/test-projects>
- Google describes large/E2E tests as a distinct class and requires high isolation and order independence where possible: <https://testing.googleblog.com/2010/12/test-sizes.html>
- Google's hermetic-server guidance explains that external network dependencies introduce nondeterminism and unavailability; when a hosted validation environment is necessary, its complete runtime identity and connectivity must therefore be frozen and checked: <https://testing.googleblog.com/2012/10/hermetic-servers.html>
- GitHub documents reports, logs, and screenshots as retained workflow artifacts used for deployment and failure analysis: <https://docs.github.com/en/actions/tutorials/store-and-share-data>

## Minimum release record

Record one immutable run ID with:

- exact test inventory and source digest;
- product revisions and observed runtime build IDs;
- frontend/API origins and routing/TLS checks;
- DB identity, migration/schema generation, and fixture generation;
- browser/runtime/config plus worker and retry counts;
- authentication transport, without credentials or raw tokens;
- per-suite collected/executed/pass/fail/flaky/skip/not-run counts;
- direct-root and cascade classification;
- start/end fingerprint comparison;
- cleanup result and artifact-integrity result.

The release decision is conjunctive: every required field and gate must pass in the same run.

## Stateful creation-path stability audit

Before an affected-chain rerun, verify every state-producing path against all of these conditions:

- the resource name or correlation marker is unique to the run;
- the create-response shape is proven from the authoritative API schema or product type;
- downstream steps locate the resource by exact ID or exact run-unique marker, never a positional match over historical data;
- the visible dialog or panel is scoped explicitly when duplicate hidden DOM can exist;
- readiness and state-transition waits fail explicitly rather than being swallowed;
- teardown verifies exact absence and zero remaining run-owned rows.

A single targeted or affected-chain pass can still be accidental. Require two consecutive clean serial executions of the complete affected dependency chain, from clean run-owned state and under the same frozen fingerprint, before spending the one final full release run.
