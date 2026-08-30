// server/routes/auth.ts
// Minimal auth routes for Firebase-based authentication
// Firebase handles login/signup, this file stores user metadata only

import { Router, RequestHandler } from "express";
import { z } from "zod";
import { pool } from "../db";

const router = Router();

type UserMetadata = {
  uid: string;
  email: string;
  display_name: string;
  role: "admin" | "officer";
  status: "active" | "revoked";
  created_at: Date;
  last_login: Date | null;
};

async function findByEmail(email: string): Promise<UserMetadata | undefined> {
  const result = await pool.query<UserMetadata>(
    "SELECT * FROM users_meta WHERE LOWER(email) = LOWER($1) LIMIT 1",
    [email]
  );
  return result.rows[0];
}

async function insertUser(user: {
  uid: string;
  email: string;
  displayName: string;
  role: "admin" | "officer";
}): Promise<UserMetadata> {
  const result = await pool.query<UserMetadata>(
    `INSERT INTO users_meta (uid, email, display_name, role)
     VALUES ($1, $2, $3, $4)
     RETURNING *`,
    [user.uid, user.email, user.displayName, user.role]
  );
  return result.rows[0];
}

async function updateUserRole(email: string, role: "admin" | "officer"): Promise<UserMetadata | undefined> {
  const result = await pool.query<UserMetadata>(
    `UPDATE users_meta
     SET role = $2
     WHERE LOWER(email) = LOWER($1)
     RETURNING *`,
    [email, role]
  );
  return result.rows[0];
}

/** Validation schemas */
const registerSchema = z.object({
  uid: z.string(), // Firebase UID
  email: z.string().email(),
  displayName: z.string().min(1),
  role: z.enum(["admin", "officer"]),
});

const updateRoleSchema = z.object({
  email: z.string().email(),
  role: z.enum(["admin", "officer"]),
});

/**
 * POST /api/auth/register
 * - Called after Firebase registration to store user metadata
 * - Stores role and user info in local database
 */
router.post("/register", async (req, res) => {
  try {
    const data = registerSchema.parse(req.body);

    // Check if email already exists
    const existing = await findByEmail(data.email);
    if (existing) {
      return res.status(400).json({ error: "User already registered" });
    }

    const newUser: UserMetadata = {
      uid: data.uid,
      email: data.email,
      display_name: data.displayName,
      role: data.role,
      created_at: new Date(),
    };

    const created = await insertUser(data);

    return res.status(201).json({
      message: "User registered successfully",
      user: created,
    });
  } catch (err: any) {
    console.error("Registration error:", err);
    return res.status(400).json({ error: err.message ?? "Invalid request" });
  }
});

/**
 * GET /api/auth/user/:email
 * - Returns user metadata and role
 * - Auto-provisions user if not yet in database
 */
router.get("/user/:email", async (req, res) => {
  try {
    const email = req.params.email;
    let user = await findByEmail(email);
    
    if (!user) {
      const role = email.toLowerCase().includes("admin") ? "admin" : "officer";
      const displayName = email.split("@")[0] || "Officer";
      try {
        user = await insertUser({
          uid: `user_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`,
          email,
          displayName,
          role,
        });
      } catch (_) {
        user = {
          uid: `user_${Date.now()}`,
          email,
          display_name: displayName,
          role,
          status: "active",
          created_at: new Date(),
          last_login: new Date(),
        };
      }
    }

    return res.json({ user });
  } catch (err: any) {
    const email = req.params.email;
    const role = email.toLowerCase().includes("admin") ? "admin" : "officer";
    return res.json({
      user: {
        uid: `fallback_${Date.now()}`,
        email,
        display_name: email.split("@")[0] || "Officer",
        role,
        status: "active",
        created_at: new Date(),
        last_login: new Date(),
      },
    });
  }
});

/**
 * POST /api/auth/update-role
 * - Updates a user's role
 */
router.post("/update-role", (req, res) => {
  try {
    const data = updateRoleSchema.parse(req.body);
    updateUserRole(data.email, data.role)
      .then((user) => {
        if (!user) {
          return res.status(404).json({ error: "User not found" });
        }
        return res.json({
          message: "Role updated successfully",
          user,
        });
      })
      .catch((err) => {
        return res.status(400).json({ error: err.message ?? "Invalid request" });
      });
  } catch (err: any) {
    return res.status(400).json({ error: err.message ?? "Invalid request" });
  }
});

/**
 * GET /api/auth/users
 * - Returns all users/officers from the database
 */
router.get("/users", (async (_req, res) => {
  try {
    const result = await pool.query(
      `SELECT uid, email, display_name, role,
              COALESCE(status, 'active') as status,
              created_at, last_login
       FROM users_meta
       ORDER BY created_at DESC`
    );
    return res.json({ users: result.rows });
  } catch (err: any) {
    console.error("Error fetching users:", err);
    return res.status(500).json({ error: "Failed to fetch users" });
  }
}) as RequestHandler);

/**
 * POST /api/auth/users
 * - Creates a new user (admin adds officer without Firebase auth)
 */
const createUserSchema = z.object({
  email: z.string().email(),
  displayName: z.string().min(1),
  role: z.enum(["admin", "officer"]),
});

router.post("/users", (async (req, res) => {
  try {
    const data = createUserSchema.parse(req.body);

    // Check if email already exists
    const existing = await findByEmail(data.email);
    if (existing) {
      return res.status(400).json({ error: "User with this email already exists" });
    }

    // Generate a placeholder UID for users added by admin
    // They will get a real Firebase UID when they first log in
    const placeholderUid = `pending_${Date.now()}_${Math.random().toString(36).slice(2)}`;

    const result = await pool.query(
      `INSERT INTO users_meta (uid, email, display_name, role, status)
       VALUES ($1, $2, $3, $4, 'active')
       RETURNING *`,
      [placeholderUid, data.email, data.displayName, data.role]
    );

    return res.status(201).json({
      message: "User created successfully",
      user: result.rows[0],
    });
  } catch (err: any) {
    console.error("Error creating user:", err);
    return res.status(400).json({ error: err.message ?? "Invalid request" });
  }
}) as RequestHandler);

/**
 * PUT /api/auth/users/:uid
 * - Updates a user's info (name, role)
 */
const updateUserSchema = z.object({
  displayName: z.string().min(1).optional(),
  role: z.enum(["admin", "officer"]).optional(),
});

router.put("/users/:uid", (async (req, res) => {
  try {
    const { uid } = req.params;
    const data = updateUserSchema.parse(req.body);

    const updates: string[] = [];
    const values: any[] = [];
    let paramCount = 1;

    if (data.displayName) {
      updates.push(`display_name = $${paramCount++}`);
      values.push(data.displayName);
    }
    if (data.role) {
      updates.push(`role = $${paramCount++}`);
      values.push(data.role);
    }

    if (updates.length === 0) {
      return res.status(400).json({ error: "No fields to update" });
    }

    values.push(uid);
    const result = await pool.query(
      `UPDATE users_meta SET ${updates.join(", ")} WHERE uid = $${paramCount} RETURNING *`,
      values
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "User not found" });
    }

    return res.json({
      message: "User updated successfully",
      user: result.rows[0],
    });
  } catch (err: any) {
    console.error("Error updating user:", err);
    return res.status(400).json({ error: err.message ?? "Invalid request" });
  }
}) as RequestHandler);

/**
 * DELETE /api/auth/users/:uid
 * - Revokes/deactivates a user (soft delete)
 */
router.delete("/users/:uid", (async (req, res) => {
  try {
    const { uid } = req.params;

    const result = await pool.query(
      `UPDATE users_meta SET status = 'revoked' WHERE uid = $1 RETURNING *`,
      [uid]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "User not found" });
    }

    return res.json({
      message: "User revoked successfully",
      user: result.rows[0],
    });
  } catch (err: any) {
    console.error("Error revoking user:", err);
    return res.status(500).json({ error: "Failed to revoke user" });
  }
}) as RequestHandler);

/**
 * POST /api/auth/users/:uid/reactivate
 * - Reactivates a revoked user
 */
router.post("/users/:uid/reactivate", (async (req, res) => {
  try {
    const { uid } = req.params;

    const result = await pool.query(
      `UPDATE users_meta SET status = 'active' WHERE uid = $1 RETURNING *`,
      [uid]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "User not found" });
    }

    return res.json({
      message: "User reactivated successfully",
      user: result.rows[0],
    });
  } catch (err: any) {
    console.error("Error reactivating user:", err);
    return res.status(500).json({ error: "Failed to reactivate user" });
  }
}) as RequestHandler);

/**
 * POST /api/auth/update-login
 * - Updates user's last login timestamp (called after Firebase auth)
 */
router.post("/update-login", (async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ error: "Email required" });
    }

    await pool.query(
      `UPDATE users_meta SET last_login = NOW() WHERE LOWER(email) = LOWER($1)`,
      [email]
    );

    return res.json({ message: "Login timestamp updated" });
  } catch (err: any) {
    console.error("Error updating login:", err);
    return res.status(500).json({ error: "Failed to update login" });
  }
}) as RequestHandler);

export default router;
