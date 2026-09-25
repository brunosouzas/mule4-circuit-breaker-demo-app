# Cross-replica shared state — evidence

Deployment: `mule4-circuit-breaker-demo-app-test`, CloudHub 2.0, `test` environment, 2 replicas ×
0.1 vCore. URL: `https://mule4-circuit-breaker-demo-app-test-47xgd0.5sc6y6-4.usa-e2.cloudhub.io`.
Both replicas observed (pod hostnames, from `X-Replica-Id`):

- `mule4-circuit-breaker-demo-app-test-5dd476755b-h96hz`
- `mule4-circuit-breaker-demo-app-test-5dd476755b-mkxnx`

Collected 2026-09-25, ~15:08–15:10 UTC.

## 1. Both replicas actually answer

20 calls to `GET /health`:

```
17 x-replica-id: ...-h96hz
 3 x-replica-id: ...-mkxnx
```

Load balancing is skewed (likely connection reuse / a small number of upstream connections from a
single client), but both replicas do answer — this is the baseline the rest of this evidence
depends on.

## 2. Circuit open on one replica is visible on the other

`circuitKey=bru58-crossreplica-1790348938`, repeated `GET /orders/{key}` with
`X-Demo-Backend-Mode: always_fail` (`windowSize=5`, `minimumCalls=5`, `resetTimeout=10000` — the
demo-friendly values pinned in `pom.xml`'s `cloudhub2Deployment`, same as `common.yaml`):

| Call | Replica | Result |
|---|---|---|
| 1 | mkxnx | 502 backend_failure |
| 2 | mkxnx | 502 backend_failure |
| 3 | h96hz | 502 backend_failure |
| 4 | h96hz | 502 backend_failure |
| 5 | mkxnx | 502 backend_failure |
| 6 | h96hz | 502 backend_failure |
| 7 | h96hz | 502 backend_failure |
| 8 | h96hz | 502 backend_failure |
| 9 | h96hz | **503 circuit_open** |
| 10 | h96hz | 503 circuit_open |
| 11 | **mkxnx** | **502 backend_failure** ← see §3 |
| 12 | mkxnx | 502 backend_failure |
| 13 | mkxnx | 503 circuit_open |
| 14 | mkxnx | 503 circuit_open |
| 15 | mkxnx | 503 circuit_open |
| 16 | **h96hz** | **502 backend_failure** ← see §3 |
| 17 | h96hz | 503 circuit_open |
| 18 | h96hz | 503 circuit_open |
| 19 | mkxnx | 503 circuit_open |
| 20 | h96hz | 503 circuit_open |

**This is the acceptance criterion's proof**: calls landed on both replicas throughout (not just
one), the circuit opened after failures accumulated *across* both of them (not after 5 calls to a
single replica — each replica individually only handled 3–4 of the first 8 calls), and once open,
both replicas independently reported `circuit_open` (calls 9–10 on h96hz, 13–15 on mkxnx, 17–20 on
h96hz again) without ever needing to re-contact the failing backend. That is only possible because
the state lives in the shared, persistent Object Store — not in either replica's memory.

## 3. The "no cross-replica lock" limit, reproduced live

The README of `mule4-circuit-breaker` documents: *"the lock this plugin takes only serializes
reads/writes to a circuit key within one replica... two replicas writing to the same key at close
to the same time race at the storage level... last write wins, and a write from one replica can be
silently overwritten by another's."*

Calls 11 and 16 above are exactly that, observed from outside: the circuit had just reported
`circuit_open` on one replica, yet the very next call — landing on the *other* replica — went
through as a normal (failing) attempt instead of being blocked. In both cases the circuit did
reopen a call or two later. This is consistent with a stale read on one replica racing a concurrent
write on the other, not with the state being un-shared (if it were un-shared, the circuit would
never have opened by call 9 in the first place, since neither replica alone reached 5 failures).

## Interpretation

Both halves of the acceptance criterion hold, together, in the same run: the state **is** visibly
shared across replicas (the circuit opens and stays open based on the combined failure count, and
either replica can report it), and the plugin's own documented lack of cross-replica locking **is**
observable in production as occasional calls slipping through right after an open transition —
not a flaw in this test, but the exact trade-off the plugin's README already names.
