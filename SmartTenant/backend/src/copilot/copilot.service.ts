import { Injectable, BadRequestException } from '@nestjs/common';
import {
  InvoiceStatus,
  LeaseStatus,
  TicketStatus,
  UnitStatus,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class CopilotService {
  constructor(private readonly prisma: PrismaService) {}

  private startOfMonth(date = new Date()) {
    return new Date(date.getFullYear(), date.getMonth(), 1);
  }

  private startOfPreviousMonth(date = new Date()) {
    return new Date(date.getFullYear(), date.getMonth() - 1, 1);
  }

  private endOfPreviousMonth(date = new Date()) {
    return new Date(date.getFullYear(), date.getMonth(), 0, 23, 59, 59, 999);
  }

  private daysBetween(from: Date, to: Date) {
    const diff = to.getTime() - from.getTime();
    return Math.ceil(diff / (1000 * 60 * 60 * 24));
  }

  private formatMoney(value: number) {
    return Number(value.toFixed(2));
  }

  private safePercent(value: number) {
    return Number(value.toFixed(2));
  }

  private tenantName(invoice: any) {
    const user = invoice.lease?.tenant?.user;

    if (!user) return 'Tenant';

    const fullName = `${user.firstName ?? ''} ${user.lastName ?? ''}`.trim();

    if (fullName.length > 0) return fullName;
    if (user.email) return user.email;

    return 'Tenant';
  }

  private unitNameFromInvoice(invoice: any) {
    const unit = invoice.lease?.unit;

    if (!unit) return 'Unit';

    return unit.title ?? unit.number ?? 'Unit';
  }

  private propertyNameFromInvoice(invoice: any) {
    const property = invoice.lease?.unit?.property;

    if (!property) return 'Property';

    return property.title ?? property.name ?? 'Property';
  }

  private ticketAge(ticket: any) {
    return this.daysBetween(new Date(ticket.createdAt), new Date());
  }

  private ticketTitle(ticket: any) {
    return ticket.title ?? 'Ticket';
  }

  private leaseTenantName(lease: any) {
    const user = lease.tenant?.user;

    if (!user) return 'Tenant';

    const fullName = `${user.firstName ?? ''} ${user.lastName ?? ''}`.trim();

    if (fullName.length > 0) return fullName;
    if (user.email) return user.email;

    return 'Tenant';
  }

  private leaseUnitName(lease: any) {
    return lease.unit?.title ?? lease.unit?.number ?? 'Unit';
  }

  private leasePropertyName(lease: any) {
    return lease.unit?.property?.title ?? lease.unit?.property?.name ?? 'Property';
  }

  private calculateInvoiceAmounts(invoice: any) {
    const totalPaid = invoice.payments.reduce((sum: number, payment: any) => {
      return sum + payment.amount;
    }, 0);

    const remainingAmount = Math.max(invoice.amount - totalPaid, 0);

    return {
      totalPaid,
      remainingAmount,
    };
  }

  private scoreHealth(params: {
    occupancyRate: number;
    collectionRate: number;
    urgentOpenTickets: number;
    overdueInvoices: number;
    leasesEndingSoon: number;
    expiredActiveLeases: number;
  }) {
    let score = 100;

    if (params.occupancyRate < 90) score -= 10;
    if (params.occupancyRate < 70) score -= 10;

    if (params.collectionRate < 85) score -= 10;
    if (params.collectionRate < 65) score -= 15;

    score -= Math.min(params.urgentOpenTickets * 4, 16);
    score -= Math.min(params.overdueInvoices * 3, 15);
    score -= Math.min(params.leasesEndingSoon * 2, 10);
    score -= Math.min(params.expiredActiveLeases * 8, 24);

    return Math.max(Math.min(score, 100), 0);
  }

  private healthLabel(score: number) {
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 55) return 'Needs attention';
    return 'Critical';
  }

  private buildBriefingText(params: {
    score: number;
    unpaid: number;
    overdueInvoices: number;
    expiredActiveLeases: number;
    urgentTickets: number;
    occupancyRate: number;
    revenueTrend: number;
    leasesEndingSoon: number;
  }) {
    const parts: string[] = [];

    if (params.score >= 85) {
      parts.push('Your portfolio is in strong condition today.');
    } else if (params.score >= 70) {
      parts.push('Your portfolio is stable, with a few areas to monitor.');
    } else {
      parts.push('Your portfolio needs attention today.');
    }

    if (params.unpaid > 0) {
      parts.push(
        `There is ${params.unpaid.toFixed(
          2,
        )} in unpaid balance across active invoices.`,
      );
    }

    if (params.overdueInvoices > 0) {
      parts.push(`${params.overdueInvoices} invoice(s) are overdue.`);
    }

    if (params.expiredActiveLeases > 0) {
      parts.push(
        `${params.expiredActiveLeases} active lease(s) have already expired and need renewal or termination.`,
      );
    }

    if (params.urgentTickets > 0) {
      parts.push(`${params.urgentTickets} urgent ticket(s) need action.`);
    }

    if (params.leasesEndingSoon > 0) {
      parts.push(`${params.leasesEndingSoon} lease(s) are ending soon.`);
    }

    parts.push(`Occupancy is currently ${params.occupancyRate.toFixed(0)}%.`);

    if (params.revenueTrend > 0) {
      parts.push(
        `Revenue is up ${params.revenueTrend.toFixed(
          1,
        )}% compared to last month.`,
      );
    } else if (params.revenueTrend < 0) {
      parts.push(
        `Revenue is down ${Math.abs(params.revenueTrend).toFixed(
          1,
        )}% compared to last month.`,
      );
    }

    return parts.join(' ');
  }

  async briefing(orgId?: string) {
    if (!orgId) {
      throw new BadRequestException('No organization attached to your account');
    }

    const now = new Date();
    const monthStart = this.startOfMonth(now);
    const previousMonthStart = this.startOfPreviousMonth(now);
    const previousMonthEnd = this.endOfPreviousMonth(now);
    const thirtyDaysFromNow = new Date(
      now.getTime() + 30 * 24 * 60 * 60 * 1000,
    );

    const [
      properties,
      units,
      occupiedUnits,
      activeLeases,
      allInvoices,
      currentMonthPayments,
      previousMonthPayments,
      openTickets,
      endingLeases,
      expiredActiveLeases,
    ] = await Promise.all([
      this.prisma.property.count({
        where: {
          organizationId: orgId,
          isActive: true,
        },
      }),

      this.prisma.unit.count({
        where: {
          organizationId: orgId,
        },
      }),

      this.prisma.unit.count({
        where: {
          organizationId: orgId,
          status: UnitStatus.OCCUPIED,
        },
      }),

      this.prisma.lease.count({
        where: {
          organizationId: orgId,
          status: LeaseStatus.ACTIVE,
        },
      }),

      this.prisma.invoice.findMany({
        where: {
          lease: {
            organizationId: orgId,
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
      }),

      this.prisma.payment.findMany({
        where: {
          createdAt: {
            gte: monthStart,
          },
          invoice: {
            lease: {
              organizationId: orgId,
            },
          },
        },
        select: {
          amount: true,
        },
      }),

      this.prisma.payment.findMany({
        where: {
          createdAt: {
            gte: previousMonthStart,
            lte: previousMonthEnd,
          },
          invoice: {
            lease: {
              organizationId: orgId,
            },
          },
        },
        select: {
          amount: true,
        },
      }),

      this.prisma.ticket.findMany({
        where: {
          organizationId: orgId,
          status: {
            in: [TicketStatus.OPEN, TicketStatus.IN_PROGRESS],
          },
        },
        include: {
          createdBy: true,
          assignedTo: true,
          property: true,
          unit: true,
        },
        orderBy: {
          createdAt: 'asc',
        },
      }),

      this.prisma.lease.findMany({
        where: {
          organizationId: orgId,
          status: LeaseStatus.ACTIVE,
          endDate: {
            gte: now,
            lte: thirtyDaysFromNow,
          },
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
          endDate: 'asc',
        },
        take: 10,
      }),

      this.prisma.lease.findMany({
        where: {
          organizationId: orgId,
          status: LeaseStatus.ACTIVE,
          endDate: {
            lt: now,
          },
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
          endDate: 'asc',
        },
        take: 10,
      }),
    ]);

    const enrichedInvoices = allInvoices.map((invoice) => {
      const amounts = this.calculateInvoiceAmounts(invoice);

      return {
        ...invoice,
        totalPaid: amounts.totalPaid,
        remainingAmount: amounts.remainingAmount,
      };
    });

    const totalInvoiced = enrichedInvoices.reduce((sum, invoice) => {
      return sum + invoice.amount;
    }, 0);

    const totalPaid = enrichedInvoices.reduce((sum, invoice) => {
      return sum + invoice.totalPaid;
    }, 0);

    const totalUnpaid = enrichedInvoices.reduce((sum, invoice) => {
      return sum + invoice.remainingAmount;
    }, 0);

    const overdueInvoices = enrichedInvoices
      .filter((invoice) => {
        return (
          invoice.remainingAmount > 0 &&
          new Date(invoice.dueDate).getTime() < now.getTime()
        );
      })
      .sort((a, b) => b.remainingAmount - a.remainingAmount)
      .slice(0, 10);

    const currentRevenue = currentMonthPayments.reduce((sum, payment) => {
      return sum + payment.amount;
    }, 0);

    const previousRevenue = previousMonthPayments.reduce((sum, payment) => {
      return sum + payment.amount;
    }, 0);

    const revenueTrend =
      previousRevenue === 0
        ? currentRevenue > 0
          ? 100
          : 0
        : ((currentRevenue - previousRevenue) / previousRevenue) * 100;

    const occupancyRate = units === 0 ? 0 : (occupiedUnits / units) * 100;

    const collectionRate =
      totalInvoiced === 0 ? 0 : (totalPaid / totalInvoiced) * 100;

    const urgentTickets = openTickets.filter((ticket) => {
      const priority = ticket.priority?.toString();
      const age = this.ticketAge(ticket);

      return priority === 'urgent' || priority === 'high' || age >= 3;
    });

    const maintenanceMap = new Map<
      string,
      {
        unitId: string;
        unitName: string;
        propertyName: string;
        count: number;
      }
    >();

    for (const ticket of openTickets) {
      if (!ticket.unitId || !ticket.unit) continue;

      const existing =
        maintenanceMap.get(ticket.unitId) ??
        {
          unitId: ticket.unitId,
          unitName: ticket.unit.title ?? ticket.unit.number ?? 'Unit',
          propertyName:
            ticket.property?.title ?? ticket.property?.name ?? 'Property',
          count: 0,
        };

      existing.count += 1;
      maintenanceMap.set(ticket.unitId, existing);
    }

    const maintenanceHotspots = Array.from(maintenanceMap.values())
      .filter((item) => item.count >= 2)
      .sort((a, b) => b.count - a.count)
      .slice(0, 5);

    const healthScore = this.scoreHealth({
      occupancyRate,
      collectionRate,
      urgentOpenTickets: urgentTickets.length,
      overdueInvoices: overdueInvoices.length,
      leasesEndingSoon: endingLeases.length,
      expiredActiveLeases: expiredActiveLeases.length,
    });

    const alerts: any[] = [];
    const recommendations: any[] = [];

    if (overdueInvoices.length > 0) {
      alerts.push({
        type: 'PAYMENT_RISK',
        severity: 'HIGH',
        title: 'Overdue invoices detected',
        body: `${overdueInvoices.length} invoice(s) are overdue with a total unpaid balance of ${this.formatMoney(
          overdueInvoices.reduce((sum, invoice) => {
            return sum + invoice.remainingAmount;
          }, 0),
        )}.`,
      });

      recommendations.push({
        title: 'Follow up on overdue invoices',
        body: 'Review unpaid balances and contact tenants with overdue rent.',
        action: 'OPEN_INVOICES',
        priority: 'HIGH',
      });
    }

    if (expiredActiveLeases.length > 0) {
      alerts.push({
        type: 'LEASE_EXPIRED',
        severity: 'HIGH',
        title: 'Expired active leases detected',
        body: `${expiredActiveLeases.length} active lease(s) have already passed their end date. Review them and terminate or renew them.`,
      });

      recommendations.push({
        title: 'Review expired active leases',
        body: 'Some leases have ended but are still marked active. Terminate them or create renewal agreements.',
        action: 'OPEN_LEASES',
        priority: 'HIGH',
      });
    }

    if (urgentTickets.length > 0) {
      alerts.push({
        type: 'MAINTENANCE_RISK',
        severity: 'HIGH',
        title: 'Urgent maintenance needs attention',
        body: `${urgentTickets.length} urgent or aging ticket(s) are still open.`,
      });

      recommendations.push({
        title: 'Prioritize urgent tickets',
        body: 'Assign urgent tickets to an agent and update their status.',
        action: 'OPEN_TICKETS',
        priority: 'HIGH',
      });
    }

    if (endingLeases.length > 0) {
      alerts.push({
        type: 'LEASE_RENEWAL',
        severity: 'MEDIUM',
        title: 'Leases ending soon',
        body: `${endingLeases.length} active lease(s) will end within 30 days.`,
      });

      recommendations.push({
        title: 'Prepare lease renewals',
        body: 'Contact tenants before lease end dates to avoid vacancy.',
        action: 'OPEN_LEASES',
        priority: 'MEDIUM',
      });
    }

    if (occupancyRate < 80 && units > 0) {
      alerts.push({
        type: 'OCCUPANCY',
        severity: 'MEDIUM',
        title: 'Occupancy below target',
        body: `Occupancy is ${occupancyRate.toFixed(
          0,
        )}%. Review available units and leasing activity.`,
      });

      recommendations.push({
        title: 'Review available units',
        body: 'Inspect vacant units and prepare them for leasing.',
        action: 'OPEN_UNITS',
        priority: 'MEDIUM',
      });
    }

    if (alerts.length === 0) {
      alerts.push({
        type: 'GOOD_NEWS',
        severity: 'LOW',
        title: 'No critical risks today',
        body: 'Your portfolio looks stable. Keep monitoring payments and tickets.',
      });

      recommendations.push({
        title: 'Keep monitoring your portfolio',
        body: 'Review reports weekly and respond quickly to tenant requests.',
        action: 'OPEN_REPORTS',
        priority: 'LOW',
      });
    }

    const briefing = this.buildBriefingText({
      score: healthScore,
      unpaid: totalUnpaid,
      overdueInvoices: overdueInvoices.length,
      expiredActiveLeases: expiredActiveLeases.length,
      urgentTickets: urgentTickets.length,
      occupancyRate,
      revenueTrend,
      leasesEndingSoon: endingLeases.length,
    });

    return {
      generatedAt: new Date(),
      health: {
        score: healthScore,
        label: this.healthLabel(healthScore),
        occupancyRate: this.safePercent(occupancyRate),
        collectionRate: this.safePercent(collectionRate),
        revenueTrend: this.safePercent(revenueTrend),
      },
      summary: {
        properties,
        units,
        occupiedUnits,
        activeLeases,
        totalInvoiced: this.formatMoney(totalInvoiced),
        totalPaid: this.formatMoney(totalPaid),
        totalUnpaid: this.formatMoney(totalUnpaid),
        currentMonthRevenue: this.formatMoney(currentRevenue),
        previousMonthRevenue: this.formatMoney(previousRevenue),
        openTickets: openTickets.length,
        urgentTickets: urgentTickets.length,
        overdueInvoices: overdueInvoices.length,
        leasesEndingSoon: endingLeases.length,
        expiredActiveLeases: expiredActiveLeases.length,
      },
      briefing,
      alerts,
      recommendations,
      overdueInvoices: overdueInvoices.map((invoice) => ({
        id: invoice.id,
        amount: invoice.amount,
        totalPaid: invoice.totalPaid,
        remainingAmount: invoice.remainingAmount,
        dueDate: invoice.dueDate,
        status: invoice.status,
        tenantName: this.tenantName(invoice),
        tenantEmail: invoice.lease.tenant.user.email,
        unitName: this.unitNameFromInvoice(invoice),
        propertyName: this.propertyNameFromInvoice(invoice),
      })),
      urgentTickets: urgentTickets.slice(0, 10).map((ticket) => ({
        id: ticket.id,
        title: this.ticketTitle(ticket),
        status: ticket.status,
        priority: ticket.priority,
        ageDays: this.ticketAge(ticket),
        createdAt: ticket.createdAt,
        assignedToEmail: ticket.assignedTo?.email ?? null,
        propertyName: ticket.property?.title ?? ticket.property?.name ?? null,
        unitName: ticket.unit?.title ?? ticket.unit?.number ?? null,
      })),
      leasesEndingSoon: endingLeases.map((lease) => ({
        id: lease.id,
        endDate: lease.endDate,
        rentAmount: lease.rentAmount,
        frequency: lease.frequency,
        tenantName: this.leaseTenantName(lease),
        tenantEmail: lease.tenant.user.email,
        unitName: this.leaseUnitName(lease),
        propertyName: this.leasePropertyName(lease),
        daysLeft: this.daysBetween(now, lease.endDate),
      })),
      expiredActiveLeases: expiredActiveLeases.map((lease) => ({
        id: lease.id,
        endDate: lease.endDate,
        rentAmount: lease.rentAmount,
        frequency: lease.frequency,
        tenantName: this.leaseTenantName(lease),
        tenantEmail: lease.tenant.user.email,
        unitName: this.leaseUnitName(lease),
        propertyName: this.leasePropertyName(lease),
        daysExpired: this.daysBetween(lease.endDate, now),
      })),
      maintenanceHotspots,
    };
  }
}