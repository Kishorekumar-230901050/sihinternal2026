// client/context/types.ts
// Unified, permissive types (deviceType only, no model field)

export type DeviceStatus = "Online" | "Offline" | "OK" | "Tampered" | "Drifted" | string;

export interface Device {
  // allow both numbers and strings for id (keeps flexibility)
  id: number | string;

  // canonical device type field (camelCase only)
  deviceType?: string;

  owner?: string;
  location?: string;
  lat?: number;
  lng?: number;

  status?: DeviceStatus;
  lastUpdate?: string; // ISO timestamp

  // tamper fields (optional / nullable)
  tamperType?: string | null;
  tamperTime?: string | null; // ISO timestamp
  tamperDetails?: string | null;

  // drift value if available
  drift?: number | null;

  // allow other fields without breaking type-checks
  [key: string]: any;
}

export interface DeviceEvent {
  id: string;
  deviceId: number | string; // numeric or string (compat)
  type: string;
  timestamp: string;
  description?: string;
  [key: string]: any;
}

export interface AdminUserRow {
  id: string;
  name: string;
  email: string;
  role: string;
  lastLogin?: string;
  twoFA?: boolean;
  tokens?: number;
  [key: string]: any;
}

export interface AuditLogRow {
  id: string;
  timestamp: string;
  user: string;
  action: string;

  // device target id (string | number to match mocks)
  target: number | string;

  status?: DeviceStatus;
  clearanceBy?: string;
  clearanceAt?: string;
  clearanceToken?: string;

  [key: string]: any;
}
