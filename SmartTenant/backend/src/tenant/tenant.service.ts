import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateTenantDto } from './dto/create-tenant.dto';
import { UpdateTenantDto } from './dto/update-tenant.dto';
import { Prisma, Role } from '@prisma/client';
import * as bcrypt from 'bcrypt';

@Injectable()
export class TenantService {
  constructor(private readonly prisma: PrismaService) {}

  private tenantInclude() {
    return {
      user: true,
      leases: {
        include: {
          unit: {
            include: {
              property: true,
            },
          },
          invoices: {
            include: {
              payments: true,
            },
            orderBy: {
              dueDate: 'desc' as const,
            },
          },
        },
        orderBy: {
          createdAt: 'desc' as const,
        },
      },
      payments: {
        orderBy: {
          createdAt: 'desc' as const,
        },
      },
    };
  }

  async create(orgId: string, dto: CreateTenantDto) {
    const user = await this.prisma.user.findUnique({
      where: {
        id: dto.userId,
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (user.organizationId !== orgId) {
      throw new ForbiddenException('User does not belong to your organization');
    }

    if (user.role !== Role.TENANT) {
      throw new BadRequestException(
        'Only users with TENANT role can become tenants',
      );
    }

    const existing = await this.prisma.tenant.findUnique({
      where: {
        userId: dto.userId,
      },
    });

    if (existing) {
      throw new BadRequestException('Tenant already exists for this user');
    }

    const tenant = await this.prisma.tenant.create({
      data: {
        userId: dto.userId,
        nationalId: dto.nationalId ?? null,
        guarantor: dto.guarantor ?? Prisma.JsonNull,
      },
      include: this.tenantInclude(),
    });

    return this.enrichTenant(tenant);
  }

  async createTenantAccountAndProfile(
    orgId: string,
    dto: {
      email?: string;
      password?: string;
      firstName?: string;
      lastName?: string;
      phone?: string;
      nationalId?: string;
      guarantor?: any;
    },
  ) {
    const email = dto.email?.toString().trim().toLowerCase() ?? '';
    const password = dto.password?.toString() ?? '';

    if (!email) {
      throw new BadRequestException('Email is required');
    }

    if (!password || password.length < 6) {
      throw new BadRequestException('Password must be at least 6 characters');
    }

    const existingUser = await this.prisma.user.findUnique({
      where: {
        email,
      },
    });

    if (existingUser) {
      throw new BadRequestException('Email already exists');
    }

    const organization = await this.prisma.organization.findUnique({
      where: {
        id: orgId,
      },
    });

    if (!organization) {
      throw new NotFoundException('Organization not found');
    }

    if (!organization.isActive) {
      throw new BadRequestException('Organization is inactive');
    }

    const passwordHash = await bcrypt.hash(password, 10);

    const tenant = await this.prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          email,
          passwordHash,
          firstName:
            typeof dto.firstName === 'string'
              ? dto.firstName.trim() || null
              : null,
          lastName:
            typeof dto.lastName === 'string'
              ? dto.lastName.trim() || null
              : null,
          phone:
            typeof dto.phone === 'string' ? dto.phone.trim() || null : null,
          role: Role.TENANT,
          organizationId: orgId,
        },
      });

      return tx.tenant.create({
        data: {
          userId: user.id,
          nationalId:
            typeof dto.nationalId === 'string'
              ? dto.nationalId.trim() || null
              : null,
          guarantor: dto.guarantor ?? Prisma.JsonNull,
        },
        include: this.tenantInclude(),
      });
    });

    return this.enrichTenant(tenant);
  }

  async findAvailableTenantUsers(orgId: string) {
    return this.prisma.user.findMany({
      where: {
        organizationId: orgId,
        role: Role.TENANT,
        tenant: null,
      },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        phone: true,
        role: true,
        organizationId: true,
        createdAt: true,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
  }

  async findAllByOrganization(orgId: string) {
    const tenants = await this.prisma.tenant.findMany({
      where: {
        user: {
          organizationId: orgId,
          role: Role.TENANT,
        },
      },
      include: this.tenantInclude(),
      orderBy: {
        createdAt: 'desc',
      },
    });

    return tenants.map((tenant) => this.enrichTenant(tenant));
  }

  async findOne(id: string, orgId?: string) {
    const tenant = await this.prisma.tenant.findFirst({
      where: {
        id,
        ...(orgId
          ? {
              user: {
                organizationId: orgId,
                role: Role.TENANT,
              },
            }
          : {}),
      },
      include: this.tenantInclude(),
    });

    if (!tenant) {
      throw new NotFoundException('Tenant not found');
    }

    return this.enrichTenant(tenant);
  }

  async findByUserId(userId: string) {
    const tenant = await this.prisma.tenant.findUnique({
      where: {
        userId,
      },
      include: this.tenantInclude(),
    });

    if (!tenant) {
      throw new NotFoundException('Tenant profile not found');
    }

    return this.enrichTenant(tenant);
  }

  async update(id: string, dto: UpdateTenantDto, orgId?: string) {
    const tenant = await this.findOne(id, orgId);

    const updated = await this.prisma.tenant.update({
      where: {
        id,
      },
      data: {
        nationalId: dto.nationalId ?? tenant.nationalId,
        guarantor: dto.guarantor ?? tenant.guarantor ?? Prisma.JsonNull,
      },
      include: this.tenantInclude(),
    });

    return this.enrichTenant(updated);
  }

  async remove(id: string, orgId?: string) {
    const tenant = await this.findOne(id, orgId);

    if (tenant.leases && tenant.leases.length > 0) {
      throw new BadRequestException(
        'Cannot delete tenant profile with existing leases',
      );
    }

    return this.prisma.tenant.delete({
      where: {
        id,
      },
    });
  }

  private unitLabel(unit: any) {
    if (!unit) return 'Unit';

    const property = unit.property;
    const propertyName = property?.title ?? property?.name ?? 'Property';
    const unitName = unit.title ?? unit.number ?? 'Unit';

    return `${propertyName} • ${unitName}`;
  }

  private invoiceTotalPaid(invoice: any) {
    return (invoice.payments ?? []).reduce((sum: number, payment: any) => {
      return sum + Number(payment.amount ?? 0);
    }, 0);
  }

  private buildTimeline(input: {
    tenant: any;
    activeLease: any;
    allInvoices: any[];
    totalUnpaid: number;
  }) {
    const { tenant, activeLease, allInvoices, totalUnpaid } = input;

    const events: any[] = [];

    const pushEvent = (event: {
      type: string;
      title: string;
      description: string;
      date?: Date | string | null;
      amount?: number | null;
      status?: string | null;
      resourceId?: string | null;
    }) => {
      if (!event.date) return;

      events.push({
        type: event.type,
        title: event.title,
        description: event.description,
        date: event.date,
        amount: event.amount ?? null,
        status: event.status ?? null,
        resourceId: event.resourceId ?? null,
      });
    };

    pushEvent({
      type: 'TENANT_PROFILE_CREATED',
      title: 'Tenant profile created',
      description: 'Rental profile was created and linked to this tenant account.',
      date: tenant.createdAt,
      resourceId: tenant.id,
    });

    if (tenant.user?.createdAt) {
      pushEvent({
        type: 'TENANT_ACCOUNT_CREATED',
        title: 'Tenant account created',
        description: `Login account created for ${tenant.user.email}.`,
        date: tenant.user.createdAt,
        resourceId: tenant.user.id,
      });
    }

    for (const lease of tenant.leases ?? []) {
      pushEvent({
        type: 'LEASE_CREATED',
        title: 'Lease created',
        description: `Lease created for ${this.unitLabel(lease.unit)}.`,
        date: lease.createdAt,
        amount: Number(lease.rentAmount ?? 0),
        status: lease.status,
        resourceId: lease.id,
      });

      pushEvent({
        type: 'LEASE_STARTED',
        title: 'Lease started',
        description: `Lease period started for ${this.unitLabel(lease.unit)}.`,
        date: lease.startDate,
        amount: Number(lease.rentAmount ?? 0),
        status: lease.status,
        resourceId: lease.id,
      });

      if (lease.status === 'TERMINATED') {
        pushEvent({
          type: 'LEASE_TERMINATED',
          title: 'Lease terminated',
          description: `Lease for ${this.unitLabel(lease.unit)} was terminated.`,
          date: lease.updatedAt,
          status: lease.status,
          resourceId: lease.id,
        });
      }

      for (const invoice of lease.invoices ?? []) {
        const totalPaid = this.invoiceTotalPaid(invoice);
        const remaining = Math.max(Number(invoice.amount ?? 0) - totalPaid, 0);

        pushEvent({
          type: 'INVOICE_GENERATED',
          title: 'Invoice generated',
          description: `Invoice for ${Number(invoice.amount ?? 0).toFixed(
            2,
          )} was generated. Due date: ${new Date(invoice.dueDate)
            .toISOString()
            .split('T')[0]}.`,
          date: invoice.createdAt ?? invoice.dueDate,
          amount: Number(invoice.amount ?? 0),
          status: invoice.status,
          resourceId: invoice.id,
        });

        if (remaining > 0) {
          pushEvent({
            type: 'INVOICE_UNPAID',
            title: 'Unpaid invoice balance',
            description: `Remaining balance: ${remaining.toFixed(2)}.`,
            date: invoice.dueDate,
            amount: remaining,
            status: invoice.status,
            resourceId: invoice.id,
          });
        }

        for (const payment of invoice.payments ?? []) {
          pushEvent({
            type: 'PAYMENT_RECEIVED',
            title: 'Payment received',
            description: `Payment of ${Number(payment.amount ?? 0).toFixed(
              2,
            )} was recorded.`,
            date: payment.createdAt,
            amount: Number(payment.amount ?? 0),
            status: 'PAID',
            resourceId: payment.id,
          });
        }
      }
    }

    if (activeLease) {
      pushEvent({
        type: 'CURRENT_UNIT_ASSIGNED',
        title: 'Current unit assigned',
        description: `Tenant is currently assigned to ${this.unitLabel(
          activeLease.unit,
        )}.`,
        date: activeLease.updatedAt ?? activeLease.createdAt,
        status: activeLease.status,
        resourceId: activeLease.id,
      });
    }

    if (totalUnpaid > 0) {
      pushEvent({
        type: 'OUTSTANDING_BALANCE',
        title: 'Outstanding balance',
        description: `Tenant currently has ${totalUnpaid.toFixed(
          2,
        )} unpaid balance.`,
        date: new Date(),
        amount: totalUnpaid,
        status: 'UNPAID',
        resourceId: tenant.id,
      });
    }

    return events.sort((a, b) => {
      const dateA = new Date(a.date).getTime();
      const dateB = new Date(b.date).getTime();

      return dateB - dateA;
    });
  }

  private enrichTenant(tenant: any) {
    const activeLease =
      tenant.leases?.find((lease: any) => lease.status === 'ACTIVE') ?? null;

    const allInvoices =
      tenant.leases?.flatMap((lease: any) => lease.invoices ?? []) ?? [];

    const totalInvoiced = allInvoices.reduce((sum: number, invoice: any) => {
      return sum + Number(invoice.amount ?? 0);
    }, 0);

    const totalPaid = allInvoices.reduce((sum: number, invoice: any) => {
      const paid = this.invoiceTotalPaid(invoice);

      return sum + paid;
    }, 0);

    const totalUnpaid = Math.max(totalInvoiced - totalPaid, 0);

    const timeline = this.buildTimeline({
      tenant,
      activeLease,
      allInvoices,
      totalUnpaid,
    });

    return {
      ...tenant,
      activeLease,
      currentUnit: activeLease?.unit ?? null,
      totalInvoiced,
      totalPaid,
      totalUnpaid,
      timeline,
    };
  }
}