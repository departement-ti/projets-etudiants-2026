import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseGuards,
} from '@nestjs/common';
import { OrganizationService } from './organization.service';
import { CreateOrganizationDto } from './dto/create-organization.dto';
import { UpdateOrganizationDto } from './dto/update-organization.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { GetUser } from '../auth/get-user.decorator';

@Controller('organizations')
@UseGuards(JwtAuthGuard, RolesGuard)
export class OrganizationController {
  constructor(private readonly service: OrganizationService) {}

  @Post()
  @Roles('ADMIN')
  create(@Body() dto: CreateOrganizationDto, @GetUser() user: any) {
    return this.service.create(dto, user);
  }

  @Get()
  @Roles('ADMIN')
  findAll() {
    return this.service.findAll();
  }

  @Get(':id')
  @Roles('ADMIN')
  findOne(@Param('id') id: string) {
    return this.service.findOne(id);
  }

  @Patch(':id')
  @Roles('ADMIN')
  update(
    @Param('id') id: string,
    @Body() dto: UpdateOrganizationDto,
    @GetUser() user: any,
  ) {
    return this.service.update(id, dto, user);
  }

  @Delete(':id')
  @Roles('ADMIN')
  remove(@Param('id') id: string, @GetUser() user: any) {
    return this.service.remove(id, user);
  }

  @Post(':orgId/assign/:userId')
  @Roles('ADMIN')
  assign(
    @Param('orgId') orgId: string,
    @Param('userId') userId: string,
    @GetUser() user: any,
  ) {
    return this.service.assignUser(orgId, userId, user);
  }
}