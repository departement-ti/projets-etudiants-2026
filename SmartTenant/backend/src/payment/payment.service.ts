import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { NotificationService } from '../notification/notification.service';
import { CreatePaymentDto } from './dto/create-payment.dto';
import { InvoiceStatus } from '@prisma/client';

@Injectable()
export class PaymentService {
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

  async create(orgId: string, user: any, dto: CreatePaymentDto) {
    const invoice = await this.prisma.invoice.findFirst({
      where: {
        id: dto.invoiceId,
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
    });

    if (!invoice) {
      throw new NotFoundException('Invoice not found');
    }

    if (user.role === 'TENANT' && invoice.lease.tenant.userId !== user.id) {
      throw new ForbiddenException('You can only pay your own invoices');
    }

    const totalPaid = invoice.payments.reduce(
      (sum, payment) => sum + payment.amount,
      0,
    );

    const remainingAmount = invoice.amount - totalPaid;

    if (remainingAmount <= 0) {
      throw new BadRequestException('Invoice is already fully paid');
    }

    if (dto.amount <= 0) {
      throw new BadRequestException('Payment amount must be positive');
    }

    if (dto.amount > remainingAmount) {
      throw new BadRequestException('Payment exceeds remaining invoice amount');
    }

    const result = await this.prisma.$transaction(async (tx) => {
      const payment = await tx.payment.create({
        data: {
          invoiceId: invoice.id,
          tenantId: invoice.lease.tenantId,
          amount: dto.amount,
          method: dto.method ?? 'CASH',
          provider: dto.provider,
          providerRef: dto.providerRef,
        },
      });

      const newTotalPaid = totalPaid + dto.amount;
      const isFullyPaid = newTotalPaid >= invoice.amount;

      const updatedInvoice = await tx.invoice.update({
        where: {
          id: invoice.id,
        },
        data: {
          paid: isFullyPaid,
          paidAt: isFullyPaid ? new Date() : null,
          status: isFullyPaid
            ? InvoiceStatus.PAID
            : InvoiceStatus.PARTIALLY_PAID,
        },
      });

      return {
        payment,
        updatedInvoice,
        newTotalPaid,
        isFullyPaid,
      };
    });

    const remainingAfter = Math.max(invoice.amount - result.newTotalPaid, 0);

    await this.safeAudit({
      actor: user,
      action: 'PAYMENT_RECORDED',
      resource: 'Payment',
      resourceId: result.payment.id,
      before: {
        invoiceId: invoice.id,
        invoiceStatus: invoice.status,
        invoicePaid: invoice.paid,
        invoicePaidAt: invoice.paidAt,
        totalPaidBefore: totalPaid,
        remainingBefore: remainingAmount,
      },
      after: {
        payment: result.payment,
        invoiceStatus: result.updatedInvoice.status,
        invoicePaid: result.updatedInvoice.paid,
        invoicePaidAt: result.updatedInvoice.paidAt,
        totalPaidAfter: result.newTotalPaid,
        remainingAfter,
      },
      organizationId: orgId,
      metadata: {
        invoiceId: invoice.id,
        leaseId: invoice.leaseId,
        tenantId: invoice.lease.tenantId,
        tenantUserId: invoice.lease.tenant.userId,
        tenantEmail: invoice.lease.tenant.user.email,
        propertyId: invoice.lease.unit.propertyId,
        propertyTitle: invoice.lease.unit.property?.title,
        unitId: invoice.lease.unitId,
        unitTitle: invoice.lease.unit.title,
        amount: dto.amount,
        method: dto.method ?? 'CASH',
        provider: dto.provider,
        providerRef: dto.providerRef,
        previousInvoiceStatus: invoice.status,
        newInvoiceStatus: result.updatedInvoice.status,
        fullyPaid: result.isFullyPaid,
      },
    });

    await this.safeNotify(() =>
      this.notifications.create({
        userId: invoice.lease.tenant.userId,
        organizationId: orgId,
        title: 'Payment recorded',
        body: `Payment of ${dto.amount.toFixed(2)} was recorded for your invoice. Remaining: ${remainingAfter.toFixed(2)}.`,
        type: 'PAYMENT',
        resource: 'Payment',
        resourceId: result.payment.id,
        metadata: {
          paymentId: result.payment.id,
          invoiceId: invoice.id,
          leaseId: invoice.leaseId,
          amount: dto.amount,
          method: dto.method ?? 'CASH',
          previousInvoiceStatus: invoice.status,
          newInvoiceStatus: result.updatedInvoice.status,
          remainingAfter,
          fullyPaid: result.isFullyPaid,
        },
      }),
    );

    await this.safeNotify(() =>
      this.notifications.notifyOrganizationStaff({
        organizationId: orgId,
        excludeUserId: user?.id,
        roles: ['ADMIN', 'OWNER'],
        title: 'Payment recorded',
        body: `${invoice.lease.tenant.user.email} paid ${dto.amount.toFixed(2)} for ${invoice.lease.unit.title}.`,
        type: 'PAYMENT',
        resource: 'Payment',
        resourceId: result.payment.id,
        metadata: {
          paymentId: result.payment.id,
          invoiceId: invoice.id,
          leaseId: invoice.leaseId,
          tenantId: invoice.lease.tenantId,
          tenantEmail: invoice.lease.tenant.user.email,
          propertyId: invoice.lease.unit.propertyId,
          propertyTitle: invoice.lease.unit.property?.title,
          unitId: invoice.lease.unitId,
          unitTitle: invoice.lease.unit.title,
          amount: dto.amount,
          method: dto.method ?? 'CASH',
          remainingAfter,
          fullyPaid: result.isFullyPaid,
        },
      }),
    );

    return result.payment;
  }

  async findByInvoice(orgId: string, invoiceId: string, user: any) {
    const invoice = await this.prisma.invoice.findFirst({
      where: {
        id: invoiceId,
        lease: {
          unit: {
            organizationId: orgId,
          },
        },
      },
      include: {
        lease: {
          include: {
            tenant: true,
          },
        },
      },
    });

    if (!invoice) {
      throw new NotFoundException('Invoice not found');
    }

    if (user.role === 'TENANT' && invoice.lease.tenant.userId !== user.id) {
      throw new ForbiddenException('You can only view your own invoice payments');
    }

    return this.prisma.payment.findMany({
      where: {
        invoiceId,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
  }
}