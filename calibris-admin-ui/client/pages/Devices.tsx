// client/pages/Devices.tsx
import React, { useEffect, useMemo } from "react";
import {
  Box,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Typography,
  Stack,
  useTheme,
} from "@mui/material";
import { useStore } from "@/context/StoreContext";
import FiltersPanel from "@/components/FiltersPanel";
import DeviceDetailsPanel from "@/components/DeviceDetailsPanel";
import Footer from "@/components/Footer";
import { useLocation } from "react-router-dom";

import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group";
import DevicesMap from "@/components/DevicesMap";

function useQuery() {
  return new URLSearchParams(useLocation().search);
}

type ViewMode = "list" | "map";

export default function DevicesPage() {
  const theme = useTheme();
  const { devices = [], filters, selectedDeviceId, setSelectedDeviceId } = useStore();
  const query = useQuery();

  // default view
  const [view, setView] = React.useState<ViewMode>("list");

  useEffect(() => {
    const serial = query.get("serial");
    if (serial) setSelectedDeviceId(serial);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const filtered = useMemo(() => {
    return (devices || []).filter((d: any) => {
      // build a searchable string including device_type (with fallbacks) and owner
      const searchable = [d.id, d.device_type ?? (d as any).deviceType ?? d.model, d.owner]
        .filter(Boolean)
        .join(" ")
        .toLowerCase();

      const matchesSearch = searchable.includes((filters?.search ?? "").toLowerCase());

      const matchesStatus =
        (filters?.status ?? "All") === "All" ||
        d.status === filters.status ||
        ((filters?.status ?? "") === "Online" && d.status === "OK");

      const matchesLocation =
        (filters?.location ?? "All") === "All" || d.location === filters.location;

      const matchesDate = !filters?.date || d.lastUpdate?.slice(0, 10) === filters.date;

      return matchesSearch && matchesStatus && matchesLocation && matchesDate;
    });
  }, [devices, filters]);

  function onSelectRow(id: string) {
    setSelectedDeviceId(id);
  }

  function onMapMarkerClick(deviceOrId: any) {
    if (!deviceOrId) return;
    const id =
      typeof deviceOrId === "string" || typeof deviceOrId === "number"
        ? deviceOrId
        : deviceOrId.id ?? deviceOrId.device_id;

    setSelectedDeviceId(id);
  }

  // rgb of gov action blue #2563eb
  const accentRgb = "37,99,235";

  return (
    <Box sx={{ py: { xs: 1, sm: 2 }, px: { xs: 1, sm: 0 }, width: "100%" }}>
      {/* PAGE TITLE */}
      <Typography variant="h5" sx={{ mb: { xs: 1.5, sm: 2 }, fontWeight: 700, fontSize: { xs: "1.1rem", sm: "1.25rem" }, color: "#111827", px: { xs: 1, sm: 0 } }}>
        Devices
      </Typography>

      {/* FILTERS */}
      <Box sx={{ mb: { xs: 1.5, sm: 2 } }}>
        <FiltersPanel />
      </Box>

      {/* MAIN GRID */}
      <Box
        sx={{
          display: "grid",
          gridTemplateColumns: { xs: "1fr", md: "70% 30%" },
          gap: { xs: 2, sm: 3 },
          alignItems: "start",
        }}
      >
        {/* LEFT COLUMN */}
        <Box sx={{ width: "100%" }}>
          {/* Centered toggle with device count at the right */}
          <Box sx={{ mb: 1, position: "relative" }}>
            <Box sx={{ display: "flex", justifyContent: "center" }}>
              {/* NOTE: removed variant & size props to match component prop types */}
              <ToggleGroup
                type="single"
                value={view}
                onValueChange={(v) => {
                  if (!v) return;
                  setView(v as ViewMode);
                }}
              >
                <ToggleGroupItem value="list">LIST</ToggleGroupItem>
                <ToggleGroupItem value="map">MAP</ToggleGroupItem>
              </ToggleGroup>
            </Box>

            {/* device count anchored to right of the left column */}
            <Box
              sx={{
                position: { xs: "static", sm: "absolute" },
                right: 4,
                top: 0,
                height: { sm: "100%" },
                display: "flex",
                alignItems: "center",
                justifyContent: { xs: "center", sm: "flex-end" },
                color: "text.secondary",
                fontSize: { xs: 12, sm: 13 },
                pl: 1,
                mt: { xs: 0.5, sm: 0 },
              }}
            >
              {filtered.length} devices
            </Box>
          </Box>

          {/* LIST VIEW */}
          {view === "list" ? (
            <TableContainer
              component={Paper}
              sx={{
                mt: 0,
                background: "#ffffff",
                border: "1px solid #d1d5db",
                overflowX: "auto",
                boxShadow: '0 1px 2px rgba(0,0,0,0.05)',
              }}
            >
              <Table size="small" sx={{ minWidth: { xs: 500, sm: 650 } }}>
                <TableHead>
                  <TableRow>
                    <TableCell sx={{ fontWeight: 700, fontSize: { xs: "0.8rem", sm: "0.98rem" }, whiteSpace: "nowrap" }}>Device_id</TableCell>
                    <TableCell sx={{ fontWeight: 700, fontSize: { xs: "0.8rem", sm: "0.98rem" }, whiteSpace: "nowrap", display: { xs: "none", sm: "table-cell" } }}>Device type</TableCell>
                    <TableCell sx={{ fontWeight: 700, fontSize: { xs: "0.8rem", sm: "0.98rem" }, whiteSpace: "nowrap" }}>Owner</TableCell>
                    <TableCell sx={{ fontWeight: 700, fontSize: { xs: "0.8rem", sm: "0.98rem" }, whiteSpace: "nowrap" }}>Status</TableCell>
                    <TableCell sx={{ fontWeight: 700, fontSize: { xs: "0.8rem", sm: "0.98rem" }, whiteSpace: "nowrap", display: { xs: "none", sm: "table-cell" } }}>Last Update</TableCell>
                  </TableRow>
                </TableHead>

                <TableBody>
                  {filtered.map((d: any) => (
                    <TableRow
                      key={d.id}
                      hover
                      selected={d.id === selectedDeviceId}
                      onClick={() => onSelectRow(d.id)}
                      sx={{
                        cursor: "pointer",
                        transition: "background-color 150ms ease, transform 80ms ease",
                        // Non-selected hover
                        "&:hover": {
                          backgroundColor: `rgba(${accentRgb}, 0.06)`,
                        },
                        // Ensure cells inherit transparent background so the row color shows
                        "& .MuiTableCell-root": {
                          backgroundColor: "transparent",
                        },
                        // Selected state (when a row is selected) — high specificity
                        "&.Mui-selected, &.Mui-selected td, &.Mui-selected .MuiTableCell-root": {
                          backgroundColor: `rgba(${accentRgb}, 0.12) !important`,
                        },
                        // Selected + hover (slightly stronger)
                        "&.Mui-selected:hover, &.Mui-selected:hover td, &.Mui-selected:hover .MuiTableCell-root": {
                          backgroundColor: `rgba(${accentRgb}, 0.16) !important`,
                        },
                        // Slight press effect
                        "&:active": {
                          transform: "translateY(0.5px)",
                        },
                      }}
                    >
                      <TableCell sx={{ fontSize: { xs: "0.8rem", sm: "0.95rem" } }}>{d.id}</TableCell>
                      <TableCell sx={{ fontSize: { xs: "0.8rem", sm: "0.95rem" }, display: { xs: "none", sm: "table-cell" } }}>
                        {d.device_type ?? (d as any).deviceType ?? d.model ?? "-"}
                      </TableCell>
                      <TableCell sx={{ fontSize: { xs: "0.8rem", sm: "0.95rem" }, maxWidth: { xs: 100, sm: "none" }, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{d.owner}</TableCell>
                      <TableCell sx={{ fontSize: { xs: "0.8rem", sm: "0.95rem" } }}>{d.status}</TableCell>
                      <TableCell sx={{ fontSize: { xs: "0.8rem", sm: "0.95rem" }, display: { xs: "none", sm: "table-cell" } }}>
                        {d.lastUpdate ? new Date(d.lastUpdate).toLocaleDateString() : "-"}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          ) : (
            /* MAP VIEW */
            <Box sx={{ mt: 0, height: { xs: "50vh", sm: "72vh" }, overflow: "hidden" }}>
              <DevicesMap
                devices={filtered}
                selectedDeviceId={selectedDeviceId}
                onMarkerClick={onMapMarkerClick}
                height="100%"
              />
            </Box>
          )}
        </Box>

        {/* RIGHT COLUMN — DEVICE DETAILS PANEL */}
        <Box sx={{ width: "100%", position: { md: "sticky" }, top: { md: 88 } }}>
          <DeviceDetailsPanel />
        </Box>
      </Box>

      <Footer />
    </Box>
  );
}
