import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { PaymentService } from './payment.service';
import { CreatePaymentDto } from './dto/create-payment.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { GetUser } from '../auth/get-user.decorator';

@Controller('payments')
@UseGuards(JwtAuthGuard, RolesGuard)
export class PaymentController {
  constructor(private readonly service: PaymentService) {}

  @Post()
  @Roles('TENANT', 'ADMIN', 'OWNER')
  create(@GetUser() user: any, @Body() dto: CreatePaymentDto) {
    return this.service.create(user.organizationId, user, dto);
  }

  @Get('invoice/:invoiceId')
  @Roles('TENANT', 'ADMIN', 'OWNER')
  findByInvoice(@GetUser() user: any, @Param('invoiceId') invoiceId: string) {
    return this.service.findByInvoice(user.organizationId, invoiceId, user);
  }
}