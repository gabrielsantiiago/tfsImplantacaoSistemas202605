#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
DB_CONTAINER="${DB_CONTAINER:-tf05-db-1}"
DB_NAME="${DB_NAME:-monitoring}"
DB_USER="${DB_USER:-monitor}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

mkdir -p "$BACKUP_DIR"

log "=== BACKUP STARTED → $BACKUP_DIR ==="

# Database dump
if docker ps --format '{{.Names}}' | grep -q "$DB_CONTAINER"; then
  log "Dumping PostgreSQL database..."
  docker exec "$DB_CONTAINER" pg_dump -U "$DB_USER" "$DB_NAME" | gzip > "${BACKUP_DIR}/db.sql.gz"
  log "DB backup: $(du -sh "${BACKUP_DIR}/db.sql.gz" | cut -f1)"
else
  log "WARNING: Container $DB_CONTAINER not running — skipping DB dump"
fi

# Config backup
log "Backing up config files..."
tar -czf "${BACKUP_DIR}/config.tar.gz" ./config/
log "Config backup: $(du -sh "${BACKUP_DIR}/config.tar.gz" | cut -f1)"

# Cleanup old backups
log "Removing backups older than ${RETENTION_DAYS} days..."
find ./backups -maxdepth 1 -type d -mtime "+${RETENTION_DAYS}" -exec rm -rf {} + 2>/dev/null || true

log "=== BACKUP COMPLETE ==="
echo "$BACKUP_DIR"
