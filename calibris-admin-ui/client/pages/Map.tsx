// client/pages/Map.tsx
import React, { useMemo } from "react";
import {
  Box,
  Grid,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Typography,
} from "@mui/material";
import { useStore } from "@/context/StoreContext";
import FiltersPanel from "@/components/FiltersPanel";
import MapView from "@/components/MapView";
import Footer from "@/components/Footer";
import { useNavigate } from "react-router-dom";

export default function MapPage() {
  const { devices = [], filters, setSelectedDeviceId } = useStore();
  const navigate = useNavigate();

  const filtered = useMemo(() => {
    return (devices || []).filter((d: any) => {
      const matchesStatus =
        filters.status === "All" ||
        d.status === filters.status ||
        (filters.status === "Online" && d.status === "OK");
      const matchesLocation = filters.location === "All" || d.location === filters.location;
      return matchesStatus && matchesLocation;
    });
  }, [devices, filters]);

  return (
    <Box sx={{ p: 2 }}>
      <Typography variant="h5" sx={{ mb: 2, fontWeight: 700, fontSize: "1.25rem" }}>
        Map
      </Typography>

      <FiltersPanel compact />
      <Paper sx={{ p: 2, mt: 2, background: "#ffffff", border: "1px solid #d1d5db" }}>
        {/* PASS THE FILTERED DEVICES so pins follow the table */}
        <MapView height={360} devices={filtered} />
      </Paper>

      <TableContainer component={Paper} sx={{ mt: 2, background: "#ffffff", border: "1px solid #d1d5db" }}>
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell sx={{ fontWeight: 700, fontSize: "0.98rem" }}>Machine ID</TableCell>
              <TableCell sx={{ fontWeight: 700, fontSize: "0.98rem" }}>Location</TableCell>
              <TableCell sx={{ fontWeight: 700, fontSize: "0.98rem" }}>Status</TableCell>
              <TableCell sx={{ fontWeight: 700, fontSize: "0.98rem" }}>Last Update</TableCell>
            </TableRow>
          </TableHead>

          <TableBody>
            {filtered.map((d: any) => (
              <TableRow
                key={d.id}
                hover
                sx={{ cursor: "pointer" }}
                onClick={() => {
                  setSelectedDeviceId(d.id);
                  navigate("/devices");
                }}
              >
                <TableCell sx={{ fontSize: "0.95rem" }}>{d.id}</TableCell>
                <TableCell sx={{ fontSize: "0.95rem" }}>{d.location}</TableCell>
                <TableCell sx={{ fontSize: "0.95rem" }}>{d.status}</TableCell>
                <TableCell sx={{ fontSize: "0.95rem" }}>
                  {d.lastUpdate ? new Date(d.lastUpdate).toLocaleString() : "-"}
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>

      <Footer />
    </Box>
  );
}
