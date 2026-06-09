import { describe, it, expect, vi, beforeEach } from "vitest";
import { AppError } from "../utils/AppError.js";

// ── bcrypt mock (CJS module — use vi.hoisted so the ref is available in the
//    hoisted vi.mock factory) ─────────────────────────────────────────────────

const bcryptMock = vi.hoisted(() => ({
  hash: vi.fn().mockResolvedValue("hashed_password"),
  compare: vi.fn(),
}));

vi.mock("bcryptjs", () => ({
  default: bcryptMock,
  ...bcryptMock,
}));

// ── Prisma mock ───────────────────────────────────────────────────────────────

vi.mock("../database/db.js", () => ({
  prisma: {
    user: {
      findUnique: vi.fn(),
      findFirst: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
    },
  },
}));

// ── Email mock ────────────────────────────────────────────────────────────────

vi.mock("../utils/email.utils.js", () => ({
  sendVerificationEmail: vi.fn().mockResolvedValue(undefined),
  sendPasswordResetEmail: vi.fn().mockResolvedValue(undefined),
  sendWelcomeEmail: vi.fn().mockResolvedValue(undefined),
}));

// ── Token mock ────────────────────────────────────────────────────────────────

vi.mock("../utils/token.utils.js", async (importOriginal) => {
  const original = await importOriginal<typeof import("../utils/token.utils.js")>();
  return {
    ...original,
    generateRandomToken: vi.fn().mockReturnValue("random_token_abc123"),
    generateJwt: vi.fn().mockReturnValue("jwt_token_xyz"),
  };
});

// ── Import after mocks ────────────────────────────────────────────────────────

import { prisma } from "../database/db.js";
import * as authService from "./auth.service.js";
import { sendPasswordResetEmail } from "../utils/email.utils.js";

// ── Helpers ───────────────────────────────────────────────────────────────────

function makeUser(overrides: Record<string, unknown> = {}) {
  return {
    id: "user-id-1",
    firstname: "Jane",
    lastname: "Doe",
    email: "jane@example.com",
    password: "hashed_password",
    role: "user" as const,
    isVerified: true,
    isSuspended: false,
    lastLogin: null,
    createdAt: new Date("2024-01-01"),
    updatedAt: new Date("2024-01-01"),
    verificationToken: null,
    verificationTokenExpiresAt: null,
    avatarUrl: null,
    resetPasswordToken: null,
    resetPasswordExpiresAt: null,
    ...overrides,
  };
}

// ─── Register ─────────────────────────────────────────────────────────────────

describe("authService.register", () => {
  beforeEach(() => vi.clearAllMocks());

  it("creates a user and returns sanitized data on success", async () => {
    vi.mocked(prisma.user.findUnique).mockResolvedValue(null);
    vi.mocked(prisma.user.create).mockResolvedValue(makeUser({ isVerified: false }));

    const result = await authService.register({
      firstname: "Jane",
      lastname: "Doe",
      email: "jane@example.com",
      password: "securepassword",
    });

    expect(result.email).toBe("jane@example.com");
    expect(result).not.toHaveProperty("password");
  });

  it("throws 409 when email is already registered", async () => {
    vi.mocked(prisma.user.findUnique).mockResolvedValue(makeUser());

    await expect(
      authService.register({
        firstname: "Jane",
        lastname: "Doe",
        email: "jane@example.com",
        password: "securepassword",
      })
    ).rejects.toMatchObject({ statusCode: 409 });
  });

  it("throws 400 when a required field is missing", async () => {
    await expect(
      authService.register({ firstname: "", lastname: "Doe", email: "x@x.com", password: "password123" })
    ).rejects.toMatchObject({ statusCode: 400 });
  });

  it("throws 400 when password is shorter than 8 characters", async () => {
    vi.mocked(prisma.user.findUnique).mockResolvedValue(null);

    await expect(
      authService.register({ firstname: "Jane", lastname: "Doe", email: "x@x.com", password: "short" })
    ).rejects.toMatchObject({ statusCode: 400 });
  });
});

// ─── Login ────────────────────────────────────────────────────────────────────

describe("authService.login", () => {
  beforeEach(() => vi.clearAllMocks());

  it("returns user and token on successful login", async () => {
    vi.mocked(prisma.user.findUnique).mockResolvedValue(makeUser({ isVerified: true }));
    bcryptMock.compare.mockResolvedValueOnce(true);
    vi.mocked(prisma.user.update).mockResolvedValue(makeUser());

    const result = await authService.login({ email: "jane@example.com", password: "securepassword" });

    expect(result.token).toBe("jwt_token_xyz");
    expect(result.user.email).toBe("jane@example.com");
    expect(result.user).not.toHaveProperty("password");
  });

  it("throws 401 on wrong password", async () => {
    vi.mocked(prisma.user.findUnique).mockResolvedValue(makeUser());
    bcryptMock.compare.mockResolvedValueOnce(false);

    await expect(
      authService.login({ email: "jane@example.com", password: "wrongpassword" })
    ).rejects.toMatchObject({ statusCode: 401 });
  });

  it("throws 401 when user does not exist", async () => {
    vi.mocked(prisma.user.findUnique).mockResolvedValue(null);

    await expect(
      authService.login({ email: "nobody@example.com", password: "password" })
    ).rejects.toMatchObject({ statusCode: 401 });
  });

  it("throws 403 when account is not verified", async () => {
    vi.mocked(prisma.user.findUnique).mockResolvedValue(makeUser({ isVerified: false }));
    bcryptMock.compare.mockResolvedValueOnce(true);

    await expect(
      authService.login({ email: "jane@example.com", password: "securepassword" })
    ).rejects.toMatchObject({ statusCode: 403 });
  });
});

// ─── Verify Email ─────────────────────────────────────────────────────────────

describe("authService.verifyEmail", () => {
  beforeEach(() => vi.clearAllMocks());

  it("marks user as verified on a valid token", async () => {
    vi.mocked(prisma.user.findFirst).mockResolvedValue(makeUser({ isVerified: false }));
    vi.mocked(prisma.user.update).mockResolvedValue(makeUser());

    await expect(authService.verifyEmail("valid_token")).resolves.toBeUndefined();
    expect(prisma.user.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ isVerified: true }),
      })
    );
  });

  it("throws 400 on expired or invalid token", async () => {
    vi.mocked(prisma.user.findFirst).mockResolvedValue(null);

    await expect(authService.verifyEmail("bad_token")).rejects.toMatchObject({ statusCode: 400 });
  });

  it("throws 400 when no token is provided", async () => {
    await expect(authService.verifyEmail("")).rejects.toMatchObject({ statusCode: 400 });
  });
});

// ─── Forgot Password ──────────────────────────────────────────────────────────

describe("authService.forgotPassword", () => {
  beforeEach(() => vi.clearAllMocks());

  it("silently succeeds when email does not exist (no info leak)", async () => {
    vi.mocked(prisma.user.findUnique).mockResolvedValue(null);

    await expect(authService.forgotPassword("nobody@example.com")).resolves.toBeUndefined();
    expect(prisma.user.update).not.toHaveBeenCalled();
  });

  it("sets reset token and sends email when user exists", async () => {
    vi.mocked(prisma.user.findUnique).mockResolvedValue(makeUser());
    vi.mocked(prisma.user.update).mockResolvedValue(makeUser());

    await authService.forgotPassword("jane@example.com");

    expect(prisma.user.update).toHaveBeenCalled();
    expect(sendPasswordResetEmail).toHaveBeenCalledWith("jane@example.com", "random_token_abc123");
  });
});

// ─── Reset Password ───────────────────────────────────────────────────────────

describe("authService.resetPassword", () => {
  beforeEach(() => vi.clearAllMocks());

  it("updates password and clears reset token fields on valid token", async () => {
    vi.mocked(prisma.user.findFirst).mockResolvedValue(makeUser());
    vi.mocked(prisma.user.update).mockResolvedValue(makeUser());
    bcryptMock.hash.mockResolvedValueOnce("new_hashed_password");

    await expect(authService.resetPassword("valid_token", "newpassword123")).resolves.toBeUndefined();
    expect(prisma.user.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          resetPasswordToken: null,
          resetPasswordExpiresAt: null,
        }),
      })
    );
  });

  it("throws 400 on expired or invalid token", async () => {
    vi.mocked(prisma.user.findFirst).mockResolvedValue(null);

    await expect(authService.resetPassword("expired_token", "newpassword123")).rejects.toMatchObject({
      statusCode: 400,
    });
  });

  it("throws 400 when new password is too short", async () => {
    await expect(authService.resetPassword("any_token", "short")).rejects.toMatchObject({
      statusCode: 400,
    });
  });
});

// ─── AppError ─────────────────────────────────────────────────────────────────

describe("AppError", () => {
  it("carries the correct statusCode and message", () => {
    const err = new AppError("Not found", 404);
    expect(err.statusCode).toBe(404);
    expect(err.message).toBe("Not found");
    expect(err).toBeInstanceOf(Error);
  });
});
