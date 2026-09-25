#!/usr/bin/env bash
# Reproduces the latency comparison in latency-summary.md. Usage:
#   BASE=https://<app>.cloudhub.io ./measure-latency.sh
set -euo pipefail
BASE="${BASE:?Set BASE to the deployed app's URL, e.g. https://mule4-circuit-breaker-demo-app-test-<suffix>.cloudhub.io}"
KEY="${KEY:-bru58-latency}"
N="${N:-50}"

warm_up() {
  local path="$1"
  for _ in $(seq 1 5); do curl -s -o /dev/null -m 15 "$BASE$path" -H 'X-Demo-Backend-Mode: ok'; done
}

measure() {
  local path="$1" out="$2"
  : > "$out"
  for _ in $(seq 1 "$N"); do
    curl -s -o /dev/null -m 15 -w '%{time_total}\n' "$BASE$path" -H 'X-Demo-Backend-Mode: ok' >> "$out"
  done
}

echo "warm-up: with circuit breaker"
warm_up "/orders/$KEY"
echo "measuring: with circuit breaker (N=$N)"
measure "/orders/$KEY" latency-with-cb.csv

echo "warm-up: bypass"
warm_up "/orders-bypass/$KEY"
echo "measuring: bypass (N=$N)"
measure "/orders-bypass/$KEY" latency-bypass.csv

echo "done — see latency-with-cb.csv / latency-bypass.csv (seconds, one sample per line)"
