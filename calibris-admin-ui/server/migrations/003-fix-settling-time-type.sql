-- Migration: Change settling_time from INTEGER to NUMERIC to accept decimals
-- Date: 2025-12-10

ALTER TABLE tamper_logs
ALTER COLUMN settling_time TYPE NUMERIC;

COMMENT ON COLUMN tamper_logs.settling_time IS 'Settling time in seconds (supports decimals like 0.5)';
