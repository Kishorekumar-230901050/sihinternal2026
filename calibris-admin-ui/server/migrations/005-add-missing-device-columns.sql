-- Migration: Add missing columns to devices table for unlock feature
-- Date: 2025-12-10
-- This adds essential columns needed by the dashboard and unlock endpoints

-- Add missing columns to devices table
ALTER TABLE devices ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'online';
ALTER TABLE devices ADD COLUMN IF NOT EXISTS location TEXT;
ALTER TABLE devices ADD COLUMN IF NOT EXISTS owner TEXT;
ALTER TABLE devices ADD COLUMN IF NOT EXISTS last_update TIMESTAMP DEFAULT NOW();
ALTER TABLE devices ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW();
ALTER TABLE devices ADD COLUMN IF NOT EXISTS latitude NUMERIC(9,6);
ALTER TABLE devices ADD COLUMN IF NOT EXISTS longitude NUMERIC(9,6);
ALTER TABLE devices ADD COLUMN IF NOT EXISTS city TEXT;
ALTER TABLE devices ADD COLUMN IF NOT EXISTS state TEXT;

-- Add id column as alias to device_id for API compatibility
ALTER TABLE devices ADD COLUMN IF NOT EXISTS id INTEGER;
UPDATE devices SET id = device_id WHERE id IS NULL;

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_devices_status ON devices(status);
CREATE INDEX IF NOT EXISTS idx_devices_last_update ON devices(last_update DESC);

-- Update existing Device 1 with some default values
UPDATE devices
SET
  status = 'online',
  location = 'Lab Testing',
  owner = 'Admin',
  last_update = NOW(),
  created_at = NOW()
WHERE device_id = 1 AND status IS NULL;

-- Add comments
COMMENT ON COLUMN devices.status IS 'Device status: online, offline, safe_mode, Tampered';
COMMENT ON COLUMN devices.id IS 'Alias for device_id for API compatibility';
