# BRU-58 — evidence index

Evidence gathered against the real CloudHub 2.0 `test` deployment (2 replicas, 0.1 vCore), proving
the `mule4-circuit-breaker` plugin's cross-replica shared state and measuring the Object Store
overhead it adds. See the [Linear issue](https://linear.app/brunosouzas/issue/BRU-58) for the full
acceptance criteria.

No trial-account credentials or secrets are stored in this folder — only response headers, logs
and timing numbers collected with plain `curl`.

**Status: pending the first pipeline deploy.** This index and its files are filled in once the app
is actually running on CloudHub 2.0 (registering the Azure DevOps pipeline and reading back the
public URL are manual steps done by Bruno — see the README's "Delivery flow" section). Planned
files:

| File | What it proves |
|---|---|
| `cross-replica-proof.md` | Two distinct `X-Replica-Id` values across repeated calls, and the "5 failures open the circuit, visible from either replica" scenario |
| `first-write-concurrency.md` | Whether the first-concurrent-write scenario is reproducible from outside a pod via near-simultaneous requests, or why it isn't |
| `latency-summary.md`, `latency-with-cb.csv`, `latency-bypass.csv`, `measure-latency.sh` | Response-time comparison between `/orders/{key}` (through the circuit breaker) and `/orders-bypass/{key}` (direct), and the delta attributed to the plugin's Object Store reads/writes |
