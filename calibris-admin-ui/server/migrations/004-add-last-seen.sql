-- Add last_seen column to track device online status
ALTER TABLE devices ADD COLUMN IF NOT EXISTS last_seen TIMESTAMP DEFAULT NOW();

-- Create index for fast status queries
CREATE INDEX IF NOT EXISTS idx_devices_last_seen ON devices(last_seen);

-- Update existing devices to have recent last_seen
UPDATE devices SET last_seen = NOW() WHERE last_seen IS NULL;
