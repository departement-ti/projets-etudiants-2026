import { Module } from '@nestjs/common';
import { AuthModule } from './auth/auth.module';
import { PrismaService } from './prisma/prisma.service';
import { OrganizationModule } from './organization/organization.module';
import { UserModule } from './user/user.module';
import { PropertyModule } from './property/property.module';
import { UnitModule } from './unit/unit.module';
import { TenantModule } from './tenant/tenant.module';
import { LeaseModule } from './lease/lease.module';
import { InvoiceModule } from './invoice/invoice.module';
import { TicketModule } from './ticket/ticket.module';
import { DashboardModule } from './dashboard/dashboard.module';
import { AppController } from './app.controller';
import { AiModule } from './AI/ai.module';
import { PaymentModule } from './payment/payment.module';
import { AuditModule } from './audit/audit.module';
import { NotificationModule } from './notification/notification.module';
import { ReportsModule } from './reports/reports.module';
import { CopilotModule } from './copilot/copilot.module';

@Module({
  imports: [
    AuthModule,
    OrganizationModule,
    UserModule,
    PropertyModule,
    UnitModule,
    TenantModule,
    LeaseModule,
    InvoiceModule,
    TicketModule,
    DashboardModule,
    AiModule,
    PaymentModule,
    AuditModule,
    NotificationModule,
    ReportsModule,
    CopilotModule,
  ],
  controllers: [AppController], // <-- place here
  providers: [PrismaService],
})
export class AppModule {}
