#!/usr/bin/env bash
set -euo pipefail

API_URL="${API_URL:-http://localhost:5000}"
INTERVAL="${INTERVAL:-30}"
REPORT_DIR="./reports"
WEBHOOK_URL="${WEBHOOK_URL:-}"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

mkdir -p "$REPORT_DIR"

send_webhook() {
  local msg="$1"
  [ -z "$WEBHOOK_URL" ] && return
  curl -sf -X POST "$WEBHOOK_URL" -H "Content-Type: application/json" \
    -d "{\"text\": \"$msg\"}" > /dev/null 2>&1 || true
}

generate_report() {
  local report="${REPORT_DIR}/health-$(date +%Y%m%d_%H%M%S).json"
  curl -sf "${API_URL}/api/stats" > "$report" 2>/dev/null || echo '{"error":"api_unreachable"}' > "$report"
  log "Report saved: $report"
}

log "=== HEALTH MONITOR STARTED (interval: ${INTERVAL}s) ==="

LAST_REPORT=$(date +%s)

while true; do
  STATS=$(curl -sf "${API_URL}/api/stats" 2>/dev/null || echo '{}')
  UNHEALTHY=$(echo "$STATS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('unhealthy_services',0))" 2>/dev/null || echo "?")
  ALERTS=$(echo "$STATS"   | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('open_alerts',0))"       2>/dev/null || echo "?")

  log "Unhealthy: $UNHEALTHY | Open alerts: $ALERTS"

  if [ "$UNHEALTHY" != "0" ] && [ "$UNHEALTHY" != "?" ]; then
    send_webhook "⚠️ Monitor: $UNHEALTHY service(s) unhealthy, $ALERTS open alert(s)"
  fi

  # Hourly report
  NOW=$(date +%s)
  if (( NOW - LAST_REPORT >= 3600 )); then
    generate_report
    LAST_REPORT=$NOW
  fi

  sleep "$INTERVAL"
done
