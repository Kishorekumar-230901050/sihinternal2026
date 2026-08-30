import { Request, Response } from "express";
import bcrypt from "bcryptjs";
import { z } from "zod";
import { prisma } from "../db";
import { signToken } from "../middlewares/auth";

const SALT_ROUNDS = 10;

const vendorRegisterSchema = z.object({
  fullName: z.string().min(2),
  email: z.string().email(),
  phone: z.string().min(8),
  password: z.string().min(8),
  businessName: z.string().optional(),
  addressLine: z.string().optional(),
  city: z.string().optional(),
  state: z.string().optional(),
  pincode: z.string().optional(),
});

export async function registerVendor(req: Request, res: Response) {
  const parsed = vendorRegisterSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });

  const { password, ...rest } = parsed.data;
  const existing = await prisma.user.findFirst({
    where: { OR: [{ email: rest.email }, { phone: rest.phone }] },
  });
  if (existing) return res.status(409).json({ error: "Email or phone already registered" });

  const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);
  const user = await prisma.user.create({
    data: { ...rest, passwordHash, role: "VENDOR" },
  });

  const token = signToken({ sub: user.id, role: "VENDOR", email: user.email });
  res.status(201).json({ token, user: sanitizeUser(user) });
}

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

export async function loginVendor(req: Request, res: Response) {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });

  const user = await prisma.user.findUnique({ where: { email: parsed.data.email } });
  if (!user || !(await bcrypt.compare(parsed.data.password, user.passwordHash))) {
    return res.status(401).json({ error: "Invalid credentials" });
  }

  const token = signToken({ sub: user.id, role: "VENDOR", email: user.email });
  res.json({ token, user: sanitizeUser(user) });
}

export async function loginLmo(req: Request, res: Response) {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });

  const lmo = await prisma.lMO.findUnique({ where: { email: parsed.data.email } });
  if (!lmo || !(await bcrypt.compare(parsed.data.password, lmo.passwordHash))) {
    return res.status(401).json({ error: "Invalid credentials" });
  }

  const token = signToken({ sub: lmo.id, role: "LMO", email: lmo.email });
  res.json({ token, lmo: { id: lmo.id, fullName: lmo.fullName, email: lmo.email, employeeCode: lmo.employeeCode } });
}

export async function loginAdmin(req: Request, res: Response) {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });

  const admin = await prisma.admin.findUnique({ where: { email: parsed.data.email } });
  if (!admin || !(await bcrypt.compare(parsed.data.password, admin.passwordHash))) {
    return res.status(401).json({ error: "Invalid credentials" });
  }

  const token = signToken({ sub: admin.id, role: "ADMIN", email: admin.email });
  res.json({ token, admin: { id: admin.id, fullName: admin.fullName, email: admin.email } });
}

function sanitizeUser(user: { passwordHash: string; [k: string]: unknown }) {
  const { passwordHash, ...rest } = user;
  return rest;
}
