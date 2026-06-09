import { config } from "dotenv";

const nodeEnv = process.env.NODE_ENV ?? "development";

// Load base .env first, then override with environment-specific file.
config({ path: ".env" });
config({ path: `.env.${nodeEnv}.local`, override: true });

export const PORT = process.env.PORT ?? "5000";
export const NODE_ENV = nodeEnv;
export const DATABASE_URL = process.env.DATABASE_URL;

// JWT
if (nodeEnv === "production" && !process.env.JWT_SECRET) {
  throw new Error('Missing JWT_SECRET. Set it in your production environment.');
}
export const JWT_SECRET = process.env.JWT_SECRET ?? "dev-secret-change-in-production";
export const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN ?? "7d";

// Email
export const EMAIL_HOST = process.env.EMAIL_HOST ?? "";
export const EMAIL_PORT = Number(process.env.EMAIL_PORT ?? "587");
export const EMAIL_USER = process.env.EMAIL_USER ?? "";
export const EMAIL_PASS = process.env.EMAIL_PASS ?? "";
export const EMAIL_FROM = process.env.EMAIL_FROM ?? "noreply@oneplace.app";

// Client URL (for email links)
export const CLIENT_URL = process.env.CLIENT_URL ?? "http://localhost:3000";

// S3 / Cloudflare R2 (file uploads)
// R2 is S3-compatible — set S3_REGION to "auto" and point S3_ENDPOINT to your R2 endpoint.
export const S3_REGION = process.env.S3_REGION ?? "";
export const S3_BUCKET = process.env.S3_BUCKET ?? "";
export const S3_ACCESS_KEY_ID = process.env.S3_ACCESS_KEY_ID ?? "";
export const S3_SECRET_ACCESS_KEY = process.env.S3_SECRET_ACCESS_KEY ?? "";
export const S3_ENDPOINT = process.env.S3_ENDPOINT ?? ""; // Required for Cloudflare R2
export const S3_CDN_URL = process.env.S3_CDN_URL ?? "";

// Groq AI
export const GROQ_API_KEY = process.env.GROQ_API_KEY ?? "";

// HuggingFace (for embeddings — free tier works without a token, but a free
// HF token removes rate limits: https://huggingface.co/settings/tokens)
export const HF_API_KEY = process.env.HF_API_KEY ?? "";