#!/usr/bin/env bash
set -euo pipefail

ROLLBACK_TAG="${1:-}"
log() { echo "[$(date '+%H:%M:%S')] $*"; }

if [ -z "$ROLLBACK_TAG" ]; then
  echo "Usage: $0 <tag>"
  echo "Available tags:"
  docker images tf05-api --format "{{.Tag}}" | grep "pre-deploy" | head -10
  exit 1
fi

log "=== ROLLBACK TO $ROLLBACK_TAG ==="

log "Re-tagging images..."
docker tag "tf05-api:${ROLLBACK_TAG}"       tf05-api:latest
docker tag "tf05-dashboard:${ROLLBACK_TAG}" tf05-dashboard:latest

log "Restarting services with previous images..."
docker compose up -d --no-deps --force-recreate api dashboard

log "Verifying rollback..."
sleep 8
STATUS=$(curl -sf http://localhost:5000/health | python3 -c "import sys,json; print(json.load(sys.stdin)['status'])" 2>/dev/null || echo "error")
if [ "$STATUS" = "healthy" ]; then
  log "Rollback successful ✓"
else
  log "WARNING: Service still unhealthy after rollback. Manual intervention required."
  exit 1
fi

log "=== ROLLBACK COMPLETE ==="
