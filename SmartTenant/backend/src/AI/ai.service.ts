import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InvoiceStatus, LeaseStatus, TicketStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationService } from '../notification/notification.service';

@Injectable()
export class AiService {
  constructor(
  private readonly prisma: PrismaService,
  private readonly notifications: NotificationService,
) {}

  // ======================================================
  // EXISTING FEATURE: RENT DELAY PREDICTION
  // ======================================================
  predictRentDelay(data: any) {
    const tenantName = data.tenantName ?? 'Tenant';
    const rentAmount = Number(data.rentAmount ?? 0);
    const previousLatePayments = Number(data.previousLatePayments ?? 0);
    const openTickets = Number(data.openTickets ?? 0);
    const unpaidAmount = Number(data.unpaidAmount ?? 0);

    let score = 20;

    score += previousLatePayments * 18;

    if (unpaidAmount > 0) score += 25;
    if (rentAmount > 0 && unpaidAmount >= rentAmount * 0.5) score += 15;
    if (openTickets >= 2) score += 10;

    score = Math.min(Math.max(score, 0), 100);

    const riskLevel =
      score >= 80 ? 'CRITICAL' : score >= 60 ? 'HIGH' : score >= 35 ? 'MEDIUM' : 'LOW';

    const explanation: string[] = [];

    if (previousLatePayments > 0) {
      explanation.push(
        `${tenantName} has ${previousLatePayments} previous late payment(s).`,
      );
    }

    if (unpaidAmount > 0) {
      explanation.push(`There is an unpaid balance of ${unpaidAmount}.`);
    }

    if (openTickets > 0) {
      explanation.push(
        `${openTickets} open maintenance ticket(s) may affect tenant satisfaction.`,
      );
    }

    if (explanation.length === 0) {
      explanation.push('No major negative signals were detected.');
    }

    const recommendations =
      riskLevel === 'LOW'
        ? [
            'Keep normal rent reminders.',
            'Maintain regular communication.',
          ]
        : riskLevel === 'MEDIUM'
          ? [
              'Send a friendly reminder before the due date.',
              'Monitor unpaid balance and open tickets.',
            ]
          : [
              'Contact tenant proactively before rent is due.',
              'Prioritize unresolved maintenance issues.',
              'Consider payment plan discussion if unpaid balance grows.',
            ];

    return {
      tenantName,
      score,
      riskLevel,
      summary: `${tenantName} has a ${riskLevel.toLowerCase()} rent delay risk.`,
      explanation,
      recommendations,
    };
  }

  // ======================================================
  // EXISTING FEATURE: TENANT RISK SCORE
  // ======================================================
  scoreTenantRisk(data: any) {
    const tenantName = data.tenantName ?? 'Tenant';
    const latePayments = Number(data.latePayments ?? 0);
    const unpaidAmount = Number(data.unpaidAmount ?? 0);
    const ticketsCount = Number(data.ticketsCount ?? 0);
    const leaseMonths = Number(data.leaseMonths ?? 0);

    let score = 100;

    score -= latePayments * 15;

    if (unpaidAmount > 0) score -= 20;
    if (unpaidAmount > 500) score -= 10;

    if (ticketsCount >= 3) score -= 10;
    if (leaseMonths >= 12) score += 8;

    score = Math.min(Math.max(score, 0), 100);

    const category =
      score >= 80 ? 'LOW' : score >= 60 ? 'MEDIUM' : score >= 40 ? 'ELEVATED' : 'HIGH';

    const strengths: string[] = [];
    const concerns: string[] = [];
    const recommendedActions: string[] = [];

    if (leaseMonths >= 12) {
      strengths.push('Longer lease history improves reliability confidence.');
    }

    if (latePayments === 0) {
      strengths.push('No late payments were reported.');
    } else {
      concerns.push(`${latePayments} late payment(s) reduce reliability score.`);
    }

    if (unpaidAmount > 0) {
      concerns.push(`Current unpaid balance is ${unpaidAmount}.`);
      recommendedActions.push('Discuss unpaid balance settlement with tenant.');
    }

    if (ticketsCount >= 3) {
      concerns.push('Multiple tickets may indicate satisfaction or unit condition issues.');
      recommendedActions.push('Review maintenance history before renewal.');
    }

    if (recommendedActions.length === 0) {
      recommendedActions.push('Continue standard tenant monitoring.');
    }

    return {
      tenantName,
      score,
      category,
      summary: `${tenantName} has a ${category.toLowerCase()} tenant risk profile.`,
      strengths,
      concerns,
      recommendedActions,
    };
  }

  // ======================================================
  // EXISTING FEATURE: SMART REPLY
  // ======================================================
  suggestReply(data: any) {
    const message = data.message?.toString() ?? '';
    const tone = data.tone?.toString() ?? 'professional';

    const lower = message.toLowerCase();

    let category = 'GENERAL';
    let urgency = 'NORMAL';

    if (
      lower.includes('leak') ||
      lower.includes('water') ||
      lower.includes('sink') ||
      lower.includes('toilet') ||
      lower.includes('pipe')
    ) {
      category = 'PLUMBING';
      urgency = lower.includes('urgent') || lower.includes('flood')
        ? 'HIGH'
        : 'MEDIUM';
    } else if (
      lower.includes('electric') ||
      lower.includes('power') ||
      lower.includes('wire') ||
      lower.includes('socket')
    ) {
      category = 'ELECTRICAL';
      urgency = 'HIGH';
    } else if (
      lower.includes('noise') ||
      lower.includes('neighbor') ||
      lower.includes('neighbour')
    ) {
      category = 'NOISE_COMPLAINT';
      urgency = 'NORMAL';
    }

    const greeting =
      tone === 'friendly'
        ? 'Hi, thanks for reaching out.'
        : tone === 'formal'
          ? 'Dear tenant, thank you for contacting us.'
          : tone === 'empathetic'
            ? 'Hi, I’m sorry you’re experiencing this issue.'
            : 'Hello, thank you for your message.';

    const suggestedReply =
      `${greeting} We have received your request and our team will review it as soon as possible. ` +
      `Please share any additional details or photos if available. We will keep you updated on the next steps.`;

    const quickReplies = [
      'Thank you for reporting this. We will review it shortly.',
      'Could you please send a photo or more details?',
      'Our team will follow up with you as soon as possible.',
    ];

    const nextActions =
      urgency === 'HIGH'
        ? [
            'Prioritize this ticket.',
            'Assign it to an available agent.',
            'Contact the tenant for immediate clarification.',
          ]
        : [
            'Review the ticket details.',
            'Reply to the tenant.',
            'Schedule follow-up if needed.',
          ];

    return {
      suggestedReply,
      category,
      urgency,
      quickReplies,
      nextActions,
    };
  }

  // ======================================================
  // NEW FEATURE: AI TENANT 360 INTELLIGENCE
  // ======================================================
  async tenant360(tenantId: string, orgId?: string) {
    if (!orgId) {
      throw new BadRequestException('No organization attached to your account');
    }

    const tenant = await this.prisma.tenant.findFirst({
      where: {
        id: tenantId,
        user: {
          organizationId: orgId,
        },
      },
      include: {
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
                dueDate: 'desc',
              },
            },
          },
          orderBy: {
            createdAt: 'desc',
          },
        },
        payments: {
          orderBy: {
            createdAt: 'desc',
          },
          take: 10,
        },
      },
    });

    if (!tenant) {
      throw new NotFoundException('Tenant not found');
    }

    const tickets = await this.prisma.ticket.findMany({
      where: {
        organizationId: orgId,
        createdById: tenant.userId,
      },
      include: {
        property: true,
        unit: true,
        assignedTo: true,
        messages: true,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    const now = new Date();

    const allInvoices = tenant.leases.flatMap((lease) => {
      return lease.invoices.map((invoice) => ({
        ...invoice,
        lease,
      }));
    });

    const activeLease =
      tenant.leases.find((lease) => lease.status === LeaseStatus.ACTIVE) ??
      null;

    const latestLease = tenant.leases[0] ?? null;

    const totalInvoiced = allInvoices.reduce((sum, invoice) => {
      return sum + invoice.amount;
    }, 0);

    const totalPaid = allInvoices.reduce((sum, invoice) => {
      const invoicePaid = invoice.payments.reduce((paymentSum, payment) => {
        return paymentSum + payment.amount;
      }, 0);

      return sum + invoicePaid;
    }, 0);

    const totalUnpaid = Math.max(totalInvoiced - totalPaid, 0);

    const enrichedInvoices = allInvoices.map((invoice) => {
      const invoicePaid = invoice.payments.reduce((sum, payment) => {
        return sum + payment.amount;
      }, 0);

      const remainingAmount = Math.max(invoice.amount - invoicePaid, 0);

      const isOverdue =
        remainingAmount > 0 && new Date(invoice.dueDate).getTime() < now.getTime();

      const wasPaidLate =
        invoice.paidAt &&
        new Date(invoice.paidAt).getTime() > new Date(invoice.dueDate).getTime();

      return {
        id: invoice.id,
        amount: invoice.amount,
        totalPaid: invoicePaid,
        remainingAmount,
        dueDate: invoice.dueDate,
        status: invoice.status,
        paid: invoice.paid,
        paidAt: invoice.paidAt,
        isOverdue,
        wasPaidLate,
      };
    });

    const overdueInvoices = enrichedInvoices.filter((invoice) => invoice.isOverdue);
    const latePaidInvoices = enrichedInvoices.filter((invoice) => invoice.wasPaidLate);

    const collectionRate =
      totalInvoiced === 0 ? 100 : (totalPaid / totalInvoiced) * 100;

    const openTickets = tickets.filter((ticket) => {
      return (
        ticket.status === TicketStatus.OPEN ||
        ticket.status === TicketStatus.IN_PROGRESS
      );
    });

    const urgentTickets = openTickets.filter((ticket) => {
      const priority = ticket.priority?.toString();

      return priority === 'urgent' || priority === 'high';
    });

    const resolvedTickets = tickets.filter((ticket) => {
      return (
        ticket.status === TicketStatus.RESOLVED ||
        ticket.status === TicketStatus.CLOSED
      );
    });

    const daysUntilLeaseEnd = activeLease
      ? this.daysBetween(now, activeLease.endDate)
      : null;

    const leaseEndingSoon =
      daysUntilLeaseEnd !== null && daysUntilLeaseEnd >= 0 && daysUntilLeaseEnd <= 30;

    const risk = this.calculateTenant360Risk({
      totalInvoiced,
      totalUnpaid,
      overdueInvoices: overdueInvoices.length,
      latePaidInvoices: latePaidInvoices.length,
      openTickets: openTickets.length,
      urgentTickets: urgentTickets.length,
      leaseEndingSoon,
      activeLeaseExists: !!activeLease,
      collectionRate,
    });

    const renewalRecommendation = this.buildRenewalRecommendation({
      riskLevel: risk.level,
      totalUnpaid,
      overdueInvoices: overdueInvoices.length,
      leaseEndingSoon,
      activeLease,
      daysUntilLeaseEnd,
    });

    const suggestedMessage = this.buildTenantMessage({
      tenantName: this.userDisplayName(tenant.user),
      totalUnpaid,
      overdueInvoices: overdueInvoices.length,
      leaseEndingSoon,
      daysUntilLeaseEnd,
      riskLevel: risk.level,
    });

    const nextBestActions = this.buildNextBestActions({
      totalUnpaid,
      overdueInvoices: overdueInvoices.length,
      urgentTickets: urgentTickets.length,
      openTickets: openTickets.length,
      leaseEndingSoon,
      riskLevel: risk.level,
    });

    const managementSummary = this.buildManagementSummary({
      tenantName: this.userDisplayName(tenant.user),
      riskLevel: risk.level,
      riskScore: risk.score,
      totalUnpaid,
      overdueInvoices: overdueInvoices.length,
      openTickets: openTickets.length,
      urgentTickets: urgentTickets.length,
      leaseEndingSoon,
      daysUntilLeaseEnd,
      collectionRate,
    });

    return {
      generatedAt: new Date(),

      tenant: {
        id: tenant.id,
        userId: tenant.userId,
        name: this.userDisplayName(tenant.user),
        email: tenant.user.email,
        phone: tenant.user.phone,
        nationalId: tenant.nationalId,
        createdAt: tenant.createdAt,
      },

      lease: activeLease
        ? {
            id: activeLease.id,
            status: activeLease.status,
            startDate: activeLease.startDate,
            endDate: activeLease.endDate,
            daysUntilEnd: daysUntilLeaseEnd,
            rentAmount: activeLease.rentAmount,
            frequency: activeLease.frequency,
            unit: {
              id: activeLease.unit.id,
              title: activeLease.unit.title,
              number: activeLease.unit.number,
              property: {
                id: activeLease.unit.property?.id,
                title: activeLease.unit.property?.title,
                name: activeLease.unit.property?.name,
              },
            },
          }
        : latestLease
          ? {
              id: latestLease.id,
              status: latestLease.status,
              startDate: latestLease.startDate,
              endDate: latestLease.endDate,
              daysUntilEnd: null,
              rentAmount: latestLease.rentAmount,
              frequency: latestLease.frequency,
              unit: {
                id: latestLease.unit.id,
                title: latestLease.unit.title,
                number: latestLease.unit.number,
                property: {
                  id: latestLease.unit.property?.id,
                  title: latestLease.unit.property?.title,
                  name: latestLease.unit.property?.name,
                },
              },
            }
          : null,

      financials: {
        totalInvoiced: this.money(totalInvoiced),
        totalPaid: this.money(totalPaid),
        totalUnpaid: this.money(totalUnpaid),
        collectionRate: this.percent(collectionRate),
        invoiceCount: enrichedInvoices.length,
        overdueInvoices: overdueInvoices.length,
        latePaidInvoices: latePaidInvoices.length,
      },

      maintenance: {
        totalTickets: tickets.length,
        openTickets: openTickets.length,
        urgentTickets: urgentTickets.length,
        resolvedTickets: resolvedTickets.length,
        lastTickets: tickets.slice(0, 5).map((ticket) => ({
          id: ticket.id,
          title: ticket.title,
          status: ticket.status,
          priority: ticket.priority,
          createdAt: ticket.createdAt,
          assignedToEmail: ticket.assignedTo?.email ?? null,
          propertyName: ticket.property?.title ?? ticket.property?.name ?? null,
          unitName: ticket.unit?.title ?? ticket.unit?.number ?? null,
        })),
      },

      ai: {
        riskScore: risk.score,
        riskLevel: risk.level,
        healthLabel: risk.healthLabel,
        managementSummary,
        riskFactors: risk.factors,
        positiveSignals: risk.positiveSignals,
        renewalRecommendation,
        nextBestActions,
        suggestedMessage,
      },

      invoices: enrichedInvoices.slice(0, 8),
    };
  }
  async sendTenant360Message(
  tenantId: string,
  orgId: string | undefined,
  actor: any,
  message: string,
) {
  if (!orgId) {
    throw new BadRequestException('No organization attached to your account');
  }

  const cleanMessage = message?.toString().trim();

  if (!cleanMessage) {
    throw new BadRequestException('Message is required');
  }

  const tenant = await this.prisma.tenant.findFirst({
    where: {
      id: tenantId,
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

  await this.notifications.create({
    userId: tenant.userId,
    organizationId: orgId,
    title: 'Message from management',
    body: cleanMessage,
    type: 'AI_MESSAGE',
    resource: 'Tenant',
    resourceId: tenant.id,
    metadata: {
      tenantId: tenant.id,
      tenantEmail: tenant.user.email,
      sentById: actor?.id,
      sentByEmail: actor?.email,
      source: 'AI_TENANT_360',
    },
  });

  return {
    success: true,
    message: 'Message sent to tenant',
  };
}

  // ======================================================
  // TENANT 360 HELPERS
  // ======================================================
  private calculateTenant360Risk(params: {
    totalInvoiced: number;
    totalUnpaid: number;
    overdueInvoices: number;
    latePaidInvoices: number;
    openTickets: number;
    urgentTickets: number;
    leaseEndingSoon: boolean;
    activeLeaseExists: boolean;
    collectionRate: number;
  }) {
    let score = 18;
    const factors: string[] = [];
    const positiveSignals: string[] = [];

    const unpaidRatio =
      params.totalInvoiced === 0
        ? 0
        : params.totalUnpaid / params.totalInvoiced;

    if (params.totalUnpaid > 0) {
      const impact = Math.min(unpaidRatio * 40, 30);
      score += impact;
      factors.push(
        `Tenant has an unpaid balance of ${this.money(params.totalUnpaid)}.`,
      );
    } else {
      positiveSignals.push('No unpaid balance detected.');
      score -= 8;
    }

    if (params.overdueInvoices > 0) {
      score += Math.min(params.overdueInvoices * 9, 27);
      factors.push(`${params.overdueInvoices} invoice(s) are overdue.`);
    } else {
      positiveSignals.push('No overdue invoices detected.');
    }

    if (params.latePaidInvoices > 0) {
      score += Math.min(params.latePaidInvoices * 5, 15);
      factors.push(`${params.latePaidInvoices} invoice(s) were paid late.`);
    }

    if (params.urgentTickets > 0) {
      score += Math.min(params.urgentTickets * 6, 18);
      factors.push(`${params.urgentTickets} urgent/high ticket(s) are open.`);
    }

    if (params.openTickets > 0) {
      score += Math.min(params.openTickets * 3, 12);
      factors.push(`${params.openTickets} ticket(s) still need follow-up.`);
    } else {
      positiveSignals.push('No open maintenance requests.');
    }

    if (params.leaseEndingSoon) {
      score += 8;
      factors.push('Lease is ending soon, renewal decision is time-sensitive.');
    }

    if (!params.activeLeaseExists) {
      score += 12;
      factors.push('No active lease was found for this tenant.');
    }

    if (params.collectionRate >= 95 && params.totalInvoiced > 0) {
      positiveSignals.push('Strong rent collection rate.');
      score -= 7;
    }

    score = Math.round(Math.min(Math.max(score, 0), 100));

    const level =
      score >= 80
        ? 'CRITICAL'
        : score >= 60
          ? 'HIGH'
          : score >= 35
            ? 'MEDIUM'
            : 'LOW';

    const healthLabel =
      level === 'LOW'
        ? 'Excellent'
        : level === 'MEDIUM'
          ? 'Watch'
          : level === 'HIGH'
            ? 'Risky'
            : 'Critical';

    if (factors.length === 0) {
      factors.push('No major risk factors were detected.');
    }

    if (positiveSignals.length === 0) {
      positiveSignals.push('Positive signals are limited or need more data.');
    }

    return {
      score,
      level,
      healthLabel,
      factors,
      positiveSignals,
    };
  }

  private buildRenewalRecommendation(params: {
    riskLevel: string;
    totalUnpaid: number;
    overdueInvoices: number;
    leaseEndingSoon: boolean;
    activeLease: any;
    daysUntilLeaseEnd: number | null;
  }) {
    if (!params.activeLease) {
      return {
        decision: 'NO_ACTIVE_LEASE',
        title: 'No active lease',
        body: 'No active lease was found. Review tenant history before creating a new lease.',
      };
    }

    if (params.totalUnpaid > 0 || params.overdueInvoices > 0) {
      return {
        decision: 'CONDITIONAL_RENEWAL',
        title: 'Renew only after balance review',
        body: 'Tenant may be renewed, but unpaid or overdue balances should be settled or formally planned before signing.',
      };
    }

    if (params.riskLevel === 'HIGH' || params.riskLevel === 'CRITICAL') {
      return {
        decision: 'MANAGER_REVIEW_REQUIRED',
        title: 'Manager review required',
        body: 'Risk level is high. Review payment and maintenance history before offering renewal.',
      };
    }

    if (params.leaseEndingSoon) {
      return {
        decision: 'RENEWAL_OPPORTUNITY',
        title: 'Good renewal opportunity',
        body: `Lease ends in ${params.daysUntilLeaseEnd} day(s). Tenant looks suitable for proactive renewal discussion.`,
      };
    }

    return {
      decision: 'MONITOR',
      title: 'Continue monitoring',
      body: 'Tenant profile is stable. No urgent renewal action is needed today.',
    };
  }

  private buildTenantMessage(params: {
    tenantName: string;
    totalUnpaid: number;
    overdueInvoices: number;
    leaseEndingSoon: boolean;
    daysUntilLeaseEnd: number | null;
    riskLevel: string;
  }) {
    if (params.totalUnpaid > 0) {
      return `Hello ${params.tenantName}, we hope you are doing well. We noticed that your account currently has an outstanding balance of ${this.money(
        params.totalUnpaid,
      )}. Please let us know if you would like to discuss payment options or need any clarification.`;
    }

    if (params.leaseEndingSoon) {
      return `Hello ${params.tenantName}, we hope everything is going well. Your lease is approaching its end date in ${params.daysUntilLeaseEnd} day(s), and we would like to discuss renewal options with you.`;
    }

    if (params.riskLevel === 'LOW') {
      return `Hello ${params.tenantName}, thank you for keeping your account in good standing. Please contact us anytime if you need support or have questions.`;
    }

    return `Hello ${params.tenantName}, we are reviewing your tenant profile and would like to make sure everything is going smoothly. Please let us know if there is anything we can help with.`;
  }

  private buildNextBestActions(params: {
    totalUnpaid: number;
    overdueInvoices: number;
    urgentTickets: number;
    openTickets: number;
    leaseEndingSoon: boolean;
    riskLevel: string;
  }) {
    const actions: string[] = [];

    if (params.totalUnpaid > 0) {
      actions.push('Review outstanding balance and contact tenant.');
    }

    if (params.overdueInvoices > 0) {
      actions.push('Prioritize overdue invoice follow-up.');
    }

    if (params.urgentTickets > 0) {
      actions.push('Escalate urgent maintenance tickets before renewal decisions.');
    } else if (params.openTickets > 0) {
      actions.push('Follow up on open maintenance requests.');
    }

    if (params.leaseEndingSoon) {
      actions.push('Prepare renewal conversation before the lease end date.');
    }

    if (params.riskLevel === 'HIGH' || params.riskLevel === 'CRITICAL') {
      actions.push('Ask owner or manager to review this tenant before renewal.');
    }

    if (actions.length === 0) {
      actions.push('Tenant appears stable. Continue normal monitoring.');
    }

    return actions;
  }

  private buildManagementSummary(params: {
    tenantName: string;
    riskLevel: string;
    riskScore: number;
    totalUnpaid: number;
    overdueInvoices: number;
    openTickets: number;
    urgentTickets: number;
    leaseEndingSoon: boolean;
    daysUntilLeaseEnd: number | null;
    collectionRate: number;
  }) {
    const parts: string[] = [];

    parts.push(
      `${params.tenantName} currently has a ${params.riskLevel.toLowerCase()} risk profile with a score of ${params.riskScore}/100.`,
    );

    if (params.totalUnpaid > 0) {
      parts.push(`Outstanding balance is ${this.money(params.totalUnpaid)}.`);
    } else {
      parts.push('There is no unpaid balance.');
    }

    if (params.overdueInvoices > 0) {
      parts.push(`${params.overdueInvoices} invoice(s) are overdue.`);
    }

    if (params.urgentTickets > 0) {
      parts.push(`${params.urgentTickets} urgent maintenance ticket(s) need attention.`);
    } else if (params.openTickets > 0) {
      parts.push(`${params.openTickets} maintenance ticket(s) are still open.`);
    }

    if (params.leaseEndingSoon) {
      parts.push(
        `Lease ends in ${params.daysUntilLeaseEnd} day(s), so renewal should be reviewed soon.`,
      );
    }

    parts.push(`Collection rate is ${this.percent(params.collectionRate)}%.`);

    return parts.join(' ');
  }

  private userDisplayName(user: any) {
    const fullName = `${user.firstName ?? ''} ${user.lastName ?? ''}`.trim();

    if (fullName.length > 0) return fullName;
    if (user.email) return user.email;

    return 'Tenant';
  }

  private daysBetween(from: Date, to: Date) {
    const diff = new Date(to).getTime() - new Date(from).getTime();

    return Math.ceil(diff / (1000 * 60 * 60 * 24));
  }

  private money(value: number) {
    return Number(value.toFixed(2));
  }

  private percent(value: number) {
    return Number(value.toFixed(2));
  }
}