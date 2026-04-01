#!/usr/bin/env bash
set -euo pipefail

LOG_RETENTION_DAYS="${LOG_RETENTION_DAYS:-30}"
METRICS_RETENTION_DAYS="${METRICS_RETENTION_DAYS:-90}"
DB_CONTAINER="${DB_CONTAINER:-tf05-db-1}"
DB_NAME="${DB_NAME:-monitoring}"
DB_USER="${DB_USER:-monitor}"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

log "=== CLEANUP STARTED ==="

# Remove old Docker logs
log "Pruning stopped containers and dangling images..."
docker container prune -f
docker image prune -f

# Remove old backup files
log "Removing backups older than ${LOG_RETENTION_DAYS} days..."
find ./backups -maxdepth 1 -type d -mtime "+${LOG_RETENTION_DAYS}" -exec rm -rf {} + 2>/dev/null || true

# Purge old metrics from DB
log "Purging metrics older than ${METRICS_RETENTION_DAYS} days..."
docker exec "$DB_CONTAINER" psql -U "$DB_USER" "$DB_NAME" -c \
  "DELETE FROM metrics WHERE recorded_at < NOW() - INTERVAL '${METRICS_RETENTION_DAYS} days';"

# Purge old health_checks
log "Purging health_checks older than ${METRICS_RETENTION_DAYS} days..."
docker exec "$DB_CONTAINER" psql -U "$DB_USER" "$DB_NAME" -c \
  "DELETE FROM health_checks WHERE checked_at < NOW() - INTERVAL '${METRICS_RETENTION_DAYS} days';"

# Vacuum DB
log "Running VACUUM ANALYZE..."
docker exec "$DB_CONTAINER" psql -U "$DB_USER" "$DB_NAME" -c "VACUUM ANALYZE;"

log "=== CLEANUP COMPLETE ==="
