import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { UnitService } from './unit.service';
import { CreateUnitDto } from './dto/create-unit.dto';
import { UpdateUnitDto } from './dto/update-unit.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { GetUser } from '../auth/get-user.decorator';

@Controller('units')
@UseGuards(JwtAuthGuard, RolesGuard)
export class UnitController {
  constructor(private readonly service: UnitService) {}

  @Post('property/:propertyId')
  @Roles('OWNER', 'ADMIN')
  create(
    @GetUser() user: any,
    @Param('propertyId') propertyId: string,
    @Body() dto: CreateUnitDto,
  ) {
    return this.service.create(user.organizationId, propertyId, dto);
  }

  @Get('property/:propertyId')
  @Roles('OWNER', 'ADMIN', 'AGENT', 'ASSISTANT')
  findByProperty(
    @GetUser() user: any,
    @Param('propertyId') propertyId: string,
  ) {
    return this.service.findByProperty(user.organizationId, propertyId);
  }

  @Get(':id')
  @Roles('OWNER', 'ADMIN', 'AGENT', 'ASSISTANT')
  findOne(@GetUser() user: any, @Param('id') id: string) {
    return this.service.findOne(user.organizationId, id);
  }

  @Put(':id')
  @Roles('OWNER', 'ADMIN')
  update(
    @GetUser() user: any,
    @Param('id') id: string,
    @Body() dto: UpdateUnitDto,
  ) {
    return this.service.update(user.organizationId, id, dto);
  }

  @Delete(':id')
  @Roles('OWNER', 'ADMIN')
  remove(@GetUser() user: any, @Param('id') id: string) {
    return this.service.remove(user.organizationId, id);
  }
}