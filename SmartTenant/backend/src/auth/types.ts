// src/auth/types.ts

export interface AuthUser {
  id: string;
  email: string;
  role: string;
  organizationId?: string; // optional if some users might not belong to an organization
}
