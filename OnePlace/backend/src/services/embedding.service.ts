/**
 * Embedding service.
 *
 * Uses the HuggingFace Inference API with sentence-transformers/all-MiniLM-L6-v2
 * to produce 384-dimensional dense vectors for semantic search.
 *
 * Works without an HF token (free, rate-limited to ~10 req/min).
 * Set HF_API_KEY in .env for higher limits (free account required).
 */

import { HF_API_KEY } from "../config/env.js";

const HF_URL =
  "https://api-inference.huggingface.co/models/sentence-transformers/all-MiniLM-L6-v2";

// Max chars sent per embedding — MiniLM supports ~512 tokens ≈ 2000 chars
const MAX_CHARS = 2000;

export async function getEmbedding(text: string): Promise<number[]> {
  const input = text.replace(/\s+/g, " ").trim().slice(0, MAX_CHARS);

  const headers: Record<string, string> = { "Content-Type": "application/json" };
  if (HF_API_KEY) headers["Authorization"] = `Bearer ${HF_API_KEY}`;

  const res = await fetch(HF_URL, {
    method: "POST",
    headers,
    body: JSON.stringify({ inputs: input }),
  });

  // Model is cold — HF tells us how long to wait, then we retry once
  if (res.status === 503) {
    const body = (await res.json()) as { estimated_time?: number };
    const waitMs = Math.ceil((body.estimated_time ?? 20) * 1000);
    console.log(`[embedding] Model loading, retrying in ${waitMs}ms…`);
    await new Promise((r) => setTimeout(r, waitMs));
    return getEmbedding(text);
  }

  if (!res.ok) {
    throw new Error(`HuggingFace embedding error ${res.status}: ${await res.text()}`);
  }

  const data = (await res.json()) as number[][];
  return data[0];
}

// Cosine similarity between two vectors — returns 0 if either is empty
export function cosineSimilarity(a: number[], b: number[]): number {
  if (a.length === 0 || b.length === 0) return 0;
  let dot = 0, normA = 0, normB = 0;
  for (let i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  return normA === 0 || normB === 0 ? 0 : dot / (Math.sqrt(normA) * Math.sqrt(normB));
}

// How long to wait between embedding calls to stay within free-tier limits
// With an HF token: 5/sec is safe. Without: 1 per 7 seconds.
export const EMBED_THROTTLE_MS = HF_API_KEY ? 200 : 7000;
