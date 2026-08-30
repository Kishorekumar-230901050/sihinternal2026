-- Migration: Add status and last_login columns to users_meta table
-- For admin panel user management

-- Add status column (active/revoked)
ALTER TABLE users_meta ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active';

-- Add last_login column
ALTER TABLE users_meta ADD COLUMN IF NOT EXISTS last_login TIMESTAMP;

-- Add constraint for status values
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'users_meta_status_check'
    ) THEN
        ALTER TABLE users_meta ADD CONSTRAINT users_meta_status_check CHECK (status IN ('active', 'revoked'));
    END IF;
END $$;
