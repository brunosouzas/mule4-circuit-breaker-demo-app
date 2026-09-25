# BRU-58 — evidence index

Evidence gathered against the real CloudHub 2.0 `test` deployment
(`mule4-circuit-breaker-demo-app-test`, 2 replicas, 0.1 vCore,
`https://mule4-circuit-breaker-demo-app-test-47xgd0.5sc6y6-4.usa-e2.cloudhub.io`), proving the
`mule4-circuit-breaker` plugin's cross-replica shared state and measuring the Object Store overhead
it adds. Collected 2026-09-25. See the
[Linear issue](https://linear.app/brunosouzas/issue/BRU-58) for the full acceptance criteria.

No trial-account credentials or secrets are stored in this folder — only response headers, logs
and timing numbers collected with plain `curl`. The persistent Object Store has no TTL, so the
`bru58-*` circuit keys created while gathering this evidence stay stored for the life of the trial
account (expires 24/10/2026) — not a leak, just worth knowing.

| File | What it proves |
|---|---|
| [`cross-replica-proof.md`](cross-replica-proof.md) | Both replicas answer; a circuit opened from combined cross-replica failures is visible on either replica; a live reproduction of the plugin's documented "no cross-replica lock" race |
| [`first-write-concurrency.md`](first-write-concurrency.md) | Whether the first-concurrent-write scenario is reproducible from outside a pod — inconclusive by design, but a real anomaly consistent with it was observed and reported honestly |
| [`scenarios.md`](scenarios.md) | The README's other scenarios (business error, half-open, independent keys) repeated against CloudHub, plus one gap found: the `slow` backend mode doesn't reproduce there (Groovy scripting engine, not a plugin issue) |
| [`latency-summary.md`](latency-summary.md), [`measure-latency.sh`](measure-latency.sh), `latency-with-cb.csv`, `latency-bypass.csv` | Measured Object Store overhead: **+5.6 ms median** per `circuit-breaker:execute` call (4 Object Store operations), isolated via a bypass endpoint that shares everything except the circuit breaker itself |
