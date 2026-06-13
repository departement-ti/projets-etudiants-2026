import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { Role } from '@prisma/client';
import * as bcrypt from 'bcrypt';

@Injectable()
export class UserService {
  constructor(
    private prisma: PrismaService,
    private audit: AuditService,
  ) {}

  private safeUserSelect = {
    id: true,
    email: true,
    firstName: true,
    lastName: true,
    phone: true,
    role: true,
    organizationId: true,
    createdAt: true,
    updatedAt: true,
    organization: {
      select: {
        id: true,
        name: true,
        slug: true,
        isActive: true,
      },
    },
    tenant: {
      select: {
        id: true,
        nationalId: true,
        riskScore: true,
        createdAt: true,
      },
    },
  };

  private allowedRoles = ['OWNER', 'AGENT', 'ASSISTANT', 'TENANT', 'ADMIN'];

  private async validateOrganizationForRole(
    role: string,
    organizationId?: string | null,
  ) {
    if (role === 'ADMIN') {
      if (!organizationId) return null;

      const organization = await this.prisma.organization.findUnique({
        where: {
          id: organizationId,
        },
      });

      if (!organization) {
        throw new NotFoundException('Organization not found');
      }

      if (!organization.isActive) {
        throw new BadRequestException('Organization is inactive');
      }

      return organization.id;
    }

    if (!organizationId) {
      throw new BadRequestException(
        'Organization is required for OWNER, AGENT, ASSISTANT and TENANT users',
      );
    }

    const organization = await this.prisma.organization.findUnique({
      where: {
        id: organizationId,
      },
    });

    if (!organization) {
      throw new NotFoundException('Organization not found');
    }

    if (!organization.isActive) {
      throw new BadRequestException('Organization is inactive');
    }

    return organization.id;
  }

  private async safeAudit(input: {
    actor?: any;
    action: string;
    resource?: string;
    resourceId?: string;
    before?: unknown;
    after?: unknown;
    metadata?: unknown;
    organizationId?: string | null;
  }) {
    try {
      await this.audit.log(input);
    } catch (e) {
      console.error('Audit log failed:', e);
    }
  }

  async create(
    actor: any,
    data: {
      email?: string;
      password?: string;
      firstName?: string;
      lastName?: string;
      phone?: string;
      role?: string;
      organizationId?: string | null;
    },
  ) {
    const email = data.email?.toString().trim().toLowerCase() ?? '';
    const password = data.password?.toString() ?? '';
    const role = data.role?.toString() ?? 'TENANT';

    if (!email) {
      throw new BadRequestException('Email is required');
    }

    if (!password || password.length < 6) {
      throw new BadRequestException('Password must be at least 6 characters');
    }

    if (!this.allowedRoles.includes(role)) {
      throw new BadRequestException('Invalid role');
    }

    const existing = await this.prisma.user.findUnique({
      where: {
        email,
      },
    });

    if (existing) {
      throw new BadRequestException('Email already exists');
    }

    // IMPORTANT:
    // Do NOT fallback to actor.organizationId.
    // In a multi-organization system, ADMIN must explicitly choose the organization.
    const organizationId = await this.validateOrganizationForRole(
      role,
      data.organizationId ?? null,
    );

    const passwordHash = await bcrypt.hash(password, 10);

    const created = await this.prisma.user.create({
      data: {
        email,
        passwordHash,
        firstName:
          typeof data.firstName === 'string'
            ? data.firstName.trim() || null
            : null,
        lastName:
          typeof data.lastName === 'string'
            ? data.lastName.trim() || null
            : null,
        phone:
          typeof data.phone === 'string' ? data.phone.trim() || null : null,
        role: Role[role as keyof typeof Role],
        organizationId,
      },
      select: this.safeUserSelect,
    });

    await this.safeAudit({
      actor,
      action: 'USER_CREATED',
      resource: 'User',
      resourceId: created.id,
      after: created,
      organizationId: created.organizationId,
      metadata: {
        email: created.email,
        role: created.role,
        createdById: actor?.id,
        createdByEmail: actor?.email,
      },
    });

    return created;
  }

  async findAll() {
    return this.prisma.user.findMany({
      select: this.safeUserSelect,
      orderBy: {
        createdAt: 'desc',
      },
    });
  }

  async findOne(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: this.safeUserSelect,
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  async update(id: string, data: any, actor?: any) {
    const before = await this.findOne(id);

    const updated = await this.prisma.user.update({
      where: { id },
      data: {
        firstName:
          typeof data.firstName === 'string'
            ? data.firstName.trim() || null
            : undefined,
        lastName:
          typeof data.lastName === 'string'
            ? data.lastName.trim() || null
            : undefined,
        phone:
          typeof data.phone === 'string' ? data.phone.trim() || null : undefined,
      },
      select: this.safeUserSelect,
    });

    await this.safeAudit({
      actor,
      action: 'USER_UPDATED',
      resource: 'User',
      resourceId: id,
      before,
      after: updated,
      organizationId: updated.organizationId,
      metadata: {
        email: updated.email,
        changedFields: {
          firstName: before.firstName !== updated.firstName,
          lastName: before.lastName !== updated.lastName,
          phone: before.phone !== updated.phone,
        },
      },
    });

    return updated;
  }

  async updateMe(userId: string, data: any, actor?: any) {
    const before = await this.findOne(userId);

    const updated = await this.prisma.user.update({
      where: {
        id: userId,
      },
      data: {
        firstName:
          typeof data.firstName === 'string'
            ? data.firstName.trim() || null
            : undefined,
        lastName:
          typeof data.lastName === 'string'
            ? data.lastName.trim() || null
            : undefined,
        phone:
          typeof data.phone === 'string' ? data.phone.trim() || null : undefined,
      },
      select: this.safeUserSelect,
    });

    await this.safeAudit({
      actor,
      action: 'USER_PROFILE_UPDATED',
      resource: 'User',
      resourceId: userId,
      before,
      after: updated,
      organizationId: updated.organizationId,
      metadata: {
        email: updated.email,
        changedFields: {
          firstName: before.firstName !== updated.firstName,
          lastName: before.lastName !== updated.lastName,
          phone: before.phone !== updated.phone,
        },
      },
    });

    return updated;
  }

  async delete(id: string, currentUserId: string, actor?: any) {
    if (id === currentUserId) {
      throw new BadRequestException('You cannot delete your own account');
    }

    const before = await this.findOne(id);

    const deleted = await this.prisma.user.delete({
      where: { id },
      select: this.safeUserSelect,
    });

    await this.safeAudit({
      actor,
      action: 'USER_DELETED',
      resource: 'User',
      resourceId: id,
      before,
      after: deleted,
      organizationId: before.organizationId,
      metadata: {
        email: before.email,
        role: before.role,
      },
    });

    return deleted;
  }

  async profile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        phone: true,
        role: true,
        organizationId: true,
        createdAt: true,
        updatedAt: true,
        organization: {
          select: {
            id: true,
            name: true,
            slug: true,
            isActive: true,
          },
        },
        tenant: {
          select: {
            id: true,
            nationalId: true,
            guarantor: true,
            riskScore: true,
            createdAt: true,
            leases: {
              include: {
                unit: {
                  include: {
                    property: true,
                  },
                },
                invoices: true,
              },
              orderBy: {
                createdAt: 'desc',
              },
            },
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('User profile not found');
    }

    return user;
  }

  async changeRole(userId: string, role: string, actor?: any) {
    if (!this.allowedRoles.includes(role)) {
      throw new ForbiddenException('Invalid role');
    }

    const before = await this.findOne(userId);

    if (role !== 'ADMIN' && !before.organizationId) {
      throw new BadRequestException(
        'This user must be assigned to an organization before changing to a non-admin role',
      );
    }

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: {
        role: Role[role as keyof typeof Role],
      },
      select: this.safeUserSelect,
    });

    await this.safeAudit({
      actor,
      action: 'USER_ROLE_CHANGED',
      resource: 'User',
      resourceId: userId,
      before: {
        role: before.role,
      },
      after: {
        role: updated.role,
      },
      organizationId: updated.organizationId,
      metadata: {
        email: updated.email,
        previousRole: before.role,
        newRole: updated.role,
      },
    });

    return updated;
  }

  async findAgentsByOrganization(orgId: string) {
    return this.prisma.user.findMany({
      where: {
        organizationId: orgId,
        role: {
          in: [Role.AGENT],
        },
      },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        role: true,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
  }

  async changeMyPassword(
    userId: string,
    data: {
      currentPassword?: string;
      newPassword?: string;
    },
    actor?: any,
  ) {
    const currentPassword = data.currentPassword?.toString() ?? '';
    const newPassword = data.newPassword?.toString() ?? '';

    if (!currentPassword || !newPassword) {
      throw new BadRequestException(
        'Current password and new password are required',
      );
    }

    if (newPassword.length < 6) {
      throw new BadRequestException(
        'New password must be at least 6 characters',
      );
    }

    const user = await this.prisma.user.findUnique({
      where: {
        id: userId,
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const validPassword = await bcrypt.compare(
      currentPassword,
      user.passwordHash,
    );

    if (!validPassword) {
      throw new UnauthorizedException('Current password is incorrect');
    }

    const samePassword = await bcrypt.compare(newPassword, user.passwordHash);

    if (samePassword) {
      throw new BadRequestException(
        'New password must be different from current password',
      );
    }

    const newPasswordHash = await bcrypt.hash(newPassword, 10);

    await this.prisma.user.update({
      where: {
        id: userId,
      },
      data: {
        passwordHash: newPasswordHash,
      },
    });

    await this.safeAudit({
      actor,
      action: 'USER_PASSWORD_CHANGED',
      resource: 'User',
      resourceId: userId,
      organizationId: user.organizationId,
      metadata: {
        email: user.email,
      },
    });

    return {
      message: 'Password changed successfully',
    };
  }
}