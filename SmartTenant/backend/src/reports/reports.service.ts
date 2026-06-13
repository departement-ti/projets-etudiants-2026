import {
  Injectable,
  BadRequestException,
} from '@nestjs/common';
import PDFDocument = require('pdfkit');
import { PrismaService } from '../prisma/prisma.service';
import { InvoiceStatus } from '@prisma/client';

@Injectable()
export class ReportsService {
  constructor(private readonly prisma: PrismaService) {}

  private parseDate(value?: string) {
    if (!value) return undefined;

    const date = new Date(value);

    if (Number.isNaN(date.getTime())) {
      throw new BadRequestException('Invalid date format');
    }

    return date;
  }

  private dateRange(startDate?: string, endDate?: string) {
    const start = this.parseDate(startDate);
    const end = this.parseDate(endDate);

    if (start && end && end < start) {
      throw new BadRequestException('endDate must be after startDate');
    }

    return {
      start,
      end,
    };
  }

  private formatMoney(value: number) {
    return value.toFixed(2);
  }

  private formatDate(value?: Date | string | null) {
    if (!value) return '—';

    const date = value instanceof Date ? value : new Date(value);

    if (Number.isNaN(date.getTime())) return '—';

    return date.toISOString().split('T')[0];
  }

  private tenantName(invoice: any) {
    const user = invoice.lease?.tenant?.user;

    if (!user) return 'Tenant';

    const fullName = `${user.firstName ?? ''} ${user.lastName ?? ''}`.trim();

    if (fullName.length > 0) return fullName;
    if (user.email) return user.email;

    return 'Tenant';
  }

  private unitName(invoice: any) {
    const unit = invoice.lease?.unit;

    if (!unit) return 'Unit';

    return unit.title ?? unit.number ?? 'Unit';
  }

  private propertyName(invoice: any) {
    const property = invoice.lease?.unit?.property;

    if (!property) return 'Property';

    return property.title ?? property.name ?? 'Property';
  }

  async financialReport(params: {
    orgId: string;
    startDate?: string;
    endDate?: string;
  }) {
    const { start, end } = this.dateRange(params.startDate, params.endDate);

    const paymentDateFilter =
      start || end
        ? {
            createdAt: {
              ...(start ? { gte: start } : {}),
              ...(end ? { lte: end } : {}),
            },
          }
        : {};

    const invoiceDateFilter =
      start || end
        ? {
            dueDate: {
              ...(start ? { gte: start } : {}),
              ...(end ? { lte: end } : {}),
            },
          }
        : {};

    const payments = await this.prisma.payment.findMany({
      where: {
        ...paymentDateFilter,
        invoice: {
          lease: {
            organizationId: params.orgId,
          },
        },
      },
      include: {
        invoice: {
          include: {
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
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    const invoices = await this.prisma.invoice.findMany({
      where: {
        ...invoiceDateFilter,
        lease: {
          organizationId: params.orgId,
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
        dueDate: 'desc',
      },
    });

    const totalRevenue = payments.reduce((sum, payment) => {
      return sum + payment.amount;
    }, 0);

    const enrichedInvoices = invoices.map((invoice) => {
      const totalPaid = invoice.payments.reduce((sum, payment) => {
        return sum + payment.amount;
      }, 0);

      const remainingAmount = Math.max(invoice.amount - totalPaid, 0);

      return {
        ...invoice,
        totalPaid,
        remainingAmount,
      };
    });

    const totalInvoiced = enrichedInvoices.reduce((sum, invoice) => {
      return sum + invoice.amount;
    }, 0);

    const totalUnpaid = enrichedInvoices.reduce((sum, invoice) => {
      return sum + invoice.remainingAmount;
    }, 0);

    const paidInvoices = enrichedInvoices.filter((invoice) => {
      return invoice.status === InvoiceStatus.PAID || invoice.remainingAmount <= 0;
    });

    const partiallyPaidInvoices = enrichedInvoices.filter((invoice) => {
      return invoice.status === InvoiceStatus.PARTIALLY_PAID;
    });

    const unpaidInvoices = enrichedInvoices.filter((invoice) => {
      return invoice.status === InvoiceStatus.UNPAID && invoice.remainingAmount > 0;
    });

    const topUnpaidMap = new Map<
      string,
      {
        tenantId: string;
        tenantName: string;
        tenantEmail: string;
        unpaid: number;
        invoices: number;
      }
    >();

    for (const invoice of enrichedInvoices) {
      if (invoice.remainingAmount <= 0) continue;

      const tenant = invoice.lease.tenant;
      const user = tenant.user;

      const key = tenant.id;

      const existing =
        topUnpaidMap.get(key) ??
        {
          tenantId: tenant.id,
          tenantName: this.tenantName(invoice),
          tenantEmail: user.email,
          unpaid: 0,
          invoices: 0,
        };

      existing.unpaid += invoice.remainingAmount;
      existing.invoices += 1;

      topUnpaidMap.set(key, existing);
    }

    const topUnpaidTenants = Array.from(topUnpaidMap.values())
      .sort((a, b) => b.unpaid - a.unpaid)
      .slice(0, 10);

    const recentPayments = payments.slice(0, 10).map((payment) => {
      const invoice = payment.invoice;

      return {
        id: payment.id,
        amount: payment.amount,
        method: payment.method,
        status: payment.status,
        createdAt: payment.createdAt,
        invoiceId: payment.invoiceId,
        tenantName: invoice ? this.tenantName(invoice) : 'Tenant',
        tenantEmail: invoice?.lease?.tenant?.user?.email ?? null,
        unitName: invoice ? this.unitName(invoice) : 'Unit',
        propertyName: invoice ? this.propertyName(invoice) : 'Property',
      };
    });

    const outstandingInvoices = enrichedInvoices
      .filter((invoice) => invoice.remainingAmount > 0)
      .sort((a, b) => b.remainingAmount - a.remainingAmount)
      .slice(0, 10)
      .map((invoice) => ({
        id: invoice.id,
        amount: invoice.amount,
        totalPaid: invoice.totalPaid,
        remainingAmount: invoice.remainingAmount,
        status: invoice.status,
        dueDate: invoice.dueDate,
        tenantName: this.tenantName(invoice),
        tenantEmail: invoice.lease.tenant.user.email,
        unitName: this.unitName(invoice),
        propertyName: this.propertyName(invoice),
      }));

    return {
      period: {
        startDate: start ? this.formatDate(start) : null,
        endDate: end ? this.formatDate(end) : null,
      },
      summary: {
        totalRevenue,
        totalInvoiced,
        totalUnpaid,
        invoiceCount: enrichedInvoices.length,
        paymentCount: payments.length,
        paidInvoiceCount: paidInvoices.length,
        partiallyPaidInvoiceCount: partiallyPaidInvoices.length,
        unpaidInvoiceCount: unpaidInvoices.length,
        collectionRate:
          totalInvoiced === 0
            ? 0
            : Number(((totalRevenue / totalInvoiced) * 100).toFixed(2)),
      },
      recentPayments,
      outstandingInvoices,
      topUnpaidTenants,
    };
  }

  async financialReportPdf(params: {
    orgId: string;
    startDate?: string;
    endDate?: string;
  }) {
    const report = await this.financialReport(params);

    return new Promise<Buffer>((resolve) => {
      const doc = new PDFDocument({
        size: 'A4',
        margin: 40,
      });

      const chunks: Buffer[] = [];

      doc.on('data', (chunk) => chunks.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(chunks)));

      doc
        .fontSize(22)
        .text('SmartTenant Financial Report', {
          align: 'center',
        });

      doc.moveDown(0.5);

      doc
        .fontSize(10)
        .fillColor('gray')
        .text(
          `Generated at: ${new Date().toLocaleString()}`,
          {
            align: 'center',
          },
        );

      doc.moveDown(1);

      doc
        .fillColor('black')
        .fontSize(12)
        .text(
          `Period: ${
            report.period.startDate ?? 'All time'
          } to ${report.period.endDate ?? 'Today'}`,
        );

      doc.moveDown(1);

      doc.fontSize(16).text('Summary');
      doc.moveDown(0.5);

      const summaryRows = [
        ['Total Revenue', this.formatMoney(report.summary.totalRevenue)],
        ['Total Invoiced', this.formatMoney(report.summary.totalInvoiced)],
        ['Total Unpaid', this.formatMoney(report.summary.totalUnpaid)],
        ['Collection Rate', `${report.summary.collectionRate}%`],
        ['Invoices', report.summary.invoiceCount.toString()],
        ['Payments', report.summary.paymentCount.toString()],
        ['Paid Invoices', report.summary.paidInvoiceCount.toString()],
        [
          'Partially Paid Invoices',
          report.summary.partiallyPaidInvoiceCount.toString(),
        ],
        ['Unpaid Invoices', report.summary.unpaidInvoiceCount.toString()],
      ];

      for (const [label, value] of summaryRows) {
        doc.fontSize(11).text(`${label}: ${value}`);
      }

      doc.moveDown(1.2);

      doc.fontSize(16).text('Recent Payments');
      doc.moveDown(0.5);

      if (report.recentPayments.length === 0) {
        doc.fontSize(11).text('No payments found.');
      } else {
        for (const payment of report.recentPayments) {
          doc
            .fontSize(10)
            .text(
              `${this.formatDate(payment.createdAt)} | ${payment.tenantName} | ${payment.propertyName} - ${payment.unitName} | ${this.formatMoney(payment.amount)} | ${payment.method ?? '—'}`,
            );
        }
      }

      doc.moveDown(1.2);

      doc.fontSize(16).text('Top Unpaid Tenants');
      doc.moveDown(0.5);

      if (report.topUnpaidTenants.length === 0) {
        doc.fontSize(11).text('No unpaid tenant balances.');
      } else {
        for (const tenant of report.topUnpaidTenants) {
          doc
            .fontSize(10)
            .text(
              `${tenant.tenantName} (${tenant.tenantEmail}) | Unpaid: ${this.formatMoney(tenant.unpaid)} | Invoices: ${tenant.invoices}`,
            );
        }
      }

      doc.moveDown(1.2);

      doc.fontSize(16).text('Outstanding Invoices');
      doc.moveDown(0.5);

      if (report.outstandingInvoices.length === 0) {
        doc.fontSize(11).text('No outstanding invoices.');
      } else {
        for (const invoice of report.outstandingInvoices) {
          doc
            .fontSize(10)
            .text(
              `${this.formatDate(invoice.dueDate)} | ${invoice.tenantName} | ${invoice.propertyName} - ${invoice.unitName} | Remaining: ${this.formatMoney(invoice.remainingAmount)} | ${invoice.status}`,
            );
        }
      }

      doc.moveDown(2);

      doc
        .fontSize(9)
        .fillColor('gray')
        .text('Generated by SmartTenant', {
          align: 'center',
        });

      doc.end();
    });
  }
}