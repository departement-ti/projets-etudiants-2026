import type { UserRole } from "@prisma/client";

export interface RegisterInput {
  firstname: string;
  lastname: string;
  email: string;
  password: string;
}

export interface LoginInput {
  email: string;
  password: string;
}

export interface JwtPayload {
  userId: string;
  role: UserRole;
}

export interface SafeUser {
  id: string;
  firstname: string;
  lastname: string;
  email: string;
  role: UserRole;
  isVerified: boolean;
  lastLogin: Date | null;
  createdAt: Date;
}
