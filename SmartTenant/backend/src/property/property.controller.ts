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
import { PropertyService } from './property.service';
import { CreatePropertyDto } from './dto/create-property.dto';
import { UpdatePropertyDto } from './dto/update-property.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { GetUser } from '../auth/get-user.decorator';

@Controller('properties')
@UseGuards(JwtAuthGuard, RolesGuard)
export class PropertyController {
  constructor(private readonly service: PropertyService) {}

  @Post()
  @Roles('OWNER', 'ADMIN')
  create(@GetUser() user: any, @Body() dto: CreatePropertyDto) {
    return this.service.create(user.organizationId, dto);
  }

  @Get()
  @Roles('OWNER', 'ADMIN', 'AGENT', 'ASSISTANT')
  findAll(@GetUser() user: any) {
    return this.service.findAll(user.organizationId);
  }

  @Get(':id')
  @Roles('OWNER', 'ADMIN', 'AGENT', 'ASSISTANT')
  findOne(@GetUser() user: any, @Param('id') id: string) {
    return this.service.findOne(user.organizationId, id);
  }

  @Patch(':id')
  @Roles('OWNER', 'ADMIN')
  update(
    @GetUser() user: any,
    @Param('id') id: string,
    @Body() dto: UpdatePropertyDto,
  ) {
    return this.service.update(user.organizationId, id, dto);
  }

  @Delete(':id')
  @Roles('OWNER', 'ADMIN')
  remove(@GetUser() user: any, @Param('id') id: string) {
    return this.service.remove(user.organizationId, id);
  }
}