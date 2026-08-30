import React, { createContext, useContext } from "react";
import { AdminUserRow, AuditLogRow, Device, DeviceEvent, Filters, UserInfo } from "./types";

export interface StoreState {
  devices: Device[];
  events: DeviceEvent[];
  users: AdminUserRow[];
  audit: AuditLogRow[];
  user: UserInfo;
  filters: Filters;
  selectedDeviceId: string | null;

  setSelectedDeviceId: (id: string | null) => void;
  setFilters: (patch: Partial<Filters>) => void;
  clearFilters: () => void;
  addEvent: (ev: DeviceEvent) => void;
}

const StoreContext = createContext<StoreState | undefined>(undefined);
export const useStore = () => {
  const ctx = useContext(StoreContext);
  if (!ctx) throw new Error("useStore must be used within StoreProvider");
  return ctx;
};

export default StoreContext;
