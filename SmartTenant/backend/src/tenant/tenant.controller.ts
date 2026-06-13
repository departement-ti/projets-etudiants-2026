import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Delete,
  UseGuards,
  NotFoundException,
} from '@nestjs/common';
import { TenantService } from './tenant.service';
import { CreateTenantDto } from './dto/create-tenant.dto';
import { UpdateTenantDto } from './dto/update-tenant.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { GetUser } from '../auth/get-user.decorator';

@Controller('tenants')
@UseGuards(JwtAuthGuard, RolesGuard)
export class TenantController {
  constructor(private readonly service: TenantService) {}

  @Post()
  @Roles('ADMIN', 'OWNER')
  create(@GetUser() user: any, @Body() dto: CreateTenantDto) {
    if (!user.organizationId) {
      throw new NotFoundException('No organization attached to your account');
    }

    return this.service.create(user.organizationId, dto);
  }

  @Post('account')
  @Roles('ADMIN', 'OWNER')
  createAccountAndProfile(@GetUser() user: any, @Body() dto: any) {
    if (!user.organizationId) {
      throw new NotFoundException('No organization attached to your account');
    }

    return this.service.createTenantAccountAndProfile(
      user.organizationId,
      dto,
    );
  }

  @Get()
  @Roles('ADMIN', 'OWNER')
  findAll(@GetUser() user: any) {
    if (!user.organizationId) {
      throw new NotFoundException('No organization attached to your account');
    }

    return this.service.findAllByOrganization(user.organizationId);
  }

  @Get('available-users')
  @Roles('ADMIN', 'OWNER')
  availableTenantUsers(@GetUser() user: any) {
    if (!user.organizationId) {
      throw new NotFoundException('No organization attached to your account');
    }

    return this.service.findAvailableTenantUsers(user.organizationId);
  }

  @Get('me/profile')
  @Roles('TENANT')
  me(@GetUser() user: any) {
    return this.service.findByUserId(user.id);
  }

  @Get(':id')
  @Roles('ADMIN', 'OWNER')
  findOne(@Param('id') id: string, @GetUser() user: any) {
    return this.service.findOne(id, user.organizationId);
  }

  @Patch(':id')
  @Roles('ADMIN', 'OWNER')
  update(
    @Param('id') id: string,
    @Body() dto: UpdateTenantDto,
    @GetUser() user: any,
  ) {
    return this.service.update(id, dto, user.organizationId);
  }

  @Delete(':id')
  @Roles('ADMIN', 'OWNER')
  remove(@Param('id') id: string, @GetUser() user: any) {
    return this.service.remove(id, user.organizationId);
  }
}