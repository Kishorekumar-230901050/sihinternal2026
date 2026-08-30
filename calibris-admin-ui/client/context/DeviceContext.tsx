export { default as DeviceProvider } from "@/context/StoreProvider";
export { default as default } from "@/context/StoreProvider";
export { default as useDeviceStore } from "@/context/StoreContext";

// Provide compatibility exports: useDeviceContext hook and names
import StoreContext from "@/context/StoreContext";
import { useContext } from "react";

export function useDeviceContext() {
  const ctx = useContext(StoreContext as any);
  if (!ctx) throw new Error("useDeviceContext must be used within DeviceProvider");
  return ctx;
}
