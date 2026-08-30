import React, { useState, useEffect } from "react";
import {
  Box,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Stack,
  TextField,
  Table,
  TableHead,
  TableBody,
  TableRow,
  TableCell,
  Chip,
  TableContainer,
  Paper,
  Checkbox,
  CircularProgress,
  Alert,
  MenuItem,
  Select,
  FormControl,
  InputLabel,
  IconButton,
  Tooltip,
} from "@mui/material";
import RefreshIcon from "@mui/icons-material/Refresh";
import Footer from "@/components/Footer";
import { API_BASE_URL } from "@/config/api";

interface Officer {
  uid: string;
  email: string;
  display_name: string;
  role: "admin" | "officer";
  status: "active" | "revoked";
  created_at: string;
  last_login: string | null;
}

export default function AdminPage() {
  const [officers, setOfficers] = useState<Officer[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  // Dialog states
  const [addDialogOpen, setAddDialogOpen] = useState(false);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [confirmDialogOpen, setConfirmDialogOpen] = useState(false);

  // Form states
  const [newName, setNewName] = useState("");
  const [newEmail, setNewEmail] = useState("");
  const [newRole, setNewRole] = useState<"admin" | "officer">("officer");

  // Selection state
  const [selectedUids, setSelectedUids] = useState<string[]>([]);
  const [editingOfficer, setEditingOfficer] = useState<Officer | null>(null);
  const [actionType, setActionType] = useState<"revoke" | "reactivate">("revoke");

  // Fetch officers from database
  const fetchOfficers = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await fetch(`${API_BASE_URL}/auth/users`, {
        headers: { "ngrok-skip-browser-warning": "true" },
      });
      if (!response.ok) throw new Error("Failed to fetch officers");
      const data = await response.json();
      setOfficers(data.users || []);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchOfficers();
  }, []);

  // Add new officer
  const handleAddOfficer = async () => {
    if (!newName.trim() || !newEmail.trim()) {
      setError("Name and Email are required");
      return;
    }

    try {
      const response = await fetch(`${API_BASE_URL}/auth/users`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
        body: JSON.stringify({
          displayName: newName,
          email: newEmail,
          role: newRole,
        }),
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || "Failed to add officer");
      }

      setSuccess("Officer added successfully");
      setAddDialogOpen(false);
      setNewName("");
      setNewEmail("");
      setNewRole("officer");
      fetchOfficers();
    } catch (err: any) {
      setError(err.message);
    }
  };

  // Edit officer
  const handleEditOfficer = async () => {
    if (!editingOfficer) return;

    try {
      const response = await fetch(`${API_BASE_URL}/auth/users/${editingOfficer.uid}`, {
        method: "PUT",
        headers: {
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
        body: JSON.stringify({
          displayName: newName,
          role: newRole,
        }),
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || "Failed to update officer");
      }

      setSuccess("Officer updated successfully");
      setEditDialogOpen(false);
      setEditingOfficer(null);
      setNewName("");
      setNewRole("officer");
      fetchOfficers();
    } catch (err: any) {
      setError(err.message);
    }
  };

  // Revoke or reactivate selected officers
  const handleBulkAction = async () => {
    if (selectedUids.length === 0) return;

    try {
      for (const uid of selectedUids) {
        const endpoint = actionType === "revoke"
          ? `${API_BASE_URL}/auth/users/${uid}`
          : `${API_BASE_URL}/auth/users/${uid}/reactivate`;

        const response = await fetch(endpoint, {
          method: actionType === "revoke" ? "DELETE" : "POST",
          headers: { "ngrok-skip-browser-warning": "true" },
        });

        if (!response.ok) {
          const data = await response.json();
          throw new Error(data.error || `Failed to ${actionType} officer`);
        }
      }

      setSuccess(`Successfully ${actionType === "revoke" ? "revoked" : "reactivated"} ${selectedUids.length} officer(s)`);
      setConfirmDialogOpen(false);
      setSelectedUids([]);
      fetchOfficers();
    } catch (err: any) {
      setError(err.message);
    }
  };

  // Open edit dialog
  const openEditDialog = () => {
    if (selectedUids.length !== 1) {
      setError("Please select exactly one officer to edit");
      return;
    }
    const officer = officers.find(o => o.uid === selectedUids[0]);
    if (officer) {
      setEditingOfficer(officer);
      setNewName(officer.display_name);
      setNewRole(officer.role);
      setEditDialogOpen(true);
    }
  };

  // Open confirm dialog for revoke
  const openRevokeDialog = () => {
    if (selectedUids.length === 0) {
      setError("Please select at least one officer to revoke");
      return;
    }
    setActionType("revoke");
    setConfirmDialogOpen(true);
  };

  // Toggle selection
  const toggleSelect = (uid: string) => {
    setSelectedUids(prev =>
      prev.includes(uid) ? prev.filter(u => u !== uid) : [...prev, uid]
    );
  };

  // Select all
  const toggleSelectAll = () => {
    if (selectedUids.length === officers.length) {
      setSelectedUids([]);
    } else {
      setSelectedUids(officers.map(o => o.uid));
    }
  };

  // Format date
  const formatDate = (dateStr: string | null) => {
    if (!dateStr) return "Never";
    return new Date(dateStr).toLocaleString("en-IN", {
      day: "2-digit",
      month: "short",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  return (
    <Box sx={{ p: { xs: 1, sm: 2 } }}>
      <h1 className="page-heading" style={{ fontSize: "clamp(1.25rem, 4vw, 1.5rem)", color: "#111827" }}>Admin</h1>

      {/* Success/Error alerts */}
      {error && (
        <Alert severity="error" onClose={() => setError(null)} sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}
      {success && (
        <Alert severity="success" onClose={() => setSuccess(null)} sx={{ mb: 2 }}>
          {success}
        </Alert>
      )}

      <Stack direction={{ xs: "column", sm: "row" }} spacing={{ xs: 1, sm: 2 }} sx={{ mb: 2 }} alignItems={{ xs: "stretch", sm: "center" }}>
        <Stack direction="row" spacing={1} sx={{ flexWrap: "wrap", gap: 1 }}>
          <Button variant="contained" onClick={() => setAddDialogOpen(true)} size="small" sx={{ fontSize: { xs: "0.75rem", sm: "0.875rem" } }}>
            Add User
          </Button>
          <Button
            variant="outlined"
            onClick={openEditDialog}
            disabled={selectedUids.length !== 1}
            size="small"
            sx={{ fontSize: { xs: "0.75rem", sm: "0.875rem" } }}
          >
            Edit Selected
          </Button>
          <Button
            variant="outlined"
            color="error"
            onClick={openRevokeDialog}
            disabled={selectedUids.length === 0}
            size="small"
            sx={{ fontSize: { xs: "0.75rem", sm: "0.875rem" } }}
          >
            Revoke ({selectedUids.length})
          </Button>
        </Stack>
        <Box sx={{ flexGrow: 1, display: { xs: "none", sm: "block" } }} />
        <Tooltip title="Refresh">
          <IconButton onClick={fetchOfficers} disabled={loading} size="small">
            <RefreshIcon />
          </IconButton>
        </Tooltip>
      </Stack>

      {/* Officers Table */}
      <TableContainer
        component={Paper}
        sx={{
          background: "#ffffff",
          border: "1px solid #d1d5db",
          overflowX: "auto",
          boxShadow: '0 1px 2px rgba(0,0,0,0.05)',
        }}
      >
        <Table size="small" sx={{ minWidth: { xs: 500, sm: 700 } }}>
          <TableHead>
            <TableRow>
              <TableCell padding="checkbox">
                <Checkbox
                  checked={selectedUids.length === officers.length && officers.length > 0}
                  indeterminate={selectedUids.length > 0 && selectedUids.length < officers.length}
                  onChange={toggleSelectAll}
                  size="small"
                />
              </TableCell>
              <TableCell sx={{ fontSize: { xs: "0.75rem", sm: "0.875rem" } }}>Name</TableCell>
              <TableCell sx={{ fontSize: { xs: "0.75rem", sm: "0.875rem" } }}>Email</TableCell>
              <TableCell sx={{ fontSize: { xs: "0.75rem", sm: "0.875rem" } }}>Role</TableCell>
              <TableCell sx={{ fontSize: { xs: "0.75rem", sm: "0.875rem" } }}>Status</TableCell>
              <TableCell sx={{ fontSize: { xs: "0.75rem", sm: "0.875rem" }, display: { xs: "none", sm: "table-cell" } }}>Last Login</TableCell>
              <TableCell sx={{ fontSize: { xs: "0.75rem", sm: "0.875rem" }, display: { xs: "none", sm: "table-cell" } }}>Created</TableCell>
            </TableRow>
          </TableHead>

          <TableBody>
            {loading ? (
              <TableRow>
                <TableCell colSpan={7} align="center" sx={{ py: 4 }}>
                  <CircularProgress size={24} />
                </TableCell>
              </TableRow>
            ) : officers.length === 0 ? (
              <TableRow>
                <TableCell colSpan={7} align="center" sx={{ py: 4, color: "#6b7280" }}>
                  No officers found. Add your first officer above.
                </TableCell>
              </TableRow>
            ) : (
              officers.map((officer) => (
                <TableRow
                  key={officer.uid}
                  hover
                  selected={selectedUids.includes(officer.uid)}
                  sx={{ cursor: "pointer" }}
                  onClick={() => toggleSelect(officer.uid)}
                >
                  <TableCell padding="checkbox">
                    <Checkbox
                      checked={selectedUids.includes(officer.uid)}
                      onClick={(e) => e.stopPropagation()}
                      onChange={() => toggleSelect(officer.uid)}
                      size="small"
                    />
                  </TableCell>
                  <TableCell sx={{ fontSize: { xs: "0.75rem", sm: "0.875rem" } }}>{officer.display_name}</TableCell>
                  <TableCell sx={{ fontSize: { xs: "0.75rem", sm: "0.875rem" }, maxWidth: { xs: 120, sm: "none" }, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{officer.email}</TableCell>
                  <TableCell>
                    <Chip
                      label={officer.role}
                      size="small"
                      color={officer.role === "admin" ? "success" : "default"}
                      sx={{ fontSize: { xs: "0.65rem", sm: "0.75rem" } }}
                    />
                  </TableCell>
                  <TableCell>
                    <Chip
                      label={officer.status}
                      size="small"
                      color={officer.status === "active" ? "success" : "error"}
                      variant={officer.status === "revoked" ? "outlined" : "filled"}
                      sx={{ fontSize: { xs: "0.65rem", sm: "0.75rem" } }}
                    />
                  </TableCell>
                  <TableCell sx={{ fontSize: { xs: "0.75rem", sm: "0.875rem" }, display: { xs: "none", sm: "table-cell" } }}>{formatDate(officer.last_login)}</TableCell>
                  <TableCell sx={{ fontSize: { xs: "0.75rem", sm: "0.875rem" }, display: { xs: "none", sm: "table-cell" } }}>{formatDate(officer.created_at)}</TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Add User Dialog */}
      <Dialog open={addDialogOpen} onClose={() => setAddDialogOpen(false)} fullWidth maxWidth="sm">
        <DialogTitle>Add Officer</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField
              label="Name"
              fullWidth
              value={newName}
              onChange={(e) => setNewName(e.target.value)}
              placeholder="Enter officer name"
            />
            <TextField
              label="Email"
              fullWidth
              type="email"
              value={newEmail}
              onChange={(e) => setNewEmail(e.target.value)}
              placeholder="Enter officer email"
            />
            <FormControl fullWidth>
              <InputLabel>Role</InputLabel>
              <Select
                value={newRole}
                label="Role"
                onChange={(e) => setNewRole(e.target.value as "admin" | "officer")}
              >
                <MenuItem value="officer">Officer</MenuItem>
                <MenuItem value="admin">Admin</MenuItem>
              </Select>
            </FormControl>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setAddDialogOpen(false)}>Cancel</Button>
          <Button variant="contained" onClick={handleAddOfficer}>
            Add Officer
          </Button>
        </DialogActions>
      </Dialog>

      {/* Edit User Dialog */}
      <Dialog open={editDialogOpen} onClose={() => setEditDialogOpen(false)} fullWidth maxWidth="sm">
        <DialogTitle>Edit Officer</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField
              label="Name"
              fullWidth
              value={newName}
              onChange={(e) => setNewName(e.target.value)}
            />
            <TextField
              label="Email"
              fullWidth
              value={editingOfficer?.email || ""}
              disabled
              helperText="Email cannot be changed"
            />
            <FormControl fullWidth>
              <InputLabel>Role</InputLabel>
              <Select
                value={newRole}
                label="Role"
                onChange={(e) => setNewRole(e.target.value as "admin" | "officer")}
              >
                <MenuItem value="officer">Officer</MenuItem>
                <MenuItem value="admin">Admin</MenuItem>
              </Select>
            </FormControl>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEditDialogOpen(false)}>Cancel</Button>
          <Button variant="contained" onClick={handleEditOfficer}>
            Save Changes
          </Button>
        </DialogActions>
      </Dialog>

      {/* Confirm Revoke Dialog */}
      <Dialog open={confirmDialogOpen} onClose={() => setConfirmDialogOpen(false)}>
        <DialogTitle>Confirm {actionType === "revoke" ? "Revoke" : "Reactivate"}</DialogTitle>
        <DialogContent>
          Are you sure you want to {actionType} {selectedUids.length} officer(s)?
          {actionType === "revoke" && (
            <Box sx={{ mt: 1, color: "#d97706" }}>
              Revoked officers will not be able to log in until reactivated.
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setConfirmDialogOpen(false)}>Cancel</Button>
          <Button
            variant="contained"
            color={actionType === "revoke" ? "error" : "success"}
            onClick={handleBulkAction}
          >
            {actionType === "revoke" ? "Revoke" : "Reactivate"}
          </Button>
        </DialogActions>
      </Dialog>

      <Footer />
    </Box>
  );
}
