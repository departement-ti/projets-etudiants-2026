import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { NotificationService } from '../notification/notification.service';
import { CreateLeaseDto } from './dto/create-lease.dto';
import {
  LeaseStatus,
  UnitStatus,
  InvoiceStatus,
  PaymentFrequency,
} from '@prisma/client';

@Injectable()
export class LeaseService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly notifications: NotificationService,
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

  private async safeNotify(fn: () => Promise<any>) {
    try {
      await fn();
    } catch (e) {
      console.error('Notification failed:', e);
    }
  }

  private leaseInclude() {
    return {
      tenant: {
        include: {
          user: true,
        },
      },
      unit: {
        include: {
          property: true,
        },
      },
      invoices: true,
    };
  }

  private formatDate(value: Date) {
    return value.toISOString().split('T')[0];
  }

  private unitLabel(unit: any) {
    if (!unit) return 'unit';

    return unit.title ?? unit.number ?? 'unit';
  }

  private parseDate(value: string, label: string) {
    const date = new Date(value);

    if (Number.isNaN(date.getTime())) {
      throw new BadRequestException(`${label} is invalid`);
    }

    return date;
  }

  private daysBetween(start: Date, end: Date) {
    const diff = end.getTime() - start.getTime();

    return Math.ceil(diff / (1000 * 60 * 60 * 24));
  }

  private validateLeaseDuration(
    startDate: Date,
    endDate: Date,
    frequency: PaymentFrequency,
  ) {
    if (endDate <= startDate) {
      throw new BadRequestException('Lease end date must be after start date');
    }

    const days = this.daysBetween(startDate, endDate);

    const minimumDaysByFrequency: Record<PaymentFrequency, number> = {
      DAILY: 1,
      WEEKLY: 7,
      MONTHLY: 28,
      YEARLY: 365,
    };

    const minimumDays = minimumDaysByFrequency[frequency];

    if (days < minimumDays) {
      throw new BadRequestException(
        `${frequency} lease must last at least ${minimumDays} day(s)`,
      );
    }
  }

  async create(orgId: string, dto: CreateLeaseDto, actor?: any) {
    const startDate = this.parseDate(dto.startDate, 'Start date');
    const endDate = this.parseDate(dto.endDate, 'End date');

    if (!dto.frequency) {
      throw new BadRequestException('Payment frequency is required');
    }

    this.validateLeaseDuration(startDate, endDate, dto.frequency);

    if (!dto.rentAmount || dto.rentAmount <= 0) {
      throw new BadRequestException('Rent amount must be positive');
    }

    if (dto.depositAmount !== undefined && dto.depositAmount < 0) {
      throw new BadRequestException('Deposit amount cannot be negative');
    }

    if (dto.status && dto.status !== LeaseStatus.ACTIVE) {
      throw new BadRequestException('New leases must start as ACTIVE');
    }

    const unit = await this.prisma.unit.findFirst({
      where: {
        id: dto.unitId,
        organizationId: orgId,
      },
      include: {
        currentLease: true,
      },
    });

    if (!unit) {
      throw new NotFoundException('Unit not found');
    }

    if (unit.status !== UnitStatus.AVAILABLE) {
      throw new BadRequestException('Unit is not available');
    }

    if (unit.currentLease) {
      throw new BadRequestException('Unit already has an active current lease');
    }

    const tenant = await this.prisma.tenant.findFirst({
      where: {
        id: dto.tenantId,
        user: {
          organizationId: orgId,
        },
      },
      include: {
        user: true,
      },
    });

    if (!tenant) {
      throw new NotFoundException('Tenant not found');
    }

    const result = await this.prisma.$transaction(async (tx) => {
      const lease = await tx.lease.create({
        data: {
          organizationId: orgId,
          tenantId: dto.tenantId,
          unitId: dto.unitId,
          currentUnitId: dto.unitId,

          startDate,
          endDate,

          rentAmount: dto.rentAmount,
          frequency: dto.frequency,
          status: LeaseStatus.ACTIVE,

          ...(dto.depositAmount !== undefined && {
            depositAmount: dto.depositAmount,
          }),
        },
      });

      const invoice = await tx.invoice.create({
        data: {
          leaseId: lease.id,
          amount: lease.rentAmount,

          // First rent invoice is due at the lease start date.
          // This matches the usual rent-in-advance logic.
          dueDate: lease.startDate,

          status: InvoiceStatus.UNPAID,
          paid: false,
        },
      });

      await tx.unit.update({
        where: {
          id: dto.unitId,
        },
        data: {
          status: UnitStatus.OCCUPIED,
        },
      });

      return {
        lease,
        invoice,
      };
    });

    const createdLease = await this.findOne(orgId, result.lease.id);

    await this.safeAudit({
      actor,
      action: 'LEASE_CREATED',
      resource: 'Lease',
      resourceId: result.lease.id,
      after: createdLease,
      organizationId: orgId,
      metadata: {
        tenantId: dto.tenantId,
        tenantEmail: tenant.user.email,
        unitId: dto.unitId,
        previousUnitStatus: unit.status,
        newUnitStatus: UnitStatus.OCCUPIED,
        rentAmount: dto.rentAmount,
        frequency: dto.frequency,
        startDate,
        endDate,
        firstInvoiceId: result.invoice.id,
        firstInvoiceAmount: result.invoice.amount,
        firstInvoiceDueDate: result.invoice.dueDate,
      },
    });

    await this.safeNotify(() =>
      this.notifications.create({
        userId: tenant.userId,
        organizationId: orgId,
        title: 'New lease created',
        body: `A new lease was created for ${this.unitLabel(
          createdLease.unit,
        )} from ${this.formatDate(createdLease.startDate)} to ${this.formatDate(
          createdLease.endDate,
        )}.`,
        type: 'LEASE',
        resource: 'Lease',
        resourceId: createdLease.id,
        metadata: {
          leaseId: createdLease.id,
          unitId: createdLease.unitId,
          unitTitle: createdLease.unit.title,
          propertyId: createdLease.unit.propertyId,
          propertyTitle: createdLease.unit.property?.title,
          rentAmount: createdLease.rentAmount,
          frequency: createdLease.frequency,
          startDate: createdLease.startDate,
          endDate: createdLease.endDate,
          firstInvoiceId: result.invoice.id,
          firstInvoiceAmount: result.invoice.amount,
          firstInvoiceDueDate: result.invoice.dueDate,
        },
      }),
    );

    await this.safeNotify(() =>
      this.notifications.notifyOrganizationStaff({
        organizationId: orgId,
        excludeUserId: actor?.id,
        roles: ['ADMIN', 'OWNER'],
        title: 'Lease created',
        body: `Lease created for ${tenant.user.email} on ${this.unitLabel(
          createdLease.unit,
        )}.`,
        type: 'LEASE',
        resource: 'Lease',
        resourceId: createdLease.id,
        metadata: {
          leaseId: createdLease.id,
          tenantId: tenant.id,
          tenantEmail: tenant.user.email,
          unitId: createdLease.unitId,
          unitTitle: createdLease.unit.title,
          rentAmount: createdLease.rentAmount,
          frequency: createdLease.frequency,
        },
      }),
    );

    return createdLease;
  }

  findAll(orgId: string) {
    return this.prisma.lease.findMany({
      where: {
        organizationId: orgId,
      },
      include: this.leaseInclude(),
      orderBy: {
        createdAt: 'desc',
      },
    });
  }

  async findOne(orgId: string, id: string) {
    const lease = await this.prisma.lease.findFirst({
      where: {
        id,
        organizationId: orgId,
      },
      include: this.leaseInclude(),
    });

    if (!lease) {
      throw new NotFoundException('Lease not found');
    }

    return lease;
  }

  async terminate(orgId: string, id: string, actor?: any) {
    const before = await this.findOne(orgId, id);

    if (before.status !== LeaseStatus.ACTIVE) {
      throw new BadRequestException('Lease already terminated');
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.lease.update({
        where: {
          id,
        },
        data: {
          status: LeaseStatus.TERMINATED,
          currentUnitId: null,
        },
      });

      await tx.unit.update({
        where: {
          id: before.unitId,
        },
        data: {
          status: UnitStatus.AVAILABLE,
        },
      });
    });

    const after = await this.findOne(orgId, id);

    await this.safeAudit({
      actor,
      action: 'LEASE_TERMINATED',
      resource: 'Lease',
      resourceId: id,
      before,
      after,
      organizationId: orgId,
      metadata: {
        tenantId: before.tenantId,
        tenantEmail: before.tenant.user.email,
        unitId: before.unitId,
        unitTitle: before.unit.title,
        previousLeaseStatus: before.status,
        newLeaseStatus: after.status,
        previousUnitStatus: UnitStatus.OCCUPIED,
        newUnitStatus: UnitStatus.AVAILABLE,
      },
    });

    await this.safeNotify(() =>
      this.notifications.create({
        userId: before.tenant.userId,
        organizationId: orgId,
        title: 'Lease terminated',
        body: `Your lease for ${this.unitLabel(
          before.unit,
        )} has been terminated.`,
        type: 'WARNING',
        resource: 'Lease',
        resourceId: id,
        metadata: {
          leaseId: id,
          tenantId: before.tenantId,
          unitId: before.unitId,
          unitTitle: before.unit.title,
          propertyId: before.unit.propertyId,
          propertyTitle: before.unit.property?.title,
          previousStatus: before.status,
          newStatus: after.status,
        },
      }),
    );

    await this.safeNotify(() =>
      this.notifications.notifyOrganizationStaff({
        organizationId: orgId,
        excludeUserId: actor?.id,
        roles: ['ADMIN', 'OWNER'],
        title: 'Lease terminated',
        body: `Lease terminated for ${before.tenant.user.email} on ${this.unitLabel(
          before.unit,
        )}.`,
        type: 'WARNING',
        resource: 'Lease',
        resourceId: id,
        metadata: {
          leaseId: id,
          tenantId: before.tenantId,
          tenantEmail: before.tenant.user.email,
          unitId: before.unitId,
          unitTitle: before.unit.title,
        },
      }),
    );

    return {
      success: true,
    };
  }
}