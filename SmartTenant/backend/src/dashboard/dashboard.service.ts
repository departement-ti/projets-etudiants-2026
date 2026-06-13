import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { LeaseStatus, UnitStatus } from '@prisma/client';

@Injectable()
export class DashboardService {
  constructor(private readonly prisma: PrismaService) {}

  async stats(orgId: string) {
    const properties = await this.prisma.property.count({
      where: {
        organizationId: orgId,
        isActive: true,
      },
    });

    const units = await this.prisma.unit.count({
      where: {
        organizationId: orgId,
      },
    });

    const occupiedUnits = await this.prisma.unit.count({
      where: {
        organizationId: orgId,
        status: UnitStatus.OCCUPIED,
      },
    });

    const activeLeases = await this.prisma.lease.count({
      where: {
        organizationId: orgId,
        status: LeaseStatus.ACTIVE,
      },
    });

    const payments = await this.prisma.payment.findMany({
      where: {
        invoice: {
          lease: {
            unit: {
              organizationId: orgId,
            },
          },
        },
      },
      select: {
        amount: true,
      },
    });

    const revenue = payments.reduce((sum, payment) => {
      return sum + payment.amount;
    }, 0);

    const invoices = await this.prisma.invoice.findMany({
      where: {
        lease: {
          unit: {
            organizationId: orgId,
          },
        },
      },
      include: {
        payments: true,
      },
    });

    const unpaid = invoices.reduce((sum, invoice) => {
      const totalPaid = invoice.payments.reduce(
        (paymentSum, payment) => paymentSum + payment.amount,
        0,
      );

      const remaining = Math.max(invoice.amount - totalPaid, 0);

      return sum + remaining;
    }, 0);

    const recentLeases = await this.prisma.lease.findMany({
      where: {
        organizationId: orgId,
      },
      include: {
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
      },
      orderBy: {
        createdAt: 'desc',
      },
      take: 5,
    });

    const recentInvoices = await this.prisma.invoice.findMany({
      where: {
        lease: {
          unit: {
            organizationId: orgId,
          },
        },
      },
      include: {
        payments: true,
        lease: {
          include: {
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
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
      take: 5,
    });

    const recentTickets = await this.prisma.ticket.findMany({
      where: {
        organizationId: orgId,
      },
      include: {
        createdBy: true,
        assignedTo: true,
        property: true,
        unit: true,
      },
      orderBy: {
        createdAt: 'desc',
      },
      take: 5,
    });

    const enrichedRecentInvoices = recentInvoices.map((invoice) => {
      const totalPaid = invoice.payments.reduce(
        (sum, payment) => sum + payment.amount,
        0,
      );

      const remainingAmount = Math.max(invoice.amount - totalPaid, 0);

      return {
        ...invoice,
        totalPaid,
        remainingAmount,
      };
    });

    return {
      properties,
      units,
      occupiedUnits,
      activeLeases,
      revenue,
      unpaid,
      recentLeases,
      recentInvoices: enrichedRecentInvoices,
      recentTickets,
    };
  }
}