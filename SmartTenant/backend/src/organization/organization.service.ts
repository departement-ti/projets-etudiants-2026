import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { CreateOrganizationDto } from './dto/create-organization.dto';
import { UpdateOrganizationDto } from './dto/update-organization.dto';
import { Role } from '@prisma/client';

@Injectable()
export class OrganizationService {
  constructor(
    private prisma: PrismaService,
    private audit: AuditService,
  ) {}

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

  async create(dto: CreateOrganizationDto, actor?: any) {
    const name = dto.name?.trim() ?? '';
    const slug = dto.slug?.trim().toLowerCase() ?? '';

    if (!name) {
      throw new BadRequestException('Organization name is required');
    }

    if (!slug) {
      throw new BadRequestException('Organization slug is required');
    }

    const existing = await this.prisma.organization.findUnique({
      where: { slug },
    });

    if (existing) {
      throw new BadRequestException('Organization slug already exists');
    }

    const organization = await this.prisma.organization.create({
      data: {
        name,
        slug,
        isActive: true,
      },
    });

    await this.safeAudit({
      actor,
      action: 'ORGANIZATION_CREATED',
      resource: 'Organization',
      resourceId: organization.id,
      after: organization,
      organizationId: organization.id,
      metadata: {
        name: organization.name,
        slug: organization.slug,
      },
    });

    return organization;
  }

  async findAll() {
    return this.prisma.organization.findMany({
      orderBy: {
        createdAt: 'desc',
      },
    });
  }

  async findOne(id: string) {
    const org = await this.prisma.organization.findUnique({
      where: { id },
    });

    if (!org) {
      throw new NotFoundException('Organization not found');
    }

    return org;
  }

  async update(id: string, dto: UpdateOrganizationDto, actor?: any) {
    const before = await this.findOne(id);

    const data: any = {};

    if (typeof dto.name === 'string') {
      const name = dto.name.trim();

      if (!name) {
        throw new BadRequestException('Organization name cannot be empty');
      }

      data.name = name;
    }

    if (typeof dto.slug === 'string') {
      const slug = dto.slug.trim().toLowerCase();

      if (!slug) {
        throw new BadRequestException('Organization slug cannot be empty');
      }

      const existing = await this.prisma.organization.findUnique({
        where: { slug },
      });

      if (existing && existing.id !== id) {
        throw new BadRequestException('Organization slug already exists');
      }

      data.slug = slug;
    }

    if (typeof dto.isActive === 'boolean') {
      data.isActive = dto.isActive;
    }

    const updated = await this.prisma.organization.update({
      where: { id },
      data,
    });

    let action = 'ORGANIZATION_UPDATED';

    if (before.isActive === true && updated.isActive === false) {
      action = 'ORGANIZATION_DEACTIVATED';
    }

    if (before.isActive === false && updated.isActive === true) {
      action = 'ORGANIZATION_REACTIVATED';
    }

    await this.safeAudit({
      actor,
      action,
      resource: 'Organization',
      resourceId: id,
      before,
      after: updated,
      organizationId: id,
      metadata: {
        previousName: before.name,
        newName: updated.name,
        previousSlug: before.slug,
        newSlug: updated.slug,
        previousActive: before.isActive,
        newActive: updated.isActive,
      },
    });

    return updated;
  }

  async remove(id: string, actor?: any) {
    const before = await this.findOne(id);

    const updated = await this.prisma.organization.update({
      where: { id },
      data: {
        isActive: false,
      },
    });

    await this.safeAudit({
      actor,
      action: 'ORGANIZATION_DEACTIVATED',
      resource: 'Organization',
      resourceId: id,
      before,
      after: updated,
      organizationId: id,
      metadata: {
        name: updated.name,
        slug: updated.slug,
      },
    });

    return updated;
  }

  private async assertUserCanMoveOrganization(input: {
    userId: string;
    currentOrganizationId?: string | null;
    newOrganizationId: string;
    role: Role;
  }) {
    const { userId, currentOrganizationId, newOrganizationId, role } = input;

    if (currentOrganizationId === newOrganizationId) {
      return;
    }

    if (role !== Role.TENANT) {
      return;
    }

    const tenant = await this.prisma.tenant.findUnique({
      where: {
        userId,
      },
      include: {
        _count: {
          select: {
            leases: true,
            payments: true,
          },
        },
      },
    });

    const createdTicketsCount = await this.prisma.ticket.count({
      where: {
        createdById: userId,
      },
    });

    const hasTenantProfile = !!tenant;
    const hasLeases = (tenant?._count?.leases ?? 0) > 0;
    const hasPayments = (tenant?._count?.payments ?? 0) > 0;
    const hasTickets = createdTicketsCount > 0;

    const hasRentalHistory =
      hasTenantProfile && (hasLeases || hasPayments || hasTickets);

    if (hasRentalHistory) {
      throw new BadRequestException(
        'Tenant users with rental history cannot be moved to another organization. Create a new tenant profile/account for the new organization instead.',
      );
    }
  }

  async assignUser(orgId: string, userId: string, actor?: any) {
    const organization = await this.findOne(orgId);

    if (!organization.isActive) {
      throw new BadRequestException('Cannot assign user to inactive organization');
    }

    const before = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        role: true,
        organizationId: true,
      },
    });

    if (!before) {
      throw new NotFoundException('User not found');
    }

    await this.assertUserCanMoveOrganization({
      userId,
      currentOrganizationId: before.organizationId,
      newOrganizationId: orgId,
      role: before.role,
    });

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: {
        organizationId: orgId,
      },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        role: true,
        organizationId: true,
      },
    });

    await this.safeAudit({
      actor,
      action: 'USER_ASSIGNED_TO_ORGANIZATION',
      resource: 'User',
      resourceId: userId,
      before,
      after: updated,
      organizationId: orgId,
      metadata: {
        userEmail: updated.email,
        userRole: updated.role,
        previousOrganizationId: before.organizationId,
        newOrganizationId: orgId,
        organizationName: organization.name,
        organizationSlug: organization.slug,
      },
    });

    return updated;
  }
}