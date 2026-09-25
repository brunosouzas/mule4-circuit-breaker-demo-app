# README scenarios, repeated against CloudHub 2.0

Same deployment as the rest of this evidence. Cross-replica opening/blocking is covered in
[`cross-replica-proof.md`](cross-replica-proof.md); this file covers the remaining scenarios from
the README's "Scenarios" section.

## Business error never opens the circuit

5× `GET /orders/{key}` with `X-Demo-Backend-Mode: business_error`: **400, 400, 400, 400, 400** —
matches the README exactly, never 503.

## Half-open recovers after `resetTimeout`

5× `always_fail` (502×5), 6th call **503** (opened cleanly this run, no cross-replica race). Waited
12 s (> the 10 s `resetTimeout`), then one `ok` call: **200 `{ orderId: "ORD-DEMO", status:
"ACCEPTED" }`**, on replica `mkxnx`. Matches the README.

## Independent circuits

6× `always_fail` on a `checkout` key (502×6, never actually opened within 6 calls this run — see
`cross-replica-proof.md` for why the exact call count to open varies with replica interleaving),
then one `ok` call on an unrelated `shipping` key: **200**, unaffected. Matches the README's claim
that different keys never share state (in contrast to same-key calls, which do — the whole point of
this issue).

## Slow backend — not reproducible on this deployment

The README documents: `slow` mode makes the simulated backend sleep 2 s, and the client's 1 s
`responseTimeout` turns that into a 502 after ~1 s. On CloudHub 2.0, this **did not reproduce**:
every attempt (3 runs) returned `502 backend_failure` in ~0.3–0.5 s — far faster than either the 2 s
sleep or the 1 s timeout, meaning the sleep never actually happened.

The `slow` mode's delay is implemented with `mule-scripting-module`'s Groovy engine
(`<scripting:execute engine="groovy">`, `backend-simulator.xml`). This repo's own MUnit suite
already carries a note that MUnit's embedded runtime doesn't register the Groovy engine
("Scripting engine 'groovy' not found") — the fast, consistent 502 observed here is consistent with
the same gap existing in the CloudHub 2.0 runtime itself, not just MUnit's test runtime, though this
wasn't confirmed against Runtime Manager logs (no direct log access from this session).

**This is a demo-app/environment gap, not a `mule4-circuit-breaker` limitation** — it doesn't affect
the circuit breaker's own behaviour (the call still fails and still counts toward the window, just
faster than documented, from a different error path than the one that reaches `HTTP:TIMEOUT`).
Flagged here for the record; fixing it (bundling/confirming the Groovy engine for CloudHub 2.0, or
replacing the sleep with a mechanism that doesn't depend on it) is follow-up work, not part of
BRU-58's acceptance criteria.
