-- Migration: add trend analysis support
ALTER TABLE health_checks ADD COLUMN IF NOT EXISTS consecutive_failures INTEGER DEFAULT 0;
ALTER TABLE services ADD COLUMN IF NOT EXISTS last_status VARCHAR(20) DEFAULT 'unknown';
ALTER TABLE services ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();
