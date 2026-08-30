import "dotenv/config";
import bcrypt from "bcryptjs";
import { prisma } from "../src/db";

const SALT_ROUNDS = 10;

async function main() {
  console.log("Seeding CALIBRIS database...");

  // --- Instrument Types (the 5 required types) ---------------------------
  const instrumentTypeDefs = [
    {
      name: "Weighing Scale",
      code: "WEIGHING_SCALE",
      category: "Weighing",
      description: "Commercial weighing scales up to 300kg",
      feeInPaise: 30000,
      validityMonths: 12,
    },
    {
      name: "Weighbridge",
      code: "WEIGHBRIDGE",
      category: "Weighing",
      description: "Heavy vehicle weighbridge installations",
      feeInPaise: 500000,
      validityMonths: 12,
    },
    {
      name: "Platform Scale",
      code: "PLATFORM_SCALE",
      category: "Weighing",
      description: "Industrial platform scales",
      feeInPaise: 40000,
      validityMonths: 12,
    },
    {
      name: "Fuel Dispenser",
      code: "FUEL_DISPENSER",
      category: "Measuring",
      description: "Petrol/diesel dispensing units",
      feeInPaise: 150000,
      validityMonths: 6,
    },
    {
      name: "Water Meter",
      code: "WATER_METER",
      category: "Measuring",
      description: "Domestic and commercial water meters",
      feeInPaise: 20000,
      validityMonths: 12,
    },
  ];

  const instrumentTypes = await Promise.all(
    instrumentTypeDefs.map((def) =>
      prisma.instrumentType.upsert({
        where: { name: def.name },
        update: {},
        create: def,
      })
    )
  );
  console.log(`  ✓ ${instrumentTypes.length} instrument types`);

  // --- Department & Location ---------------------------------------------
  const department = await prisma.department.upsert({
    where: { name: "Chennai Metropolitan Legal Metrology" },
    update: {},
    create: { name: "Chennai Metropolitan Legal Metrology" },
  });

  const location = await prisma.location.upsert({
    where: { id: "seed-location-chennai" },
    update: {},
    create: {
      id: "seed-location-chennai",
      name: "Chennai Central",
      district: "Chennai",
      state: "Tamil Nadu",
      pincode: "600001",
      departmentId: department.id,
    },
  });
  console.log("  ✓ department & location");

  // --- GATC ----------------------------------------------------------------
  const gatc = await prisma.gATC.upsert({
    where: { id: "seed-gatc-chennai-central" },
    update: {},
    create: {
      id: "seed-gatc-chennai-central",
      name: "Chennai Central GATC",
      addressLine: "123 Mount Road, Chennai",
      latitude: 13.0827,
      longitude: 80.2707,
      locationId: location.id,
      contactPhone: "+914412345678",
      instrumentTypes: {
        create: instrumentTypes.map((it) => ({ instrumentTypeId: it.id, dailyCapacity: 15 })),
      },
    },
  });
  console.log("  ✓ GATC: Chennai Central GATC");

  // --- Mock users ------------------------------------------------------------
  const vendorPasswordHash = await bcrypt.hash("Vendor@123", SALT_ROUNDS);
  const vendor = await prisma.user.upsert({
    where: { email: "vendor@example.com" },
    update: {},
    create: {
      role: "VENDOR",
      fullName: "Ravi Kumar",
      email: "vendor@example.com",
      phone: "+919000000001",
      passwordHash: vendorPasswordHash,
      businessName: "Kumar Traders",
      city: "Chennai",
      state: "Tamil Nadu",
      pincode: "600001",
    },
  });

  const lmoPasswordHash = await bcrypt.hash("Lmo@12345", SALT_ROUNDS);
  const lmo = await prisma.lMO.upsert({
    where: { email: "lmo@example.com" },
    update: {},
    create: {
      fullName: "Priya Sundaram",
      email: "lmo@example.com",
      phone: "+919000000002",
      passwordHash: lmoPasswordHash,
      employeeCode: "LMO-CHN-001",
      departmentId: department.id,
      locations: { create: { locationId: location.id } },
    },
  });

  const adminPasswordHash = await bcrypt.hash("Admin@12345", SALT_ROUNDS);
  const admin = await prisma.admin.upsert({
    where: { email: "admin@example.com" },
    update: {},
    create: {
      fullName: "System Administrator",
      email: "admin@example.com",
      passwordHash: adminPasswordHash,
    },
  });

  console.log("  ✓ mock users: vendor@example.com / lmo@example.com / admin@example.com");
  console.log("\nSeed complete. Credentials:");
  console.log("  Vendor : vendor@example.com / Vendor@123");
  console.log("  LMO    : lmo@example.com / Lmo@12345");
  console.log("  Admin  : admin@example.com / Admin@12345");

  void gatc;
  void vendor;
  void lmo;
  void admin;
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
