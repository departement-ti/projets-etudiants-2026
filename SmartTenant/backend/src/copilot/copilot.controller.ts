import { Controller, Get, UseGuards } from '@nestjs/common';
import { CopilotService } from './copilot.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { GetUser } from '../auth/get-user.decorator';

@Controller('copilot')
@UseGuards(JwtAuthGuard, RolesGuard)
export class CopilotController {
  constructor(private readonly service: CopilotService) {}

  @Get('briefing')
  @Roles('ADMIN', 'OWNER')
  briefing(@GetUser() user: any) {
    return this.service.briefing(user.organizationId);
  }
}