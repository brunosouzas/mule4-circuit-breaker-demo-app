# mule4-circuit-breaker-demo-app

A Mule 4 application that uses the [mule4-circuit-breaker](https://github.com/brunosouzas/mule4-circuit-breaker) plugin against a simulated backend you can make fail, slow down or recover, so each circuit breaker scenario can be triggered and checked inside a real Mule runtime.

## Architecture

```
curl → GET /orders/{circuitKey} → circuit-breaker:execute → GET /backend/orders (same app)
```

`/orders/{circuitKey}` is the client endpoint. It wraps a call to the simulated backend in `<circuit-breaker:execute>`. The backend is a second flow in this same application, controlled per request by the `X-Demo-Backend-Mode` header the client forwards unchanged — there is no server-side state; "the backend recovers" is simply the caller sending a later request with a different header value.

`global-error-handler` (`src/main/mule/global.xml`) maps what comes back into an HTTP status:

| Error | HTTP status |
|---|---|
| `CIRCUIT-BREAKER:OPEN` | 503 |
| The backend's business error (`HTTP:BAD_REQUEST`) | 400 |
| The backend's infrastructure failures (`HTTP:INTERNAL_SERVER_ERROR`, `HTTP:TIMEOUT`, `HTTP:CONNECTIVITY`) | 502 |

## Endpoints

| Method | Path | Purpose |
|---|---|---|
| GET | `/orders/{circuitKey}` | Client endpoint; `circuitKey` selects which circuit this call belongs to |
| GET | `/backend/orders` | Simulated backend; behaviour controlled by the `X-Demo-Backend-Mode` request header |

## Running locally

1. Package this app:
   ```bash
   mvn clean package
   ```
   `mule4-circuit-breaker` resolves from the Anypoint Exchange of the trial org
   (`c17ce335-be76-4fd0-87e2-130837d2c65a`, see [pom.xml](pom.xml)) — no local `mvn install` of the
   plugin repo needed. This requires an `anypoint-exchange-v3` server entry in `~/.m2/settings.xml`
   with Exchange **read** access; a Connected App scoped only to publish (the one the plugin's own
   release pipeline uses) can't resolve it and fails with a 404 "Asset file not found".
   This produces `target/mule4-circuit-breaker-demo-app-0.1.0-SNAPSHOT-mule-application.jar`.
2. Deploy it to a Mule 4 standalone runtime you already have installed locally: copy that jar into `<MULE_HOME>/apps/` and start (or restart) the runtime — `bin/mule start` (or `bin/mule restart` if it's already running). The app listens on port `8081` by default (`src/main/resources/config/common.yaml`).

## Scenarios

Every command targets `circuitKey=demo` and can be repeated with a different value (e.g. `checkout`, `shipping`) to see independent circuits. `-i` shows the response status so you can see the mapping in `global.xml` in action.

**Closed circuit — calls pass through:**
```bash
curl -i http://localhost:8081/orders/demo -H 'X-Demo-Backend-Mode: ok'
```

**Opens on failure rate — the 5th failing call fills the window, the 6th is blocked:**
```bash
for i in 1 2 3 4 5 6; do curl -i http://localhost:8081/orders/demo -H 'X-Demo-Backend-Mode: always_fail'; done
# the first 5 are 502 (the backend really was called and really failed); the 6th is 503 with
# { "error": "circuit_open", ... } — the backend is no longer being called at all
```

**Business error never opens the circuit — repeat as many times as you like:**
```bash
for i in 1 2 3 4 5; do curl -i http://localhost:8081/orders/demo -H 'X-Demo-Backend-Mode: business_error'; done
# always 400, never 503
```

**Half-open recovers once `resetTimeout` (10s by default) elapses:**
```bash
# open it first
for i in 1 2 3 4 5; do curl -i http://localhost:8081/orders/demo -H 'X-Demo-Backend-Mode: always_fail'; done
sleep 10
curl -i http://localhost:8081/orders/demo -H 'X-Demo-Backend-Mode: ok'
# 200 again — the HALF_OPEN test call succeeded and closed the circuit
```

**Slow backend — the request times out from the client's side:**
```bash
curl -i http://localhost:8081/orders/demo -H 'X-Demo-Backend-Mode: slow'
# 502 after ~1s (the client's responseTimeout), even though the backend eventually answers after 2s
```

**Independent circuits — open one, the other keeps working:**
```bash
for i in 1 2 3 4 5; do curl -i http://localhost:8081/orders/checkout -H 'X-Demo-Backend-Mode: always_fail'; done
curl -i http://localhost:8081/orders/shipping -H 'X-Demo-Backend-Mode: ok'
# shipping still returns 200
```

## Tests

```bash
mvn clean test
```

MUnit stubs the single `http:request` call with `munit-tools:mock-when` rather than going through the real backend listener (MUnit doesn't start message sources by default), so it stays fast and deterministic. The `cb.*` system properties in `pom.xml`'s `munit-maven-plugin` configuration give the circuit breaker small, fast values for tests (`windowSize=2`, `resetTimeout=500ms`) instead of the demo-friendly ones in `common.yaml`. The real end-to-end HTTP round trip is what the "Scenarios" section above exercises.

## Limits

The circuit's state lives in the plugin's own persistent Object Store, which is what lets state survive across CloudHub 2.0 replicas of the same deployment — not relevant to a single local instance, but worth knowing before reading too much into a single-instance demo: see [mule4-circuit-breaker's README](https://github.com/brunosouzas/mule4-circuit-breaker#limits-of-shared-state) for the documented limits of that mechanism (no cross-replica lock, no coordination on a circuit's very first write, added latency).

## Licence

[MIT](LICENSE)
