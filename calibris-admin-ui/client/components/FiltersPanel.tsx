import { Box, MenuItem, TextField } from "@mui/material";
import React from "react";
import { useStore } from "@/context/StoreContext";

export default function FiltersPanel({ compact = false }: { compact?: boolean }) {
  const { filters, setFilters } = useStore();

  return (
    <Box
      sx={{
        display: "flex",
        gap: { xs: 1, sm: 2 },
        flexWrap: "wrap",
        p: { xs: 1.5, sm: 2 },
        background: "#ffffff",
        border: "1px solid #d1d5db",
        borderRadius: 2,
      }}
    >
      <TextField
        size="small"
        label="Search Serial, Model"
        value={filters.search}
        onChange={(e) => setFilters({ search: e.target.value })}
        sx={{
          minWidth: { xs: "100%", sm: compact ? 140 : 200 },
          flex: { xs: "1 1 100%", sm: "0 0 auto" }
        }}
      />

      <TextField
        size="small"
        select
        label="Status"
        value={filters.status}
        onChange={(e) => setFilters({ status: e.target.value as any })}
        sx={{
          minWidth: { xs: "calc(50% - 4px)", sm: compact ? 140 : 200 },
          flex: { xs: "1 1 calc(50% - 4px)", sm: "0 0 auto" }
        }}
      >
        {["All", "Online", "Offline", "Tampered", "Drifted"].map((s) => (
          <MenuItem key={s} value={s}>
            {s}
          </MenuItem>
        ))}
      </TextField>

      <TextField
        size="small"
        select
        label="Location"
        value={filters.location}
        onChange={(e) => setFilters({ location: e.target.value as any })}
        sx={{
          minWidth: { xs: "calc(50% - 4px)", sm: compact ? 140 : 200 },
          flex: { xs: "1 1 calc(50% - 4px)", sm: "0 0 auto" },
          display: { xs: "none", sm: "flex" }
        }}
      >
        {[
          "All",
          "Mumbai, MH",
          "Bengaluru, KA",
          "Chennai, TN",
          "Delhi, DL",
          "Kolkata, WB",
          "Hyderabad, TS",
          "Pune, MH",
          "Ahmedabad, GJ",
          "Jaipur, RJ",
          "Lucknow, UP",
          "Kochi, KL",
          "Bhopal, MP",
          "Indore, MP",
          "Varanasi, UP",
          "Surat, GJ",
          "Thiruvananthapuram, KL",
          "Patna, BR",
          "Bhubaneswar, OR",
          "Coimbatore, TN",
          "Vadodara, GJ",
        ].map((s) => (
          <MenuItem key={s} value={s}>
            {s}
          </MenuItem>
        ))}
      </TextField>

      <TextField
        size="small"
        type="date"
        label="Date"
        value={filters.date}
        onChange={(e) => setFilters({ date: e.target.value })}
        sx={{
          minWidth: { xs: "calc(50% - 4px)", sm: compact ? 140 : 200 },
          flex: { xs: "1 1 calc(50% - 4px)", sm: "0 0 auto" }
        }}
        InputLabelProps={{ shrink: true }}
      />
    </Box>
  );
}
