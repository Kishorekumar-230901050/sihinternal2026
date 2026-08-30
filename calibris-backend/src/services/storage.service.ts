import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";

/**
 * Storage abstraction: uploads to Supabase Storage when
 * SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY are present, otherwise falls
 * back to writing under /uploads on local disk and serving it statically
 * (see src/index.ts express.static mount).
 */

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const SUPABASE_BUCKET = process.env.SUPABASE_STORAGE_BUCKET || "calibris-uploads";
const PORT = process.env.PORT || "3000";

const LOCAL_UPLOAD_DIR = path.join(process.cwd(), "uploads");

export const isSupabaseConfigured = Boolean(SUPABASE_URL && SUPABASE_SERVICE_ROLE_KEY);

function ensureLocalDir() {
  if (!fs.existsSync(LOCAL_UPLOAD_DIR)) {
    fs.mkdirSync(LOCAL_UPLOAD_DIR, { recursive: true });
  }
}

function randomFilename(originalName: string): string {
  const ext = path.extname(originalName);
  return `${Date.now()}-${crypto.randomBytes(8).toString("hex")}${ext}`;
}

export async function uploadFile(
  buffer: Buffer,
  originalName: string,
  mimeType: string
): Promise<{ url: string }> {
  const filename = randomFilename(originalName);

  if (isSupabaseConfigured) {
    const res = await fetch(
      `${SUPABASE_URL}/storage/v1/object/${SUPABASE_BUCKET}/${filename}`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
          "Content-Type": mimeType,
          "x-upsert": "true",
        },
        body: buffer,
      }
    );

    if (!res.ok) {
      const text = await res.text().catch(() => "");
      throw new Error(`Supabase upload failed (${res.status}): ${text}`);
    }

    return { url: `${SUPABASE_URL}/storage/v1/object/public/${SUPABASE_BUCKET}/${filename}` };
  }

  // Local filesystem fallback
  ensureLocalDir();
  const filePath = path.join(LOCAL_UPLOAD_DIR, filename);
  await fs.promises.writeFile(filePath, buffer);
  return { url: `http://localhost:${PORT}/uploads/${filename}` };
}

export { LOCAL_UPLOAD_DIR };
