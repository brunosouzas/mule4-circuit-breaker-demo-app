# First-concurrent-write reproducibility

The issue's open question: is the plugin's documented "no coordination on a circuit's very first
write, ever" limit reproducible from outside, via near-simultaneous requests to a brand-new
`circuitKey`? Short answer: **not conclusively from plain HTTP** — but a real, repeatable anomaly
was observed that is consistent with it.

## What was run

A fresh key (`bru58-firstwrite-1790349074-18766`, never used before) was called twice at once:

```bash
( curl ... "$BASE/orders/$KEY" -H 'X-Demo-Backend-Mode: ok' & )
( curl ... "$BASE/orders/$KEY" -H 'X-Demo-Backend-Mode: ok' & )
wait
```

Both calls returned `200 { orderId: "ORD-DEMO", status: "ACCEPTED" }` — one on replica `mkxnx`, one
on `h96hz`. No externally visible error or inconsistency at this point; from outside HTTP, there is
no way to force the two requests onto different replicas or to control which one's write to the
Object Store happens first, so a clean 200/200 result here doesn't rule out divergence — it only
means it didn't produce a *visible* error.

## What happened next (the anomaly)

Six subsequent `always_fail` calls on the *same* key all came back `502` (not blocked) — the
circuit did not open after 6 failures, unlike every other run in
[`cross-replica-proof.md`](cross-replica-proof.md), where it opened between calls 6 and 9. Pushing
further calls, it eventually did open, but only at call 9 counting from the two concurrent `ok`
calls (i.e. after 8 real failures, not 5):

```
call 7:  502 backend_failure   (h96hz)
call 8:  502 backend_failure   (mkxnx)
call 9:  503 circuit_open      (mkxnx)
call 10: 503 circuit_open      (mkxnx)
call 11: 503 circuit_open      (h96hz)
...
```

Once open, cross-replica visibility was consistent for the rest of the run (no further
slip-throughs like the ones in `cross-replica-proof.md` §3).

## Interpretation

Needing 8 real failures instead of 5 to open the circuit is exactly the kind of symptom the
plugin's README predicts for a divergent first write: if the two concurrent `ok` calls caused the
Object Store to briefly track two separate backing entries for the same key (per the plugin's own
`ObjectStoreCircuitStateStore`/`PartitionedPersistentObjectStore` internals), later increments could
land on whichever entry a given replica happened to see, delaying when the shared count actually
crosses `minimumCalls`. This is a plausible explanation, not a proof — this test cannot inspect the
Object Store's internal partitions from outside a pod, and 8-vs-5 could in principle also be
explained by the same read/write races documented in `cross-replica-proof.md` §3, without any
first-write divergence at all. Both explanations point at the same documented limitation (lack of
cross-replica coordination), so the practical conclusion is the same either way: **treat a brand
new circuit key's first few calls as unreliable for opening exactly on schedule when concurrent
traffic hits it immediately**, which is already the plugin's own guidance.
