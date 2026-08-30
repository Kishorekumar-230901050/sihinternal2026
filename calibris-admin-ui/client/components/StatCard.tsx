import { Card, CardContent, Typography, Box } from "@mui/material";
import React from "react";

export default function StatCard({ label, value, color }: { label: string; value: number; color: string }) {
  return (
    <Card
      elevation={0}
      sx={{
        background: "#ffffff",
        border: "1px solid #d1d5db",
        borderRadius: "6px",
      }}
    >
      <CardContent sx={{ display: "flex", flexDirection: "column", gap: 0.5, py: 2, "&:last-child": { pb: 2 } }}>
        <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
          <Box sx={{ width: 8, height: 8, borderRadius: 9999, bgcolor: color }} />
          <Typography
            variant="body2"
            sx={{
              color: "#6b7280",
              fontSize: "0.85rem",
              fontWeight: 600,
            }}
          >
            {label}
          </Typography>
        </Box>
        <Typography
          variant="h4"
          sx={{
            color: "#111827",
            fontWeight: 800,
          }}
        >
          {value.toLocaleString()}
        </Typography>
      </CardContent>
    </Card>
  );
}
