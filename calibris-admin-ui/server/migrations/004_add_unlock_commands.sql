-- Migration: Add unlock_commands table for remote device unlock feature
-- Created: 2025-12-11

CREATE TABLE IF NOT EXISTS unlock_commands (
  id SERIAL PRIMARY KEY,
  device_id INTEGER NOT NULL REFERENCES devices(device_id) ON DELETE CASCADE,
  officer_id VARCHAR(255) NOT NULL,
  reason TEXT,
  status VARCHAR(50) NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  executed_at TIMESTAMP,
  CONSTRAINT valid_status CHECK (status IN ('pending', 'executed', 'expired', 'failed'))
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_unlock_commands_device_status
  ON unlock_commands(device_id, status);

-- Index for finding pending commands quickly
CREATE INDEX IF NOT EXISTS idx_unlock_commands_pending
  ON unlock_commands(status, created_at)
  WHERE status = 'pending';
