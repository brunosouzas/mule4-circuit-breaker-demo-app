# Changelog

## 0.1.0

- Client endpoint (`GET /orders/{circuitKey}`) wraps a call to a simulated backend in `circuit-breaker:execute`.
- Simulated backend (`GET /backend/orders`), controlled per request by the `X-Demo-Backend-Mode` header: `ok`, `always_fail`, `business_error`, `slow`.
- `global-error-handler` maps `CIRCUIT-BREAKER:OPEN` to HTTP 503, the backend's business error to 400, and its infrastructure failures to 502.
- MUnit suite covering all 5 circuit breaker scenarios: closed circuit passes, opens on failure rate, business error never opens it, half-open recovers after `resetTimeout`, independent circuit keys never interfere.
