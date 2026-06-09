import https from "https";
import http from "http";
import fs from "fs";
import path from "path";
import os from "os";
import { YoutubeTranscript } from "youtube-transcript";
import Groq from "groq-sdk";
import { GROQ_API_KEY } from "../config/env.js";

const groq = new Groq({ apiKey: GROQ_API_KEY });

// ─── URL detection ────────────────────────────────────────────────────────────

function extractYouTubeId(url: string): string | null {
  const patterns = [
    /(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})/,
    /youtube\.com\/shorts\/([a-zA-Z0-9_-]{11})/,
  ];
  for (const p of patterns) {
    const m = url.match(p);
    if (m) return m[1]!;
  }
  return null;
}

function isDirectVideoUrl(url: string): boolean {
  return /\.(mp4|mp3|m4a|wav|webm|ogg|mpeg|mpga)(\?|$)/i.test(url);
}

// ─── YouTube: fetch captions (no download needed) ─────────────────────────────

async function transcribeYouTube(videoId: string): Promise<string> {
  const segments = await YoutubeTranscript.fetchTranscript(videoId);
  return segments.map((s) => s.text).join(" ").replace(/\s+/g, " ").trim();
}

// ─── Direct video: download audio + Groq Whisper ─────────────────────────────

const MAX_BYTES = 20 * 1024 * 1024; // 20 MB

function downloadPartial(url: string, destPath: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const protocol = url.startsWith("https") ? https : http;
    const file = fs.createWriteStream(destPath);
    let downloaded = 0;

    protocol.get(url, (res) => {
      res.on("data", (chunk: Buffer) => {
        downloaded += chunk.length;
        file.write(chunk);
        if (downloaded >= MAX_BYTES) {
          res.destroy();
          file.end();
        }
      });
      res.on("end", () => { file.end(); resolve(); });
      res.on("error", reject);
    }).on("error", reject);

    file.on("finish", resolve);
    file.on("error", reject);
  });
}

async function transcribeDirectVideo(url: string): Promise<string> {
  const ext = (url.match(/\.(mp4|mp3|m4a|wav|webm|ogg)(\?|$)/i)?.[1] ?? "mp4").toLowerCase();
  const tmpPath = path.join(os.tmpdir(), `lesson-${Date.now()}.${ext}`);

  try {
    await downloadPartial(url, tmpPath);
    const result = await groq.audio.transcriptions.create({
      file: fs.createReadStream(tmpPath),
      model: "whisper-large-v3-turbo",
      response_format: "text",
    });
    return typeof result === "string" ? result : (result as any).text ?? "";
  } finally {
    fs.unlink(tmpPath, () => {});
  }
}

// ─── Main export ──────────────────────────────────────────────────────────────

export type TranscriptResult = {
  transcript: string;
  source: "youtube_captions" | "whisper" | "none";
};

export async function getVideoTranscript(videoUrl: string): Promise<TranscriptResult> {
  // YouTube
  const youtubeId = extractYouTubeId(videoUrl);
  if (youtubeId) {
    try {
      const transcript = await transcribeYouTube(youtubeId);
      if (transcript.length > 50) {
        return { transcript, source: "youtube_captions" };
      }
    } catch (err) {
      console.warn("[Transcription] YouTube captions failed:", (err as Error).message);
    }
  }

  // Direct video file
  if (isDirectVideoUrl(videoUrl)) {
    try {
      const transcript = await transcribeDirectVideo(videoUrl);
      return { transcript, source: "whisper" };
    } catch (err) {
      console.warn("[Transcription] Whisper transcription failed:", (err as Error).message);
    }
  }

  // Loom / Vimeo / HLS / unsupported
  return { transcript: "", source: "none" };
}
