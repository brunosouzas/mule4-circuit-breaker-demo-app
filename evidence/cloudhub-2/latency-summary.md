# Object Store latency — measured

Deployment: `mule4-circuit-breaker-demo-app-test`, CloudHub 2.0, 2 replicas × 0.1 vCore.
Method: [`measure-latency.sh`](measure-latency.sh) (5 warm-up + 50 measured calls each), comparing
`GET /orders/{key}` (through `<circuit-breaker:execute>`, circuit closed, `ok` mode) against
`GET /orders-bypass/{key}` (identical backend call, no circuit breaker at all — see
`circuit-breaker-demo-api.xml`'s `call-backend-direct`). Both hit the same backend, same
`responseTimeout`, same header forwarding — the only difference is whether the call goes through
the plugin. Raw samples: [`latency-with-cb.csv`](latency-with-cb.csv),
[`latency-bypass.csv`](latency-bypass.csv) (seconds, one line per call).

| | mean | median | p95 | min | max |
|---|---|---|---|---|---|
| `/orders/{key}` (with circuit breaker) | 327.8 ms | 323.4 ms | 353.0 ms | 309.6 ms | 403.5 ms |
| `/orders-bypass/{key}` (direct) | 322.8 ms | 317.8 ms | 350.7 ms | 305.2 ms | 404.3 ms |
| **Delta (circuit breaker overhead)** | **+5.0 ms** | **+5.6 ms** | **+2.3 ms** | — | — |

## Reading this number

The ~320 ms baseline in both columns is dominated by the network round trip between wherever
`measure-latency.sh` ran and the CloudHub 2.0 `usa-e2` region, not by anything this app or plugin
does — that's exactly why the comparison is a *delta* between two paths that share that baseline,
rather than an absolute number taken on its own.

The delta itself (~5 ms) is the cost attributable to `<circuit-breaker:execute>`. Per the plugin's
own source (`CircuitBreakerOperations.execute()`), one call does two `stateStore.update()` calls —
one on call start, one on the outcome — each taking a lock and doing a read (`contains` +
`retrieve`) then a write (`remove` + `store`) against the persistent Object Store. So ~5 ms is the
combined cost of **4 Object Store operations** (2 reads + 2 writes) plus 2 lock acquisitions, on
CloudHub 2.0's managed backend, under this deployment's load (2 replicas, essentially idle besides
this test).

This is a per-call fixed cost, not something that scales with request volume within a single call —
it doesn't say anything about Object Store latency under concurrent load from many replicas at
once, which this single-client sequential test doesn't exercise.
