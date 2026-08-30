-- Migration: Recreate devices table with simplified schema
-- Date: 2025-12-10
-- WARNING: This will delete all existing device data!

-- Drop the old devices table (this will cascade delete related tamper_logs)
DROP TABLE IF EXISTS devices CASCADE;

-- Create device_users table if it doesn't exist
CREATE TABLE IF NOT EXISTS device_users (
    user_id SERIAL PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create new devices table with simplified schema
CREATE TABLE devices (
    device_id SERIAL PRIMARY KEY,
    user_id INTEGER,
    device_type TEXT,
    purchase_date TEXT,  -- ISO8601 date string
    FOREIGN KEY (user_id) REFERENCES device_users(user_id) ON DELETE SET NULL
);

-- Add indexes for better query performance
CREATE INDEX idx_devices_user_id ON devices(user_id);
CREATE INDEX idx_devices_device_type ON devices(device_type);

-- Add comments for documentation
COMMENT ON TABLE devices IS 'Simplified device registration table';
COMMENT ON COLUMN devices.device_id IS 'Auto-incrementing primary key for device';
COMMENT ON COLUMN devices.user_id IS 'Foreign key reference to device_users table';
COMMENT ON COLUMN devices.device_type IS 'Type of device (e.g., motion-sensor, camera, etc.)';
COMMENT ON COLUMN devices.purchase_date IS 'ISO8601 date string when device was purchased';
