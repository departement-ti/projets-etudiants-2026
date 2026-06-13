import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { AiService } from './ai.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { GetUser } from '../auth/get-user.decorator';

@Controller('ai')
@UseGuards(JwtAuthGuard, RolesGuard)
export class AiController {
  constructor(private readonly aiService: AiService) {}

  // Sensitive tenant financial AI
  // ADMIN / OWNER only
  @Post('predict/rent-delay')
  @Roles('ADMIN', 'OWNER')
  predictRentDelay(@Body() body: any) {
    return this.aiService.predictRentDelay(body ?? {});
  }

  // Sensitive tenant risk AI
  // ADMIN / OWNER only
  @Post('score/risk')
  @Roles('ADMIN', 'OWNER')
  scoreRisk(@Body() body: any) {
    return this.aiService.scoreTenantRisk(body ?? {});
  }

  // Operational AI for ticket replies
  // ADMIN / OWNER / AGENT / ASSISTANT
  @Post('suggest/reply')
  @Roles('ADMIN', 'OWNER', 'AGENT', 'ASSISTANT')
  suggestReply(@Body() body: any) {
    return this.aiService.suggestReply(body ?? {});
  }

  // Sensitive Tenant 360 message sending
  // ADMIN / OWNER only
  @Post('tenant-360/:tenantId/send-message')
  @Roles('ADMIN', 'OWNER')
  sendTenant360Message(
    @Param('tenantId') tenantId: string,
    @Body() body: any,
    @GetUser() user: any,
  ) {
    return this.aiService.sendTenant360Message(
      tenantId,
      user.organizationId,
      user,
      body?.message,
    );
  }

  // Sensitive Tenant 360 intelligence
  // ADMIN / OWNER only
  @Get('tenant-360/:tenantId')
  @Roles('ADMIN', 'OWNER')
  tenant360(@Param('tenantId') tenantId: string, @GetUser() user: any) {
    return this.aiService.tenant360(tenantId, user.organizationId);
  }
}