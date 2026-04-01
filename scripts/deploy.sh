#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
ROLLBACK_TAG="pre-deploy-$(date +%Y%m%d_%H%M%S)"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

log "=== DEPLOY STARTED ==="

# 1. Backup before deploy (only if DB container is running)
if docker ps --format '{{.Names}}' | grep -q 'tf05-db'; then
  log "Running pre-deploy backup..."
  bash "$(dirname "$0")/backup.sh"
else
  log "Skipping backup — DB container not running (first deploy)"
fi

# 2. Tag current images for rollback (only if they exist)
log "Tagging current images for rollback ($ROLLBACK_TAG)..."
if docker image inspect tf05-api:latest > /dev/null 2>&1; then
  docker tag tf05-api:latest       "tf05-api:${ROLLBACK_TAG}"
  docker tag tf05-dashboard:latest "tf05-dashboard:${ROLLBACK_TAG}"
else
  log "No existing images to tag — skipping rollback snapshot (first deploy)"
fi

# 3. Build new images
log "Building new images..."
bash "$(dirname "$0")/build.sh"

# 4. Zero-downtime rolling update
log "Updating API (zero-downtime)..."
docker compose up -d --no-deps --scale api=2 api
sleep 10

log "Updating Dashboard..."
docker compose up -d --no-deps dashboard

log "Scaling API back to 1..."
docker compose up -d --no-deps --scale api=1 api

# 5. Health verification
log "Waiting for services to be healthy..."
RETRIES=10
for i in $(seq 1 $RETRIES); do
  STATUS=$(curl -sf http://localhost:5000/health | python3 -c "import sys,json; print(json.load(sys.stdin)['status'])" 2>/dev/null || echo "error")
  if [ "$STATUS" = "healthy" ]; then
    log "API is healthy ✓"
    break
  fi
  if [ "$i" -eq "$RETRIES" ]; then
    log "ERROR: API did not become healthy. Triggering rollback..."
    bash "$(dirname "$0")/rollback.sh" "$ROLLBACK_TAG"
    exit 1
  fi
  log "Attempt $i/$RETRIES — waiting 5s..."
  sleep 5
done

log "=== DEPLOY COMPLETE ==="
