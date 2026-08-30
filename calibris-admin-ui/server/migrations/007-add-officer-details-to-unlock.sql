-- Migration: Add officer details to unlock_commands table
-- For Legal Metrology report generation with complete officer information

-- Add officer_name column
ALTER TABLE unlock_commands ADD COLUMN IF NOT EXISTS officer_name TEXT;

-- Add officer_email column
ALTER TABLE unlock_commands ADD COLUMN IF NOT EXISTS officer_email TEXT;

-- Add officer_role column
ALTER TABLE unlock_commands ADD COLUMN IF NOT EXISTS officer_role TEXT;

-- Add index for faster lookups by officer
CREATE INDEX IF NOT EXISTS idx_unlock_commands_officer
  ON unlock_commands(officer_email);
