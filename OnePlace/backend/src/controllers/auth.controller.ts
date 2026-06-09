import type { Request, Response, NextFunction } from "express";
import * as authService from "../services/auth.service.js";
import { NODE_ENV } from "../config/env.js";

const COOKIE_NAME = "token";
const COOKIE_OPTIONS = {
  httpOnly: true,
  secure: NODE_ENV === "production",
  sameSite: (NODE_ENV === "production" ? "none" : "strict") as "none" | "strict",
  maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days
};

// POST /api/v1/auth/sign-up
export async function signUp(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const user = await authService.register(req.body as { firstname: string; lastname: string; email: string; password: string });
    res.status(201).json({
      success: true,
      message: "Account created. Please check your email to verify your account.",
      data: { user },
    });
  } catch (err) {
    next(err);
  }
}

// POST /api/v1/auth/sign-in
export async function signIn(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const { user, token } = await authService.login(req.body as { email: string; password: string });
    res.cookie(COOKIE_NAME, token, COOKIE_OPTIONS);
    res.status(200).json({
      success: true,
      message: "Logged in successfully.",
      data: { user },
    });
  } catch (err) {
    next(err);
  }
}

// POST /api/v1/auth/sign-out
export async function signOut(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    res.clearCookie(COOKIE_NAME, COOKIE_OPTIONS);
    res.status(200).json({ success: true, message: "Logged out successfully." });
  } catch (err) {
    next(err);
  }
}

// POST /api/v1/auth/verify-email
export async function verifyEmail(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const { token } = req.body as { token: string };
    await authService.verifyEmail(token);
    res.status(200).json({ success: true, message: "Email verified successfully." });
  } catch (err) {
    next(err);
  }
}

// POST /api/v1/auth/forgot-password
export async function forgotPassword(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const { email } = req.body as { email: string };
    await authService.forgotPassword(email);
    res.status(200).json({
      success: true,
      message: "If an account with that email exists, a password reset link has been sent.",
    });
  } catch (err) {
    next(err);
  }
}

// POST /api/v1/auth/reset-password
export async function resetPassword(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const { token, newPassword } = req.body as { token: string; newPassword: string };
    await authService.resetPassword(token, newPassword);
    res.status(200).json({ success: true, message: "Password reset successfully." });
  } catch (err) {
    next(err);
  }
}
