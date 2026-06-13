import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { InvoiceService } from './invoice.service';
import { CreateInvoiceDto } from './dto/create-invoice.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { GetUser } from '../auth/get-user.decorator';

@Controller('invoices')
@UseGuards(JwtAuthGuard, RolesGuard)
export class InvoiceController {
  constructor(private readonly service: InvoiceService) {}

  @Post()
  @Roles('ADMIN', 'OWNER')
  create(@Body() dto: CreateInvoiceDto) {
    return this.service.create(dto);
  }

  @Post('generate-due')
  @Roles('ADMIN', 'OWNER')
  generateDue(@GetUser() user: any) {
    return this.service.generateDueInvoicesForOrganization(
      user.organizationId,
    );
  }

  @Get()
  @Roles('ADMIN', 'OWNER')
  findAll(@GetUser() user: any) {
    return this.service.findAllByOrganization(user.organizationId);
  }

  @Get('me')
  @Roles('TENANT')
  findMine(@GetUser() user: any) {
    return this.service.findAllByTenant(user.id);
  }

  @Get(':id')
  @Roles('ADMIN', 'OWNER', 'TENANT')
  findOne(@Param('id') id: string, @GetUser() user: any) {
    return this.service.findOneForUser(id, user);
  }
}