import { Module } from '@nestjs/common';
import { LeaseService } from './lease.service';
import { LeaseController } from './lease.controller';
import { PrismaService } from '../prisma/prisma.service';
import { InvoiceService } from '../invoice/invoice.service';
import { AuditModule } from '../audit/audit.module';
import { NotificationModule } from '../notification/notification.module';

@Module({
  imports: [AuditModule, NotificationModule],
  controllers: [LeaseController],
  providers: [LeaseService, InvoiceService, PrismaService],
})
export class LeaseModule {}