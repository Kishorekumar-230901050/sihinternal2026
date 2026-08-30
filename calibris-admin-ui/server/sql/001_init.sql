-- Initial schema for devices, tamper logs, and user metadata

CREATE TABLE IF NOT EXISTS users_meta (
  uid TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('admin','officer')),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS devices (
  device_id TEXT PRIMARY KEY,
  device_type TEXT,
  owner TEXT,
  status TEXT,
  location TEXT,
  latitude NUMERIC(9,6),
  longitude NUMERIC(9,6),
  last_update TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tamper_logs (
  id SERIAL PRIMARY KEY,
  device_id TEXT NOT NULL,
  tamper_type TEXT,
  severity TEXT,
  details TEXT,
  event_time TIMESTAMP NOT NULL DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW(),
  FOREIGN KEY (device_id) REFERENCES devices(device_id)
);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_tamper_device_time ON tamper_logs(device_id, event_time DESC);
CREATE INDEX IF NOT EXISTS idx_users_email ON users_meta(email);
