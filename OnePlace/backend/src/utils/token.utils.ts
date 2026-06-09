import jwt, { type SignOptions } from "jsonwebtoken";
import crypto from "crypto";
import { JWT_SECRET, JWT_EXPIRES_IN } from "../config/env.js";
import { AppError } from "./AppError.js";
import type { JwtPayload } from "../types/auth.types.js";

export function generateJwt(payload: JwtPayload): string {
  const options: SignOptions = { expiresIn: JWT_EXPIRES_IN as NonNullable<SignOptions["expiresIn"]> };
  return jwt.sign(payload, JWT_SECRET, options);
}

export function verifyJwt(token: string): JwtPayload {
  const decoded = jwt.verify(token, JWT_SECRET);
  if (typeof decoded === "string") {
    throw new AppError("Invalid token", 401);
  }
  return decoded as JwtPayload;
}

/** Generates a cryptographically random hex token */
export function generateRandomToken(bytes = 32): string {
  return crypto.randomBytes(bytes).toString("hex");
}
