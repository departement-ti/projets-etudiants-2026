import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { TicketService } from './ticket.service';
import { CreateTicketDto } from './dto/create-ticket.dto';
import { UpdateTicketDto } from './dto/update-ticket.dto';
import { AddMessageDto } from './dto/add-message.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { GetUser } from '../auth/get-user.decorator';

@Controller('tickets')
@UseGuards(JwtAuthGuard, RolesGuard)
export class TicketController {
  constructor(private readonly service: TicketService) {}

  @Post()
  @Roles('TENANT', 'OWNER', 'ADMIN', 'ASSISTANT')
  create(@Body() dto: CreateTicketDto, @GetUser() user: any) {
    return this.service.create(dto, user.id, user.organizationId, user);
  }

  @Get()
  @Roles('ADMIN', 'OWNER', 'AGENT', 'ASSISTANT')
  findAll(@GetUser() user: any) {
    if (user.role === 'AGENT') {
      return this.service.findAssignedToAgent(user.organizationId, user.id);
    }

    return this.service.findAllByOrganization(user.organizationId);
  }

  @Get('me')
  @Roles('TENANT', 'OWNER', 'AGENT', 'ADMIN', 'ASSISTANT')
  findMine(@GetUser() user: any) {
    return this.service.findByUserId(user.id);
  }

  @Get(':id')
  @Roles('ADMIN', 'OWNER', 'AGENT', 'TENANT', 'ASSISTANT')
  findOne(@Param('id') id: string, @GetUser() user: any) {
    return this.service.findOneForUser(id, user);
  }

  @Post(':id/messages')
  @Roles('TENANT', 'OWNER', 'AGENT', 'ADMIN', 'ASSISTANT')
  addMessage(
    @Param('id') id: string,
    @Body() dto: AddMessageDto,
    @GetUser() user: any,
  ) {
    return this.service.addMessage(
      id,
      dto.body,
      user.id,
      user.organizationId,
      user,
    );
  }

  @Patch(':id/assign/:userId')
  @Roles('ADMIN', 'OWNER', 'ASSISTANT')
  assign(
    @Param('id') id: string,
    @Param('userId') userId: string,
    @GetUser() user: any,
  ) {
    return this.service.assign(id, userId, user.organizationId, user);
  }

  @Patch(':id')
  @Roles('ADMIN', 'OWNER', 'ASSISTANT', 'AGENT')
  update(
    @Param('id') id: string,
    @Body() dto: UpdateTicketDto,
    @GetUser() user: any,
  ) {
    return this.service.update(id, dto, user.organizationId, user);
  }

  @Delete(':id')
  @Roles('ADMIN', 'OWNER')
  remove(@Param('id') id: string, @GetUser() user: any) {
    return this.service.remove(id, user.organizationId, user);
  }
}