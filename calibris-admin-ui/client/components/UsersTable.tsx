import React from "react";
import {
  Table,
  TableHead,
  TableBody,
  TableRow,
  TableCell,
  Chip,
  TableContainer,
  Paper
} from "@mui/material";
import { useStore } from "@/context/StoreContext";

export default function UsersTable() {
  const { users } = useStore();

  return (
    <TableContainer
      component={Paper}
      sx={{
        background: "#ffffff",
        border: "1px solid #d1d5db"
      }}
    >
      <Table size="small">
        <TableHead>
          <TableRow>
            <TableCell>Name</TableCell>
            <TableCell>Email</TableCell>
            <TableCell>Role</TableCell>
            <TableCell>Last login</TableCell>
          </TableRow>
        </TableHead>

        <TableBody>
          {users.map((u) => (
            <TableRow key={u.id} hover>
              <TableCell>{u.name}</TableCell>

              <TableCell>{u.email}</TableCell>

              <TableCell>
                <Chip
                  label={u.role}
                  size="small"
                  color={u.role === "Admin" ? "success" : "default"}
                />
              </TableCell>

              <TableCell>
                {u.lastLogin
                  ? new Date(u.lastLogin).toLocaleString()
                  : "—"}
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </TableContainer>
  );
}
