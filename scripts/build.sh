#!/usr/bin/env bash
set -euo pipefail

PROJECT="tf05"
TAG="${1:-latest}"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

log "=== BUILD STARTED (tag: $TAG) ==="

log "Validating docker-compose.yml..."
docker compose config -q

log "Building images..."
docker compose build --parallel --no-cache

log "Tagging images..."
docker tag "${PROJECT}-api:latest"       "${PROJECT}-api:${TAG}"
docker tag "${PROJECT}-dashboard:latest" "${PROJECT}-dashboard:${TAG}"

log "=== BUILD COMPLETE ==="
