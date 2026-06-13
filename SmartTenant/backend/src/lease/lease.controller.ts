import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { LeaseService } from './lease.service';
import { CreateLeaseDto } from './dto/create-lease.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { GetUser } from '../auth/get-user.decorator';

@Controller('leases')
@UseGuards(JwtAuthGuard, RolesGuard)
export class LeaseController {
  constructor(private readonly service: LeaseService) {}

  @Post()
  @Roles('OWNER', 'ADMIN')
  create(@GetUser() user: any, @Body() dto: CreateLeaseDto) {
    return this.service.create(user.organizationId, dto, user);
  }

@Get()
@Roles('OWNER', 'ADMIN', 'ASSISTANT')
findAll(@GetUser() user: any) {
  return this.service.findAll(user.organizationId);
}

@Get(':id')
@Roles('OWNER', 'ADMIN', 'ASSISTANT')
findOne(@Param('id') id: string, @GetUser() user: any) {
  return this.service.findOne(user.organizationId, id);
}

  @Patch(':id/terminate')
  @Roles('OWNER', 'ADMIN')
  terminate(@Param('id') id: string, @GetUser() user: any) {
    return this.service.terminate(user.organizationId, id, user);
  }
}