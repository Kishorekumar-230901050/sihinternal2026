-- Migration: Add city and state columns to devices table
-- Date: 2025-12-10

ALTER TABLE devices
ADD COLUMN IF NOT EXISTS city VARCHAR(100),
ADD COLUMN IF NOT EXISTS state VARCHAR(100);

-- Add comment for documentation
COMMENT ON COLUMN devices.city IS 'City location of the device';
COMMENT ON COLUMN devices.state IS 'State/Province location of the device';
