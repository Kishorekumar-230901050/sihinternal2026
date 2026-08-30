import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";

export type AuthRole = "VENDOR" | "LMO" | "ADMIN";

export interface AuthPayload {
  sub: string; // user/lmo/admin id
  role: AuthRole;
  email: string;
}

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      auth?: AuthPayload;
    }
  }
}

const JWT_SECRET = process.env.JWT_SECRET;

export function signToken(payload: AuthPayload): string {
  if (!JWT_SECRET) throw new Error("JWT_SECRET is not set");
  const expiresIn = (process.env.JWT_EXPIRES_IN || "7d") as jwt.SignOptions["expiresIn"];
  return jwt.sign(payload, JWT_SECRET, { expiresIn });
}

export function requireAuth(req: Request, res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header?.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Missing bearer token" });
  }
  const token = header.slice("Bearer ".length);
  if (!JWT_SECRET) {
    return res.status(500).json({ error: "Server misconfigured: JWT_SECRET not set" });
  }
  try {
    const decoded = jwt.verify(token, JWT_SECRET) as AuthPayload;
    req.auth = decoded;
    next();
  } catch {
    return res.status(401).json({ error: "Invalid or expired token" });
  }
}

export function requireRole(...roles: AuthRole[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.auth) return res.status(401).json({ error: "Not authenticated" });
    if (!roles.includes(req.auth.role)) {
      return res.status(403).json({ error: "Insufficient permissions" });
    }
    next();
  };
}
