import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateUnitDto } from './dto/create-unit.dto';
import { UpdateUnitDto } from './dto/update-unit.dto';
import { LeaseStatus, UnitStatus } from '@prisma/client';

@Injectable()
export class UnitService {
  constructor(private readonly prisma: PrismaService) {}

  private validateNumbers(dto: {
    rentAmount?: number;
    floor?: number;
    bedrooms?: number;
    bathrooms?: number;
    sizeSqm?: number;
  }) {
    if (dto.rentAmount !== undefined && dto.rentAmount <= 0) {
      throw new BadRequestException('Rent amount must be positive');
    }

    if (dto.floor !== undefined && dto.floor < 0) {
      throw new BadRequestException('Floor cannot be negative');
    }

    if (dto.bedrooms !== undefined && dto.bedrooms < 0) {
      throw new BadRequestException('Bedrooms cannot be negative');
    }

    if (dto.bathrooms !== undefined && dto.bathrooms < 0) {
      throw new BadRequestException('Bathrooms cannot be negative');
    }

    if (dto.sizeSqm !== undefined && dto.sizeSqm <= 0) {
      throw new BadRequestException('Size must be positive');
    }
  }

  private unitInclude() {
    return {
      property: true,
      currentLease: {
        include: {
          tenant: {
            include: {
              user: true,
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
      },
      leases: {
        include: {
          tenant: {
            include: {
              user: true,
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
          startDate: 'desc' as const,
        },
      },
      tickets: {
        orderBy: {
          createdAt: 'desc' as const,
        },
      },
    };
  }

  async create(orgId: string, propertyId: string, dto: CreateUnitDto) {
    this.validateNumbers(dto);

    if (!dto.title || dto.title.trim().length === 0) {
      throw new BadRequestException('Unit title is required');
    }

    if (dto.status === UnitStatus.OCCUPIED) {
      throw new BadRequestException(
        'New units cannot be created as OCCUPIED. Create a lease instead.',
      );
    }

    const property = await this.prisma.property.findFirst({
      where: {
        id: propertyId,
        organizationId: orgId,
        isActive: true,
      },
    });

    if (!property) {
      throw new NotFoundException('Property not found or inactive');
    }

    return this.prisma.unit.create({
      data: {
        propertyId,
        organizationId: orgId,
        title: dto.title.trim(),
        rentAmount: dto.rentAmount,
        floor: dto.floor,
        bedrooms: dto.bedrooms,
        bathrooms: dto.bathrooms,
        number: dto.number?.trim() || null,
        sizeSqm: dto.sizeSqm,
        status: dto.status ?? UnitStatus.AVAILABLE,
      },
      include: {
        property: true,
      },
    });
  }

  async findByProperty(orgId: string, propertyId: string) {
    const property = await this.prisma.property.findFirst({
      where: {
        id: propertyId,
        organizationId: orgId,
        isActive: true,
      },
    });

    if (!property) {
      throw new NotFoundException('Property not found');
    }

    return this.prisma.unit.findMany({
      where: {
        propertyId,
        organizationId: orgId,
      },
      include: {
        currentLease: {
          include: {
            tenant: {
              include: {
                user: true,
              },
            },
          },
        },
        property: true,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
  }

  async findOne(orgId: string, id: string) {
    const unit = await this.prisma.unit.findFirst({
      where: {
        id,
        organizationId: orgId,
      },
      include: this.unitInclude(),
    });

    if (!unit) {
      throw new NotFoundException('Unit not found');
    }

    return this.enrichUnit(unit);
  }

  async update(orgId: string, id: string, dto: UpdateUnitDto) {
    this.validateNumbers(dto);

    const unit = await this.prisma.unit.findFirst({
      where: {
        id,
        organizationId: orgId,
      },
      include: {
        currentLease: true,
        leases: {
          where: {
            status: LeaseStatus.ACTIVE,
          },
        },
      },
    });

    if (!unit) {
      throw new NotFoundException('Unit not found');
    }

    const hasActiveLease = unit.leases.length > 0 || !!unit.currentLease;

    if (hasActiveLease && dto.status && dto.status !== UnitStatus.OCCUPIED) {
      throw new BadRequestException(
        'Unit has an active lease and must remain OCCUPIED. Terminate the lease first.',
      );
    }

    if (!hasActiveLease && dto.status === UnitStatus.OCCUPIED) {
      throw new BadRequestException(
        'Cannot manually set unit to OCCUPIED without an active lease.',
      );
    }

    const updated = await this.prisma.unit.update({
      where: {
        id,
      },
      data: {
        title:
          dto.title === undefined ? undefined : dto.title.trim() || unit.title,
        rentAmount: dto.rentAmount,
        floor: dto.floor,
        bedrooms: dto.bedrooms,
        bathrooms: dto.bathrooms,
        number:
          dto.number === undefined ? undefined : dto.number.trim() || null,
        sizeSqm: dto.sizeSqm,
        status: dto.status,
      },
      include: this.unitInclude(),
    });

    return this.enrichUnit(updated);
  }

  async remove(orgId: string, id: string) {
    const unit = await this.prisma.unit.findFirst({
      where: {
        id,
        organizationId: orgId,
      },
      include: {
        leases: true,
        tickets: true,
        currentLease: true,
      },
    });

    if (!unit) {
      throw new NotFoundException('Unit not found');
    }

    if (unit.status === UnitStatus.OCCUPIED || unit.currentLease) {
      throw new ForbiddenException(
        'Cannot delete occupied unit. Terminate the active lease first.',
      );
    }

    if (unit.leases.length > 0) {
      throw new ForbiddenException('Cannot delete unit with lease history.');
    }

    if (unit.tickets.length > 0) {
      throw new ForbiddenException(
        'Cannot delete unit with maintenance ticket history.',
      );
    }

    return this.prisma.unit.delete({
      where: {
        id,
      },
    });
  }

  private tenantName(lease: any) {
    const user = lease?.tenant?.user;

    if (!user) return 'Tenant';

    const fullName = `${user.firstName ?? ''} ${user.lastName ?? ''}`.trim();

    if (fullName.length > 0) return fullName;

    return user.email ?? 'Tenant';
  }

  private totalPaidForLease(lease: any) {
    const invoices = lease?.invoices ?? [];

    return invoices.reduce((sum: number, invoice: any) => {
      const payments = invoice.payments ?? [];

      const invoicePaid = payments.reduce((pSum: number, payment: any) => {
        return pSum + Number(payment.amount ?? 0);
      }, 0);

      return sum + invoicePaid;
    }, 0);
  }

  private totalInvoicedForLease(lease: any) {
    const invoices = lease?.invoices ?? [];

    return invoices.reduce((sum: number, invoice: any) => {
      return sum + Number(invoice.amount ?? 0);
    }, 0);
  }

  private buildAvailabilityTimeline(unit: any) {
    const events: any[] = [];

    const status = unit.status?.toString();

    events.push({
      type: 'UNIT_CREATED',
      title: 'Unit created',
      description: 'Unit was added to the property.',
      date: unit.createdAt,
      status,
    });

    for (const lease of unit.leases ?? []) {
      events.push({
        type: 'LEASE_PERIOD',
        title:
          lease.status === LeaseStatus.ACTIVE
            ? 'Active occupancy period'
            : 'Past occupancy period',
        description: `${this.tenantName(lease)} occupied this unit from ${new Date(
          lease.startDate,
        )
          .toISOString()
          .split('T')[0]} to ${new Date(lease.endDate)
          .toISOString()
          .split('T')[0]}.`,
        date: lease.startDate,
        startDate: lease.startDate,
        endDate: lease.endDate,
        status: lease.status,
        tenantName: this.tenantName(lease),
        rentAmount: Number(lease.rentAmount ?? 0),
        leaseId: lease.id,
        totalInvoiced: this.totalInvoicedForLease(lease),
        totalPaid: this.totalPaidForLease(lease),
      });

      if (lease.status === LeaseStatus.TERMINATED) {
        events.push({
          type: 'LEASE_TERMINATED',
          title: 'Lease terminated',
          description: `Lease with ${this.tenantName(lease)} was terminated.`,
          date: lease.updatedAt,
          status: lease.status,
          tenantName: this.tenantName(lease),
          leaseId: lease.id,
        });
      }
    }

    if (unit.currentLease) {
      events.push({
        type: 'CURRENT_OCCUPANCY',
        title: 'Current occupancy',
        description: `${this.tenantName(
          unit.currentLease,
        )} is currently occupying this unit.`,
        date: unit.currentLease.startDate,
        startDate: unit.currentLease.startDate,
        endDate: unit.currentLease.endDate,
        status: unit.currentLease.status,
        tenantName: this.tenantName(unit.currentLease),
        rentAmount: Number(unit.currentLease.rentAmount ?? 0),
        leaseId: unit.currentLease.id,
      });
    }

    return events.sort((a, b) => {
      return new Date(b.date).getTime() - new Date(a.date).getTime();
    });
  }

  private calculateAvailableFrom(unit: any) {
    if (unit.status === UnitStatus.AVAILABLE) {
      return new Date();
    }

    if (unit.status === UnitStatus.OCCUPIED && unit.currentLease?.endDate) {
      return unit.currentLease.endDate;
    }

    return null;
  }

  private enrichUnit(unit: any) {
    const activeLease = unit.currentLease ?? null;
    const availableFrom = this.calculateAvailableFrom(unit);
    const availabilityTimeline = this.buildAvailabilityTimeline(unit);

    return {
      ...unit,
      activeLease,
      currentTenant: activeLease?.tenant ?? null,
      currentTenantName: activeLease ? this.tenantName(activeLease) : null,
      availableFrom,
      availabilityTimeline,
      leaseHistoryCount: unit.leases?.length ?? 0,
      ticketHistoryCount: unit.tickets?.length ?? 0,
    };
  }
}