import React from "react";
import { Paper, Box, Typography } from "@mui/material";
import MapView from "@/components/MapView";

/**
 * DevicesMap - a small adapter component that allows DevicesPage to render the existing MapView
 * as a reusable component with a consistent prop surface.
 *
 * Props:
 *  - devices: array of device objects (same as MapPage filtered devices)
 *  - selectedDeviceId: optional id of the currently selected device
 *  - onMarkerClick: optional callback when a marker is clicked (device object or id)
 *  - height: optional map height (defaults to 520 or 70vh)
 *  - style: optional style object to pass to the wrapper box
 */
type DevicesMapProps = {
  devices?: any[];
  selectedDeviceId?: string | number | null;
  onMarkerClick?: (deviceOrId: any) => void;
  height?: number | string;
  style?: React.CSSProperties;
};

export default function DevicesMap({
  devices = [],
  selectedDeviceId,
  onMarkerClick,
  height = "70vh",
  style,
}: DevicesMapProps) {
  // MapView signature is unknown beyond the `devices` and `height` props we saw in your Map.tsx.
  // If MapView supports additional props (like onMarkerClick, selectedDeviceId), pass them via `as any`.
  const mapViewProps: any = {
    devices,
    height,
  };

  if (onMarkerClick) {
    // best-effort: pass callback in case MapView supports it
    mapViewProps.onMarkerClick = onMarkerClick;
  }
  if (selectedDeviceId !== undefined) {
    mapViewProps.selectedDeviceId = selectedDeviceId;
  }

  return (
    <Paper sx={{ p: 2, mt: 0, background: "#ffffff", border: "1px solid #d1d5db" }}>
      {/*
        Render the existing MapView. We pass devices & height as your Map page did.
        The `as any` cast lets us provide optional props without breaking TypeScript if MapView's types don't exist.
      */}
      <Box sx={{ width: "100%", height: height, minHeight: "400px" }} style={style}>
        <MapView {...(mapViewProps as any)} />
      </Box>

      {devices.length === 0 && (
        <Box sx={{ mt: 2 }}>
          <Typography variant="body2" color="text.secondary">
            No devices to show on map (filters may be hiding them).
          </Typography>
        </Box>
      )}
    </Paper>
  );
}
