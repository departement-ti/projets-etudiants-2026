import {
  Controller,
  Get,
  Patch,
  Post,
  Delete,
  Param,
  Body,
  UseGuards,
} from '@nestjs/common';
import { UserService } from './user.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { GetUser } from '../auth/get-user.decorator';

@Controller('users')
@UseGuards(JwtAuthGuard, RolesGuard)
export class UserController {
  constructor(private readonly service: UserService) {}

  @Get()
  @Roles('ADMIN')
  findAll() {
    return this.service.findAll();
  }

  @Post()
  @Roles('ADMIN')
  create(@GetUser() user: any, @Body() data: any) {
    return this.service.create(user, data);
  }

  @Get('me')
  profile(@GetUser() user: any) {
    return this.service.profile(user.id);
  }

  @Patch('me/password')
  changeMyPassword(@GetUser() user: any, @Body() data: any) {
    return this.service.changeMyPassword(user.id, data, user);
  }

  @Patch('me')
  updateMe(@GetUser() user: any, @Body() data: any) {
    return this.service.updateMe(user.id, data, user);
  }

  // Used for ticket assignment dropdown.
  // ASSISTANT can load organization agents to dispatch maintenance work.
  @Get('agents')
  @Roles('ADMIN', 'OWNER', 'ASSISTANT')
  findAgents(@GetUser() user: any) {
    return this.service.findAgentsByOrganization(user.organizationId);
  }

  @Get(':id')
  @Roles('ADMIN')
  findOne(@Param('id') id: string) {
    return this.service.findOne(id);
  }

  @Patch(':id')
  @Roles('ADMIN')
  update(@Param('id') id: string, @Body() data: any, @GetUser() user: any) {
    return this.service.update(id, data, user);
  }

  @Delete(':id')
  @Roles('ADMIN')
  delete(@Param('id') id: string, @GetUser() user: any) {
    return this.service.delete(id, user.id, user);
  }

  @Patch(':id/role')
  @Roles('ADMIN')
  changeRole(
    @Param('id') id: string,
    @Body('role') role: string,
    @GetUser() user: any,
  ) {
    return this.service.changeRole(id, role, user);
  }
}