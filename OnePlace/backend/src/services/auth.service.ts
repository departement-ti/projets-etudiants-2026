import bcrypt from "bcryptjs";
import { prisma } from "../database/db.js";
import { AppError } from "../utils/AppError.js";
import { generateJwt, generateRandomToken } from "../utils/token.utils.js";
import { sendVerificationEmail, sendPasswordResetEmail, sendWelcomeEmail } from "../utils/email.utils.js";
import type { RegisterInput, LoginInput, SafeUser, JwtPayload } from "../types/auth.types.js";

const BCRYPT_ROUNDS = 12;
const VERIFICATION_TOKEN_TTL_MS = 24 * 60 * 60 * 1000; // 24 hours
const RESET_TOKEN_TTL_MS = 60 * 60 * 1000; // 1 hour

function sanitizeUser(user: {
  id: string;
  firstname: string;
  lastname: string;
  email: string;
  role: SafeUser["role"];
  isVerified: boolean;
  lastLogin: Date | null;
  createdAt: Date;
}): SafeUser {
  return {
    id: user.id,
    firstname: user.firstname,
    lastname: user.lastname,
    email: user.email,
    role: user.role,
    isVerified: user.isVerified,
    lastLogin: user.lastLogin,
    createdAt: user.createdAt,
  };
}

// ─── Register ────────────────────────────────────────────────────────────────

export async function register(input: RegisterInput): Promise<SafeUser> {
  const { firstname, lastname, email, password } = input;

  if (!firstname || !lastname || !email || !password) {
    throw new AppError("firstname, lastname, email and password are required", 400);
  }

  if (password.length < 8) {
    throw new AppError("Password must be at least 8 characters", 400);
  }
  if (!/[A-Z]/.test(password)) {
    throw new AppError("Password must contain at least one uppercase letter", 400);
  }
  if (!/[0-9]/.test(password)) {
    throw new AppError("Password must contain at least one number", 400);
  }
  if (!/[^A-Za-z0-9]/.test(password)) {
    throw new AppError("Password must contain at least one special character", 400);
  }

  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) {
    throw new AppError("An account with this email already exists", 409);
  }

  const hashedPassword = await bcrypt.hash(password, BCRYPT_ROUNDS);
  const verificationToken = generateRandomToken();
  const verificationTokenExpiresAt = new Date(Date.now() + VERIFICATION_TOKEN_TTL_MS);

  const user = await prisma.user.create({
    data: {
      firstname,
      lastname,
      email,
      password: hashedPassword,
      verificationToken,
      verificationTokenExpiresAt,
    },
  });

  await sendVerificationEmail(email, verificationToken);

  return sanitizeUser(user);
}

// ─── Login ───────────────────────────────────────────────────────────────────

export async function login(input: LoginInput): Promise<{ user: SafeUser; token: string }> {
  const { email, password } = input;

  if (!email || !password) {
    throw new AppError("email and password are required", 400);
  }

  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) {
    throw new AppError("Invalid email or password", 401);
  }

  const passwordMatches = await bcrypt.compare(password, user.password);
  if (!passwordMatches) {
    throw new AppError("Invalid email or password", 401);
  }

  if (!user.isVerified) {
    throw new AppError("Please verify your email before logging in", 403);
  }

  const payload: JwtPayload = { userId: user.id, role: user.role };
  const token = generateJwt(payload);

  await prisma.user.update({
    where: { id: user.id },
    data: { lastLogin: new Date() },
  });

  return { user: sanitizeUser(user), token };
}

// ─── Verify Email ─────────────────────────────────────────────────────────────

export async function verifyEmail(token: string): Promise<void> {
  if (!token) {
    throw new AppError("Verification token is required", 400);
  }

  const user = await prisma.user.findFirst({
    where: {
      verificationToken: token,
      verificationTokenExpiresAt: { gt: new Date() },
    },
  });

  if (!user) {
    throw new AppError("Invalid or expired verification token", 400);
  }

  await prisma.user.update({
    where: { id: user.id },
    data: {
      isVerified: true,
      verificationToken: null,
      verificationTokenExpiresAt: null,
    },
  });

  await sendWelcomeEmail(user.email, user.firstname);
}

// ─── Forgot Password ─────────────────────────────────────────────────────────

export async function forgotPassword(email: string): Promise<void> {
  if (!email) {
    throw new AppError("email is required", 400);
  }

  const user = await prisma.user.findUnique({ where: { email } });

  // Always return success to avoid leaking whether an email exists
  if (!user) return;

  const resetToken = generateRandomToken();
  const resetPasswordExpiresAt = new Date(Date.now() + RESET_TOKEN_TTL_MS);

  await prisma.user.update({
    where: { id: user.id },
    data: { resetPasswordToken: resetToken, resetPasswordExpiresAt },
  });

  await sendPasswordResetEmail(email, resetToken);
}

// ─── Reset Password ───────────────────────────────────────────────────────────

export async function resetPassword(token: string, newPassword: string): Promise<void> {
  if (!token || !newPassword) {
    throw new AppError("token and newPassword are required", 400);
  }

  if (newPassword.length < 8) {
    throw new AppError("Password must be at least 8 characters", 400);
  }

  const user = await prisma.user.findFirst({
    where: {
      resetPasswordToken: token,
      resetPasswordExpiresAt: { gt: new Date() },
    },
  });

  if (!user) {
    throw new AppError("Invalid or expired password reset token", 400);
  }

  const hashedPassword = await bcrypt.hash(newPassword, BCRYPT_ROUNDS);

  await prisma.user.update({
    where: { id: user.id },
    data: {
      password: hashedPassword,
      resetPasswordToken: null,
      resetPasswordExpiresAt: null,
    },
  });
}
