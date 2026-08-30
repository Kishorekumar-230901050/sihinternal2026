-- Extended schema to match Luckfox device fields
-- Run this after 001_init.sql to add extra columns

-- Add city and state to devices
ALTER TABLE devices ADD COLUMN IF NOT EXISTS city TEXT;
ALTER TABLE devices ADD COLUMN IF NOT EXISTS state TEXT;

-- Extend tamper_logs with all Luckfox fields
ALTER TABLE tamper_logs ADD COLUMN IF NOT EXISTS resolution_status TEXT;
ALTER TABLE tamper_logs ADD COLUMN IF NOT EXISTS settling_time INTEGER;
ALTER TABLE tamper_logs ADD COLUMN IF NOT EXISTS renewal_cycle INTEGER;
ALTER TABLE tamper_logs ADD COLUMN IF NOT EXISTS latitude NUMERIC(9,6);
ALTER TABLE tamper_logs ADD COLUMN IF NOT EXISTS longitude NUMERIC(9,6);
ALTER TABLE tamper_logs ADD COLUMN IF NOT EXISTS city TEXT;
ALTER TABLE tamper_logs ADD COLUMN IF NOT EXISTS state TEXT;
ALTER TABLE tamper_logs ADD COLUMN IF NOT EXISTS drift NUMERIC;
ALTER TABLE tamper_logs ADD COLUMN IF NOT EXISTS prev_hash TEXT;
ALTER TABLE tamper_logs ADD COLUMN IF NOT EXISTS curr_hash TEXT;
ALTER TABLE tamper_logs ADD COLUMN IF NOT EXISTS pushed_at TIMESTAMP;
ALTER TABLE tamper_logs ADD COLUMN IF NOT EXISTS luckfox_log_id TEXT;

-- Index for tracking pushed records
CREATE INDEX IF NOT EXISTS idx_tamper_pushed ON tamper_logs(pushed_at);
