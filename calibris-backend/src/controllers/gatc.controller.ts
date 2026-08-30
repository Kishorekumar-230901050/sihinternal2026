import { Request, Response } from "express";
import { prisma } from "../db";

function haversineKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) * Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/**
 * Finds GATCs that support a given instrument type. If lat/lng are
 * provided, results are sorted by distance; otherwise falls back to
 * alphabetical order by location district (used when the app's GPS
 * lookup fails and the vendor picks a district manually instead).
 */
export async function findGatcs(req: Request, res: Response) {
  const { instrumentTypeId, lat, lng, district } = req.query as Record<string, string | undefined>;

  const where: Record<string, unknown> = { isActive: true };
  if (instrumentTypeId) {
    where.instrumentTypes = { some: { instrumentTypeId } };
  }
  if (district) {
    where.location = { district: { equals: district, mode: "insensitive" } };
  }

  const gatcs = await prisma.gATC.findMany({
    where,
    include: { location: true, instrumentTypes: { include: { instrumentType: true } } },
  });

  if (lat && lng) {
    const latNum = Number(lat);
    const lngNum = Number(lng);
    const withDistance = gatcs
      .map((g) => ({ ...g, distanceKm: haversineKm(latNum, lngNum, g.latitude, g.longitude) }))
      .sort((a, b) => a.distanceKm - b.distanceKm);
    return res.json(withDistance);
  }

  const sorted = [...gatcs].sort((a, b) => a.location.district.localeCompare(b.location.district));
  res.json(sorted);
}

export async function getGatc(req: Request, res: Response) {
  const gatc = await prisma.gATC.findUnique({
    where: { id: req.params.id },
    include: { location: true, instrumentTypes: { include: { instrumentType: true } } },
  });
  if (!gatc) return res.status(404).json({ error: "GATC not found" });
  res.json(gatc);
}
